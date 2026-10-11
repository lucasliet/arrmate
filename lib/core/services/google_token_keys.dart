/// Canonical keys under which the Google OAuth session is persisted.
abstract final class GoogleTokenKeys {
  /// Google refresh token, kept to renew the access token offline.
  static const String refreshToken = 'refresh_token';

  /// Google access token sent with every Drive API request.
  static const String accessToken = 'access_token';

  /// Access token expiry, as milliseconds since epoch.
  static const String accessTokenExpiry = 'access_token_expiry';

  /// PKCE verifier saved between the authorization request and the redirect.
  static const String pendingVerifier = 'pending_verifier';

  /// Anti-CSRF state saved between the authorization request and the redirect.
  static const String pendingState = 'pending_state';

  /// Web redirect code already exchanged, ignored on later page reloads.
  static const String consumedCode = 'consumed_code';

  /// Every persisted key, for stores that cannot enumerate entries.
  static const List<String> all = [
    refreshToken,
    accessToken,
    accessTokenExpiry,
    pendingVerifier,
    pendingState,
    consumedCode,
  ];
}
