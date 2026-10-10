import 'package:flutter/foundation.dart';

/// Client id of the Desktop OAuth client, used on every native platform.
const String kGoogleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

/// Client secret of the Desktop OAuth client, used on every native platform.
const String kGoogleClientSecret = String.fromEnvironment(
  'GOOGLE_CLIENT_SECRET',
);

/// Client id of the Web application OAuth client, used by the web build.
const String kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
);

/// Client secret of the Web application OAuth client, used by the web build.
const String kGoogleWebClientSecret = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_SECRET',
);

/// Scope granting access to the private application data folder in Drive.
const String kDriveAppDataScope =
    'https://www.googleapis.com/auth/drive.appdata';

/// Custom URI scheme the loopback page bounces to once the authorization code
/// was received, so the in-app authentication session on iOS and Android
/// closes and hands control back to the app.
///
/// It is registered for the Android `CallbackActivity` in `AndroidManifest.xml`
/// and deliberately differs from the `arrmate` deep link scheme so the two
/// never compete for the same intent.
const String kGoogleOAuthCallbackScheme = 'arrmate-oauth';

/// Scopes requested at sign-in: the Drive app folder plus the account's e-mail
/// and profile, so the backup screen can show who is signed in.
const List<String> kGoogleBackupScopes = [
  kDriveAppDataScope,
  'email',
  'profile',
];

/// Whether the current build carries the OAuth client it needs.
///
/// Native platforms use the Desktop client; the web build needs its own Web
/// application client because a Desktop client cannot register browser
/// origins. Builds without the defines show the backup screen disabled.
bool get isGoogleOAuthConfigured =>
    kIsWeb ? kGoogleWebClientId.isNotEmpty : kGoogleClientId.isNotEmpty;
