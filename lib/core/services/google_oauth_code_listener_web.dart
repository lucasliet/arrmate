import 'package:url_launcher/url_launcher.dart';

import 'google_auth.dart';
import 'logger_service.dart';

/// Runs the authorization-code leg of the OAuth flow.
abstract class GoogleCodeListener {
  /// The redirect URI this listener will receive the code on.
  Future<String> prepareRedirect();

  /// Drives the user through [authorizationUrl] and resolves the code.
  Future<String> waitForCode(String authorizationUrl);
}

/// Creates the platform default [GoogleCodeListener].
GoogleCodeListener createDefaultGoogleCodeListener() =>
    WebRedirectCodeListener();

/// [GoogleCodeListener] for the web build, where the OAuth redirect reloads
/// the app itself with the code as a query parameter.
///
/// This file must stay free of web-only imports: it is analyzed together with
/// the rest of the VM sources and only compiled by the web toolchain.
class WebRedirectCodeListener implements GoogleCodeListener {
  @override
  Future<String> prepareRedirect() async {
    final base = Uri.base;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : 0,
      path: base.path,
    ).toString();
  }

  @override
  Future<String> waitForCode(String authorizationUrl) async {
    final expectedState = Uri.parse(authorizationUrl).queryParameters['state'];
    final currentParams = Uri.base.queryParameters;
    final code = currentParams['code'];
    if (expectedState != null &&
        expectedState.isNotEmpty &&
        currentParams['state'] == expectedState &&
        code != null &&
        code.isNotEmpty) {
      logger.debug('[GoogleOAuth] Resuming the code from the page URL');
      return code;
    }

    logger.info('[GoogleOAuth] Redirecting to Google in the browser');
    await launchUrl(Uri.parse(authorizationUrl));
    throw const GoogleOAuthRedirectPending();
  }
}
