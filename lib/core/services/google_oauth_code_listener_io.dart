import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/google_oauth_config.dart';
import 'app_foreground_service.dart';
import 'google_oauth_result_page.dart';
import 'google_oauth_service.dart';
import 'logger_service.dart';

/// Runs the authorization-code leg of the OAuth flow.
abstract class GoogleCodeListener {
  /// The redirect URI this listener will receive the code on.
  Future<String> prepareRedirect();

  /// Drives the user through [authorizationUrl] and resolves the code.
  Future<String> waitForCode(String authorizationUrl);
}

/// Creates the platform default [GoogleCodeListener].
GoogleCodeListener createDefaultGoogleCodeListener() => LoopbackCodeListener();

/// Opens [url] in an in-app authentication session and resolves with the
/// callback URL once the page redirects to [callbackScheme].
///
/// Throws a [PlatformException] with the `CANCELED` code when the user
/// dismisses the session.
typedef AuthenticationSessionRunner =
    Future<String> Function(String url, String callbackScheme);

/// Opens [url] in the system browser and reports whether it could be opened.
typedef ExternalBrowserLauncher = Future<bool> Function(Uri url);

Future<String> _runAuthenticationSession(String url, String callbackScheme) =>
    FlutterWebAuth2.authenticate(url: url, callbackUrlScheme: callbackScheme);

Future<String> _readPackageName() async =>
    (await PackageInfo.fromPlatform()).packageName;

