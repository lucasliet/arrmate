import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'google_auth.dart';

/// [GoogleOAuthService] for the web build, which does not sign in to Google.
class _UnavailableGoogleOAuthService implements GoogleOAuthService {
  @override
  Future<String?> getValidAccessToken() async => null;

  @override
  Future<String?> refreshAccessToken() async => null;

  @override
  Future<GoogleAccount?> restoreSession() async => null;

  @override
  Future<GoogleAccount> signIn() {
    throw const GoogleOAuthException(
      'Google sign-in is not available on the web.',
    );
  }

  @override
  Future<void> signOut() async {}
}

/// Web stand-in for the native Google OAuth session.
///
/// The backup screen does not offer sign-in on web, and this service never
/// contacts Google.
final googleOAuthServiceProvider = Provider<GoogleOAuthService>(
  (ref) => _UnavailableGoogleOAuthService(),
);
