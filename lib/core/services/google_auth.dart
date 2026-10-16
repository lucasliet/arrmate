import '../l10n/app_locale.dart';

/// The Google account currently authorized for backups.
class GoogleAccount {
  /// E-mail address of the signed-in account.
  final String email;

  /// Display name of the signed-in account, when Google reports one.
  final String? name;

  const GoogleAccount({required this.email, this.name});
}

/// Why a Google OAuth flow failed, used to translate [GoogleOAuthException].
enum GoogleOAuthFailure {
  /// The sign-in browser or authentication session could not be opened.
  browserUnavailable,

  /// The user did not finish signing in before the flow timed out.
  timedOut,

  /// The user dismissed the authentication session.
  cancelled,

  /// The user denied consent on Google's page.
  consentDenied,

  /// Google redirected back with an error; the detail carries its text.
  providerError,

  /// The redirect `state` did not match the request.
  redirectUnverified,

  /// The redirect carried no authorization code.
  missingCode,

  /// The token or account request failed at the network level; the detail
  /// carries the HTTP status, when known.
  networkError,

  /// The token endpoint answered with an unexpected HTTP status (detail).
  unexpectedStatus,

  /// The token response lacked the access token or its lifetime.
  incompleteTokenResponse,

  /// The account endpoint answered with an unexpected HTTP status (detail).
  accountLoadFailed,

  /// The account has no e-mail address.
  missingEmail,

  /// Google sign-in is not supported on this platform (web).
  unsupportedPlatform,
}

/// Error thrown across the Google OAuth flow carrying a message that is safe
/// to surface directly to the user.
class GoogleOAuthException implements Exception {
  /// Human-readable description of the failure, in English.
  final String message;

  /// Why the flow failed, used by [localizedMessage]; `null` when the message
  /// cannot be translated.
  final GoogleOAuthFailure? failure;

  /// Value interpolated in the translated message: the provider error text
  /// or the HTTP status, depending on [failure].
  final String? detail;

  /// Creates the exception with the user-facing [message].
  const GoogleOAuthException(this.message, {this.failure, this.detail});

  /// Returns the user-facing message in the language of [l10n], falling back
  /// to the English [message] when there is no [failure] to translate.
  String localizedMessage(AppLocalizations l10n) {
    final status = detail ?? l10n.coreGoogleSignInStatusUnavailable;
    return switch (failure) {
      null => message,
      GoogleOAuthFailure.browserUnavailable =>
        l10n.coreGoogleSignInBrowserFailed,
      GoogleOAuthFailure.timedOut => l10n.coreGoogleSignInTimedOut,
      GoogleOAuthFailure.cancelled => l10n.coreGoogleSignInCancelled,
      GoogleOAuthFailure.consentDenied => l10n.coreGoogleSignInConsentDenied,
      GoogleOAuthFailure.providerError => l10n.coreGoogleSignInProviderError(
        detail ?? '',
      ),
      GoogleOAuthFailure.redirectUnverified =>
        l10n.coreGoogleSignInRedirectUnverified,
      GoogleOAuthFailure.missingCode => l10n.coreGoogleSignInNoCode,
      GoogleOAuthFailure.networkError => l10n.coreGoogleSignInNetworkError(
        status,
      ),
      GoogleOAuthFailure.unexpectedStatus => l10n.coreGoogleSignInServerStatus(
        status,
      ),
      GoogleOAuthFailure.incompleteTokenResponse =>
        l10n.coreGoogleSignInIncompleteToken,
      GoogleOAuthFailure.accountLoadFailed =>
        l10n.coreGoogleSignInAccountLoadFailed(status),
      GoogleOAuthFailure.missingEmail => l10n.coreGoogleSignInNoEmail,
      GoogleOAuthFailure.unsupportedPlatform =>
        l10n.coreGoogleSignInUnavailableOnWeb,
    };
  }

  @override
  String toString() => message;
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
  Future<GoogleAccount> signIn();

  /// Revokes the granted access and clears the persisted session.
  Future<void> signOut();
}
