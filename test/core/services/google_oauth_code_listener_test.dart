import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arrmate/core/constants/google_oauth_config.dart';
import 'package:arrmate/core/services/google_oauth_code_listener_io.dart';
import 'package:arrmate/core/services/google_oauth_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Result of a loopback request made without following redirects.
class _LoopbackResponse {
  final int status;
  final String? location;
  final String body;

  const _LoopbackResponse(this.status, this.location, this.body);
}

Future<_LoopbackResponse> _get(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return _LoopbackResponse(
      response.statusCode,
      response.headers.value(HttpHeaders.locationHeader),
      body,
    );
  } finally {
    client.close(force: true);
  }
}

String _authorizationUrl(String redirectUri, {String state = 'state-1'}) =>
    Uri.parse('https://accounts.google.com/o/oauth2/v2/auth')
        .replace(queryParameters: {'redirect_uri': redirectUri, 'state': state})
        .toString();

void main() {
  group('LoopbackCodeListener with an authentication session', () {
    test('resolves the code and redirects back to the app', () async {
      late _LoopbackResponse response;
      late LoopbackCodeListener listener;
      listener = LoopbackCodeListener(
        usesAuthenticationSession: true,
        sessionRunner: (url, scheme) async {
          expect(scheme, kGoogleOAuthCallbackScheme);
          final redirect = Uri.parse(url).queryParameters['redirect_uri']!;
          response = await _get(
            Uri.parse('$redirect/?code=auth-code&state=state-1'),
          );
          return response.location!;
        },
      );

      final redirectUri = await listener.prepareRedirect();
      final code = await listener.waitForCode(_authorizationUrl(redirectUri));

      expect(code, 'auth-code');
      expect(response.status, HttpStatus.found);
      expect(response.location, startsWith('$kGoogleOAuthCallbackScheme://'));
      expect(response.body, contains('Return to Arrmate'));
    });

    test('reports a dismissed session as a cancelled sign-in', () async {
      final listener = LoopbackCodeListener(
        usesAuthenticationSession: true,
        sessionRunner: (url, scheme) async =>
            throw PlatformException(code: 'CANCELED'),
      );

      final redirectUri = await listener.prepareRedirect();

      await expectLater(
        listener.waitForCode(_authorizationUrl(redirectUri)),
        throwsA(
          isA<GoogleOAuthException>().having(
            (e) => e.message,
            'message',
            contains('cancelled'),
          ),
        ),
      );
    });

    test('reports a session that could not start', () async {
      final listener = LoopbackCodeListener(
        usesAuthenticationSession: true,
        sessionRunner: (url, scheme) async =>
            throw PlatformException(code: 'FAILED'),
      );

      final redirectUri = await listener.prepareRedirect();

      await expectLater(
        listener.waitForCode(_authorizationUrl(redirectUri)),
        throwsA(
          isA<GoogleOAuthException>().having(
            (e) => e.message,
            'message',
            contains('could not be opened'),
          ),
        ),
      );
    });

    test('still returns to the app when consent is denied', () async {
      late _LoopbackResponse response;
      final listener = LoopbackCodeListener(
        usesAuthenticationSession: true,
        sessionRunner: (url, scheme) async {
          final redirect = Uri.parse(url).queryParameters['redirect_uri']!;
          response = await _get(
            Uri.parse('$redirect/?error=access_denied&state=state-1'),
          );
          return response.location!;
        },
      );

      final redirectUri = await listener.prepareRedirect();

      await expectLater(
        listener.waitForCode(_authorizationUrl(redirectUri)),
        throwsA(
          isA<GoogleOAuthException>().having(
            (e) => e.message,
            'message',
            contains('consent was denied'),
          ),
        ),
      );
      expect(response.status, HttpStatus.found);
      expect(response.location, startsWith('$kGoogleOAuthCallbackScheme://'));
    });

    test('ignores stray requests and keeps waiting for the callback', () async {
      final statuses = <int>[];
      late _LoopbackResponse response;
      final listener = LoopbackCodeListener(
        usesAuthenticationSession: true,
        sessionRunner: (url, scheme) async {
          final redirect = Uri.parse(url).queryParameters['redirect_uri']!;
          statuses
            ..add((await _get(Uri.parse('$redirect/favicon.ico'))).status)
            ..add(
              (await _get(
                Uri.parse('$redirect/?code=auth-code&state=forged'),
              )).status,
            )
            ..add(
              (await _get(Uri.parse('$redirect/?error=access_denied'))).status,
            );
          response = await _get(
            Uri.parse('$redirect/?code=auth-code&state=state-1'),
          );
          return response.location!;
        },
      );

      final redirectUri = await listener.prepareRedirect();
      final code = await listener.waitForCode(_authorizationUrl(redirectUri));

      expect(code, 'auth-code');
      expect(statuses, everyElement(HttpStatus.notFound));
      expect(response.status, HttpStatus.found);
    });

    test('times out when the redirect never arrives', () async {
      final listener = LoopbackCodeListener(
        usesAuthenticationSession: true,
        flowTimeout: const Duration(milliseconds: 100),
        sessionRunner: (url, scheme) => Completer<String>().future,
      );

      final redirectUri = await listener.prepareRedirect();

      await expectLater(
        listener.waitForCode(_authorizationUrl(redirectUri)),
        throwsA(
          isA<GoogleOAuthException>().having(
            (e) => e.message,
            'message',
            contains('timed out'),
          ),
        ),
      );
    });
  });

  group('LoopbackCodeListener with the system browser', () {
    test('resolves the code and keeps the manual-return page', () async {
      late _LoopbackResponse response;
      final listener = LoopbackCodeListener(
        usesAuthenticationSession: false,
        browserLauncher: (url) async {
          final redirect = url.queryParameters['redirect_uri']!;
          // The browser answers asynchronously, after the launch returned.
          Future<void>(() async {
            response = await _get(
              Uri.parse('$redirect/?code=auth-code&state=state-1'),
            );
          });
          return true;
        },
      );

      final redirectUri = await listener.prepareRedirect();
      final code = await listener.waitForCode(_authorizationUrl(redirectUri));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(code, 'auth-code');
      expect(response.status, HttpStatus.ok);
      expect(response.location, isNull);
      expect(response.body, contains('You can return to the app'));
    });

    test('times out when the redirect never arrives', () async {
      final listener = LoopbackCodeListener(
        usesAuthenticationSession: false,
        flowTimeout: const Duration(milliseconds: 100),
        browserLauncher: (url) async => true,
      );

      final redirectUri = await listener.prepareRedirect();

      await expectLater(
        listener.waitForCode(_authorizationUrl(redirectUri)),
        throwsA(
          isA<GoogleOAuthException>().having(
            (e) => e.message,
            'message',
            contains('timed out'),
          ),
        ),
      );
    });

    test('fails when the browser cannot be opened', () async {
      final listener = LoopbackCodeListener(
        usesAuthenticationSession: false,
        browserLauncher: (url) async => false,
      );

      final redirectUri = await listener.prepareRedirect();

      await expectLater(
        listener.waitForCode(_authorizationUrl(redirectUri)),
        throwsA(isA<GoogleOAuthException>()),
      );
    });
  });

  group('LoopbackCodeListener returning to the app', () {
    LoopbackCodeListener buildListener({
      required bool usesSession,
      required Future<void> Function() bringAppToFront,
      String query = 'code=auth-code&state=state-1',
    }) {
      Future<void> hitCallback(String url) async {
        final redirect = Uri.parse(url).queryParameters['redirect_uri']!;
        await _get(Uri.parse('$redirect/?$query'));
      }

      return LoopbackCodeListener(
        usesAuthenticationSession: usesSession,
        bringAppToFront: bringAppToFront,
        sessionRunner: (url, scheme) async {
          await hitCallback(url);
          return '$scheme://done';
        },
        browserLauncher: (url) async {
          Future<void>(() => hitCallback(url.toString()));
          return true;
        },
      );
    }

    test('pulls the app forward once the code arrives in a session', () async {
      var calls = 0;
      final listener = buildListener(
        usesSession: true,
        bringAppToFront: () async => calls++,
      );

      final redirectUri = await listener.prepareRedirect();
      final code = await listener.waitForCode(_authorizationUrl(redirectUri));

      expect(code, 'auth-code');
      expect(calls, 1);
    });

    test('pulls the app forward when consent is denied', () async {
      var calls = 0;
      final listener = buildListener(
        usesSession: true,
        bringAppToFront: () async => calls++,
        query: 'error=access_denied&state=state-1',
      );

      final redirectUri = await listener.prepareRedirect();

      await expectLater(
        listener.waitForCode(_authorizationUrl(redirectUri)),
        throwsA(isA<GoogleOAuthException>()),
      );
      expect(calls, 1);
    });

    test('leaves the foreground alone when using the system browser', () async {
      var calls = 0;
      final listener = buildListener(
        usesSession: false,
        bringAppToFront: () async => calls++,
      );

      final redirectUri = await listener.prepareRedirect();
      final code = await listener.waitForCode(_authorizationUrl(redirectUri));

      expect(code, 'auth-code');
      expect(calls, 0);
    });

    test('still returns the code when pulling the app forward fails', () async {
      final listener = buildListener(
        usesSession: true,
        bringAppToFront: () async => throw PlatformException(code: 'boom'),
      );

      final redirectUri = await listener.prepareRedirect();
      final code = await listener.waitForCode(_authorizationUrl(redirectUri));

      expect(code, 'auth-code');
    });

    test('shows a themed page with a way back inside a session', () async {
      late _LoopbackResponse response;
      final listener = LoopbackCodeListener(
        usesAuthenticationSession: true,
        bringAppToFront: () async {},
        sessionRunner: (url, scheme) async {
          final redirect = Uri.parse(url).queryParameters['redirect_uri']!;
          response = await _get(
            Uri.parse('$redirect/?code=auth-code&state=state-1'),
          );
          return '$scheme://done';
        },
      );

      final redirectUri = await listener.prepareRedirect();
      await listener.waitForCode(_authorizationUrl(redirectUri));

      expect(response.body, contains('<style>'));
      expect(response.body, contains('Return to Arrmate'));
      expect(response.body, contains('prefers-color-scheme: dark'));
    });
  });
}
