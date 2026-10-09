import 'dart:async';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

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

/// Native [GoogleCodeListener] that binds an ephemeral loopback HTTP server,
/// opens the Google consent page in the user's browser and resolves the
/// authorization code from the first redirect it receives.
class LoopbackCodeListener implements GoogleCodeListener {
  static const Duration _flowTimeout = Duration(minutes: 5);

  static const String _successPage =
      '<html><body><h2>Arrmate</h2>'
      '<p>Sign-in complete. You can return to the app.</p></body></html>';

  HttpServer? _server;

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
    try {
      final launched = await launchUrl(
        Uri.parse(authorizationUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const GoogleOAuthException(
          'The sign-in browser could not be opened. Please try again.',
        );
      }
      logger.debug('[GoogleOAuth] Browser opened, waiting for the redirect');

      final HttpRequest request;
      try {
        request = await server.first.timeout(_flowTimeout);
      } on TimeoutException {
        throw const GoogleOAuthException(
          'Google sign-in timed out. Please try again.',
        );
      }

      return _handleCallback(request, expectedState);
    } finally {
      await _closeServer();
    }
  }

  Future<String> _handleCallback(
    HttpRequest request,
    String? expectedState,
  ) async {
    final params = request.uri.queryParameters;
    final failure = _validateCallback(params, expectedState);
    if (failure != null) {
      await _respond(request, _failurePage(failure.message));
      throw failure;
    }
    await _respond(request, _successPage);
    logger.debug('[GoogleOAuth] Authorization code received');
    return params['code']!;
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

  Future<void> _respond(HttpRequest request, String page) async {
    final response = request.response;
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.html;
    response.write(page);
    await response.close();
  }

  String _failurePage(String message) =>
      '<html><body><h2>Arrmate</h2><p>$message</p></body></html>';

  Future<void> _closeServer() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
  }
}
