import 'package:shared_preferences/shared_preferences.dart';

import 'logger_service.dart';

/// SharedPreferences key older web builds used for the Google refresh token.
const String legacyWebGoogleOAuthTokensKey = 'google_oauth_tokens';

/// Removes Google OAuth tokens left in browser storage by older web builds.
///
/// Native sessions live in the platform keyring and are not stored under
/// [legacyWebGoogleOAuthTokensKey]. [prefs] is the preferences instance opened
/// during startup.
Future<void> clearLegacyWebGoogleOAuthTokens(SharedPreferences prefs) async {
  final removed = await prefs.remove(legacyWebGoogleOAuthTokensKey);
  if (!removed) return;
  logger.info('[GoogleOAuth] Removed legacy web OAuth tokens from storage');
}
