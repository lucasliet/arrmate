import 'google_oauth_config.dart';

/// Whether this native build carries the Desktop OAuth client.
///
/// Builds without [kGoogleClientId] show the backup screen's Drive section
/// as unavailable. The web build never reaches this library.
bool get isGoogleOAuthConfigured => kGoogleClientId.isNotEmpty;
