/// Whether this build carries a Google OAuth client.
///
/// The web build never does. Drive backup stays on native platforms so the
/// Desktop client secret is not compiled into the public web bundle.
bool get isGoogleOAuthConfigured => false;
