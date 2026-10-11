/// Client id of the Desktop OAuth client, used on every native platform.
const String kGoogleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

/// Client secret of the Desktop OAuth client, used on every native platform.
const String kGoogleClientSecret = String.fromEnvironment(
  'GOOGLE_CLIENT_SECRET',
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