Future<bool> _launchExternalBrowser(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

/// Native [GoogleCodeListener] that binds an ephemeral loopback HTTP server,
/// shows the Google consent page and resolves the authorization code from the
/// first redirect the server receives.
///
/// On iOS and Android the consent page runs in an authentication session
/// (`ASWebAuthenticationSession` / Chrome Auth Tab) instead of a separate
/// browser app. Keeping the session on top of the app stops iOS from
/// suspending the process, and with it the loopback server, while the user
/// signs in; the loopback response then redirects to
/// [kGoogleOAuthCallbackScheme], which closes the session and returns to the
/// app. Desktop platforms open the system browser and keep the manual-return
/// success page.
class LoopbackCodeListener implements GoogleCodeListener {
  /// How long to wait for the authentication session to close on its own once
  /// the callback was answered.
  static const Duration _sessionCloseGrace = Duration(seconds: 3);

  static const String _appCallbackUrl = '$kGoogleOAuthCallbackScheme://done';

  final Duration _flowTimeout;
  final AuthenticationSessionRunner _sessionRunner;
  final ExternalBrowserLauncher _browserLauncher;
  final bool _usesAuthenticationSession;
  final Future<void> Function() _bringAppToFront;
  final Future<String> Function() _packageName;

  HttpServer? _server;

  /// Creates the listener.
  ///
  /// [sessionRunner], [browserLauncher], [usesAuthenticationSession],
  /// [bringAppToFront], [packageName] and [flowTimeout] exist for tests; by default the
  /// authentication session is used on iOS and Android, the system browser
  /// everywhere else, and the app pulls itself forward through
  /// [AppForegroundService].
  LoopbackCodeListener({
    AuthenticationSessionRunner? sessionRunner,
    ExternalBrowserLauncher? browserLauncher,
    bool? usesAuthenticationSession,
    Future<void> Function()? bringAppToFront,
    Future<String> Function()? packageName,
    Duration flowTimeout = const Duration(minutes: 5),
  }) : _flowTimeout = flowTimeout,
       _sessionRunner = sessionRunner ?? _runAuthenticationSession,
       _browserLauncher = browserLauncher ?? _launchExternalBrowser,
       _bringAppToFront =
           bringAppToFront ?? AppForegroundService().bringToFront,
       _packageName = packageName ?? _readPackageName,
       _usesAuthenticationSession =
           usesAuthenticationSession ??
           (defaultTargetPlatform == TargetPlatform.iOS ||
               defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<String> prepareRedirect() async {
    await _closeServer();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    logger.debug('[GoogleOAuth] Loopback server bound on port ${server.port}');
    return 'http://localhost:${server.port}';
  }

  @override
  Future<String> waitForCode(String authorizationUrl) async {
    final server = _server;
    if (server == null) {
      throw StateError('prepareRedirect must run before waitForCode.');
    }

    final expectedState = Uri.parse(authorizationUrl).queryParameters['state'];
    Future<void>? sessionClosed;
    try {
      final HttpRequest request;
      if (_usesAuthenticationSession) {
        final started = _startAuthenticationSession(server, authorizationUrl);
        sessionClosed = started.sessionClosed;
        request = await started.request;
      } else {
        request = await _awaitRequestInBrowser(server, authorizationUrl);
      }
      return await _handleCallback(request, expectedState);
    } finally {
      await sessionClosed?.timeout(_sessionCloseGrace, onTimeout: () {});
      await _closeServer();
    }
  }

  /// Resolves with the first request carrying the `state` of
  /// [authorizationUrl], answering every other request with 404.
  ///
  /// Anything else that reaches the loopback port (a stray local request, a
  /// browser probe) must not end the sign-in, and Google echoes `state` on its
  /// error redirects too, so denied consent is still delivered.
  Future<HttpRequest> _firstCallback(
    HttpServer server,
    String authorizationUrl,
  ) {
    final expectedState = Uri.parse(authorizationUrl).queryParameters['state'];
    return server.firstWhere((request) {
      final matches =
          expectedState != null &&
          expectedState.isNotEmpty &&
          request.uri.queryParameters['state'] == expectedState;
      if (!matches) {
        request.response.statusCode = HttpStatus.notFound;
        unawaited(request.response.close());
      }
      return matches;
    });
  }

  Future<HttpRequest> _awaitRequestInBrowser(
    HttpServer server,
    String authorizationUrl,
  ) async {
    final launched = await _browserLauncher(Uri.parse(authorizationUrl));
    if (!launched) {
      throw const GoogleOAuthException(
        'The sign-in browser could not be opened. Please try again.',
      );
    }
    logger.debug('[GoogleOAuth] Browser opened, waiting for the redirect');
    try {
      return await _firstCallback(
        server,
        authorizationUrl,
      ).timeout(_flowTimeout);
    } on TimeoutException {
      throw const GoogleOAuthException(
        'Google sign-in timed out. Please try again.',
      );
    }
  }

  /// Starts the authentication session and races it against the loopback
  /// redirect: the request wins on a normal sign-in, the session wins when the
  /// user dismisses it. [sessionClosed] settles once the session ended, with
  /// any failure already swallowed.
  ({Future<HttpRequest> request, Future<void> sessionClosed})
  _startAuthenticationSession(HttpServer server, String authorizationUrl) {
    Object? sessionError;
    final sessionClosed =
        _sessionRunner(authorizationUrl, kGoogleOAuthCallbackScheme).then<void>(
          (_) {},
          onError: (Object error, StackTrace stackTrace) {
            sessionError = error;
          },
        );
    logger.debug(
      '[GoogleOAuth] Authentication session opened, waiting for the redirect',
    );

    Future<HttpRequest> awaitRequest() async {
      final HttpRequest? request;
      try {
        request = await Future.any<HttpRequest?>([
          _firstCallback(server, authorizationUrl),
          sessionClosed.then((_) => null),
        ]).timeout(_flowTimeout);
      } on TimeoutException {
        throw const GoogleOAuthException(
          'Google sign-in timed out. Please try again.',
        );
      }
      if (request == null) {
        throw _sessionFailure(sessionError);
      }
      return request;
    }

    return (request: awaitRequest(), sessionClosed: sessionClosed);
  }

  GoogleOAuthException _sessionFailure(Object? error) {
    if (error == null ||
        (error is PlatformException && error.code == 'CANCELED')) {
      return const GoogleOAuthException(
        'Google sign-in was cancelled before it finished.',
      );
    }
    logger.warning('[GoogleOAuth] Authentication session failed: $error');
    return const GoogleOAuthException(
      'The sign-in browser could not be opened. Please try again.',
    );
  }

  Future<String> _handleCallback(
    HttpRequest request,
    String? expectedState,
  ) async {
    final params = request.uri.queryParameters;
    final failure = _validateCallback(params, expectedState);
    final returnLink = await _returnLink();
    if (failure != null) {
      await _respond(request, _failurePage(failure.message, returnLink));
      await _returnToApp();
      throw failure;
    }
    await _respond(request, _successPage(returnLink));
    logger.debug('[GoogleOAuth] Authorization code received');
    await _returnToApp();
    return params['code']!;
  }

  /// Pulls the app back in front of the browser, which is not guaranteed to
  /// follow the redirect to [kGoogleOAuthCallbackScheme] on its own.
  Future<void> _returnToApp() async {
    if (!_usesAuthenticationSession) return;
    try {
      await _bringAppToFront();
    } catch (error, stackTrace) {
      logger.warning(
        '[GoogleOAuth] Could not bring the app to the front',
        error,
        stackTrace,
      );
    }
  }

  GoogleOAuthException? _validateCallback(
    Map<String, String> params,
    String? expectedState,
  ) {
    final error = params['error'];
    if (error == 'access_denied') {
      return const GoogleOAuthException(
        'Google sign-in was cancelled: consent was denied.',
      );
    }
    if (error != null) {
      final description = params['error_description'];
      return GoogleOAuthException(
        'Google sign-in failed: ${description ?? error}',
      );
    }
    final state = params['state'];
    if (expectedState == null ||
        expectedState.isEmpty ||
        state != expectedState) {
      return const GoogleOAuthException(
        'Google sign-in failed: the redirect could not be verified.',
      );
    }
    final code = params['code'];
    if (code == null || code.isEmpty) {
      return const GoogleOAuthException(
        'Google sign-in failed: no authorization code was returned.',
      );
    }
    return null;
  }

  /// Answers the loopback request with [page].
  ///
  /// Inside an authentication session the answer is a redirect to
  /// [kGoogleOAuthCallbackScheme] instead, which is what closes the session and
  /// returns to the app; the page stays as the body for browsers that decline
  /// to follow the custom scheme.
  Future<void> _respond(HttpRequest request, String page) async {
    final response = request.response;
    response.headers.contentType = ContentType.html;
    if (_usesAuthenticationSession) {
      response.statusCode = HttpStatus.found;
      response.headers.set(HttpHeaders.locationHeader, _appCallbackUrl);
    } else {
      response.statusCode = HttpStatus.ok;
    }
    response.write(page);
    await response.close();
  }

  String _successPage(String? returnLink) => buildOAuthResultPage(
    success: true,
    message: 'Sign-in complete. You can return to the app.',
    returnUrl: returnLink,
  );

  String _failurePage(String message, String? returnLink) =>
      buildOAuthResultPage(
        success: false,
        message: message,
        returnUrl: returnLink,
      );

  /// The link behind the page's return button, or null on desktop.
  ///
  /// Android gets an `intent:` link, which Chrome, Samsung Internet and
  /// Firefox open straight into the app on a tap, instead of relying on the
  /// browser to resolve the custom scheme. Other platforms use the scheme.
  Future<String?> _returnLink() async {
    if (!_usesAuthenticationSession) return null;
    if (defaultTargetPlatform != TargetPlatform.android) {
      return _appCallbackUrl;
    }
    try {
      return buildAndroidIntentLink(await _packageName());
    } catch (error, stackTrace) {
      logger.warning(
        '[GoogleOAuth] Could not build the Android intent link',
        error,
        stackTrace,
      );
      return _appCallbackUrl;
    }
  }

  Future<void> _closeServer() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
  }
}
