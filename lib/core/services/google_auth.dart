/// The Google account currently authorized for backups.
class GoogleAccount {
  /// E-mail address of the signed-in account.
  final String email;

  /// Display name of the signed-in account, when Google reports one.
  final String? name;

  const GoogleAccount({required this.email, this.name});
}

/// Supplies valid access tokens for Google API calls.
abstract class GoogleAccessTokenProvider {
  /// Returns a non-expired access token, refreshing it when needed, or null
  /// when there is no signed-in session.
  Future<String?> getValidAccessToken();

  /// Forces a token refresh and returns the fresh token, or null when there is
  /// no signed-in session.
  ///
  /// Used by API clients to refresh and retry once after an unauthorized
  /// response.
  Future<String?> refreshAccessToken();
}

/// Entry point of the Google OAuth flow used by the Drive backup.
abstract class GoogleOAuthService implements GoogleAccessTokenProvider {
  /// Restores a previous session from persisted tokens without any user
  /// interaction, or returns null when no session was persisted.
  Future<GoogleAccount?> restoreSession();

  /// Runs the interactive sign-in flow and returns the signed-in account.
  ///
  /// On the web this may throw [GoogleOAuthRedirectPending] after opening the
  /// consent page: the browser navigates away and the returned code only
  /// arrives when the app reloads back with `?code=` in the URL.
  Future<GoogleAccount> signIn();

  /// Revokes the granted access and clears the persisted session.
  Future<void> signOut();
}

/// Signals that the sign-in flow continues in the browser and finishes on the
/// next app load, which only happens on the web redirect flow.
class GoogleOAuthRedirectPending implements Exception {
  const GoogleOAuthRedirectPending();
}
