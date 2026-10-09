import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/google_oauth_config.dart';
import 'google_auth.dart';
import 'google_oauth_code_listener.dart';
import 'google_token_store.dart';
import 'logger_service.dart';

/// Error thrown across the Google OAuth flow carrying a message that is safe
/// to surface directly to the user.
class GoogleOAuthException implements Exception {
  /// Human-readable description of the failure.
  final String message;

  /// Creates the exception with the user-facing [message].
  const GoogleOAuthException(this.message);

  @override
  String toString() => message;
}

/// [GoogleOAuthService] that talks to Google's OAuth 2.0 endpoints directly
/// over HTTPS, protecting the authorization-code exchange with PKCE.
///
/// Native builds receive the redirect on a loopback server; the web build
/// finishes the flow on the next app load, when [restoreSession] picks the
/// `?code=` parameter back up.
class GoogleOAuthServiceImpl extends GoogleOAuthService {
  static const String _tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const String _revokeEndpoint = 'https://oauth2.googleapis.com/revoke';
  static const String _authorizationEndpoint =
      'https://accounts.google.com/o/oauth2/v2/auth';
  static const String _userinfoEndpoint =
      'https://www.googleapis.com/oauth2/v3/userinfo';

  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenKey = 'access_token';
  static const String _accessTokenExpiryKey = 'access_token_expiry';
  static const String _pendingVerifierKey = 'pending_verifier';
  static const String _pendingStateKey = 'pending_state';

  static const Duration _tokenExpiryMargin = Duration(seconds: 60);

  final Dio _dio;
  final GoogleTokenStore _tokenStore;
  final GoogleCodeListener _codeListener;

  String? _cachedAccessToken;
  DateTime? _cachedAccessTokenExpiry;

  /// Creates the service, injecting the HTTP client [dio], the [tokenStore]
  /// and the [codeListener]; platform defaults are used for anything omitted.
  GoogleOAuthServiceImpl({
    Dio? dio,
    GoogleTokenStore? tokenStore,
    GoogleCodeListener? codeListener,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 15),
             ),
           ),
       _tokenStore = tokenStore ?? createDefaultGoogleTokenStore(),
       _codeListener = codeListener ?? createDefaultGoogleCodeListener();

  String get _clientId => kIsWeb ? kGoogleWebClientId : kGoogleClientId;

  String get _clientSecret =>
      kIsWeb ? kGoogleWebClientSecret : kGoogleClientSecret;

  /// Restores a previous session from the persisted refresh token, resuming
  /// a pending web redirect first, or returns null when nothing restores.
  @override
  Future<GoogleAccount?> restoreSession() async {
    try {
      final resumedAccount = await _resumeWebRedirectIfAvailable();
      if (resumedAccount != null) {
        return resumedAccount;
      }
      final accessToken = await getValidAccessToken();
      if (accessToken == null) {
        return null;
      }
      return _fetchAccount(accessToken);
    } catch (error, stackTrace) {
      logger.warning('[GoogleOAuth] Session restore failed', error, stackTrace);
      return null;
    }
  }

  /// Runs the PKCE-protected authorization-code flow and returns the signed-in
  /// account, throwing [GoogleOAuthRedirectPending] on the web when the
  /// browser navigation takes over.
  @override
  Future<GoogleAccount> signIn() async {
    final redirectUri = await _codeListener.prepareRedirect();
    final verifier = _generatePkceVerifier();
    final state = _generateState();
    final authorizationUrl = Uri.parse(_authorizationEndpoint).replace(
      queryParameters: <String, String>{
        'client_id': _clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': kGoogleBackupScopes.join(' '),
        'access_type': 'offline',
        'prompt': 'consent',
        'state': state,
        'code_challenge': _pkceChallenge(verifier),
        'code_challenge_method': 'S256',
      },
    );

    logger.info('[GoogleOAuth] Starting interactive sign-in');
    await _tokenStore.save(<String, String>{
      _pendingVerifierKey: verifier,
      _pendingStateKey: state,
    });

    final String code;
    try {
      code = await _codeListener.waitForCode(authorizationUrl.toString());
    } on GoogleOAuthRedirectPending {
      logger.info('[GoogleOAuth] Sign-in continues in the browser');
      rethrow;
    }

    final tokenData = await _exchangeAuthorizationCode(
      code: code,
      verifier: verifier,
      redirectUri: redirectUri,
    );
    return _completeSignIn(tokenData);
  }

  /// Returns a non-expired access token from the in-memory cache, refreshing
  /// it when missing or inside the 60 second expiry margin, or null when no
  /// session is persisted.
  @override
  Future<String?> getValidAccessToken() async {
    final stored = await _tokenStore.readAll();
    if ((stored[_refreshTokenKey] ?? '').isEmpty) {
      return null;
    }
    final cachedToken = _cachedAccessToken;
    final cachedExpiry = _cachedAccessTokenExpiry;
    if (cachedToken != null &&
        cachedExpiry != null &&
        cachedExpiry.isAfter(DateTime.now().add(_tokenExpiryMargin))) {
      return cachedToken;
    }
    return refreshAccessToken();
  }

  /// Forces a token refresh, clearing the session when Google rejects the
  /// refresh token, and returns the fresh token or null.
  @override
  Future<String?> refreshAccessToken() async {
    final stored = await _tokenStore.readAll();
    final refreshToken = stored[_refreshTokenKey];
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        _tokenEndpoint,
        data: <String, String>{
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    } on DioException catch (error, stackTrace) {
      if (error.response?.statusCode == 400) {
        logger.warning(
          '[GoogleOAuth] Refresh token rejected, clearing the session',
        );
        await _clearSession();
        return null;
      }
      logger.error('[GoogleOAuth] Token refresh failed', error, stackTrace);
      return null;
    }

    if (response.statusCode != 200 || response.data == null) {
      logger.warning(
        '[GoogleOAuth] Token refresh returned status ${response.statusCode}',
      );
      return null;
    }
    final accessToken = response.data!['access_token'] as String?;
    final expiresIn = (response.data!['expires_in'] as num?)?.toInt();
    if (accessToken == null || accessToken.isEmpty || expiresIn == null) {
      logger.warning('[GoogleOAuth] Token refresh response missing fields');
      return null;
    }
    await _persistTokens(
      accessToken: accessToken,
      expiresIn: expiresIn,
      refreshToken: response.data!['refresh_token'] as String?,
    );
    logger.debug('[GoogleOAuth] Access token refreshed');
    return accessToken;
  }

  /// Revokes the granted access best-effort and clears the persisted session
  /// together with the in-memory token cache.
  @override
  Future<void> signOut() async {
    final stored = await _tokenStore.readAll();
    final refreshToken = stored[_refreshTokenKey];
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _dio.post(
          _revokeEndpoint,
          data: <String, String>{'token': refreshToken},
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );
        logger.info('[GoogleOAuth] Refresh token revoked');
      } catch (error, stackTrace) {
        logger.warning(
          '[GoogleOAuth] Token revoke failed, continuing sign-out',
          error,
          stackTrace,
        );
      }
    }
    await _clearSession();
    logger.info('[GoogleOAuth] Signed out');
  }

  Future<GoogleAccount?> _resumeWebRedirectIfAvailable() async {
    if (!kIsWeb) {
      return null;
    }
    final currentParams = Uri.base.queryParameters;
    final code = currentParams['code'];
    if (code == null || code.isEmpty) {
      return null;
    }
    final stored = await _tokenStore.readAll();
    final pendingState = stored[_pendingStateKey];
    final verifier = stored[_pendingVerifierKey];
    if (pendingState == null ||
        pendingState.isEmpty ||
        verifier == null ||
        verifier.isEmpty ||
        currentParams['state'] != pendingState) {
      logger.warning(
        '[GoogleOAuth] Ignoring web redirect with missing or mismatched state',
      );
      return null;
    }

    logger.info('[GoogleOAuth] Resuming pending web sign-in redirect');
    try {
      final tokenData = await _exchangeAuthorizationCode(
        code: code,
        verifier: verifier,
        redirectUri: await _codeListener.prepareRedirect(),
      );
      await _tokenStore.save(<String, String>{
        _pendingVerifierKey: '',
        _pendingStateKey: '',
      });
      return _completeSignIn(tokenData);
    } catch (error, stackTrace) {
      logger.warning(
        '[GoogleOAuth] Web redirect resume failed',
        error,
        stackTrace,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>> _exchangeAuthorizationCode({
    required String code,
    required String verifier,
    required String redirectUri,
  }) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        _tokenEndpoint,
        data: <String, String>{
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code_verifier': verifier,
          'redirect_uri': redirectUri,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    } on DioException catch (error, stackTrace) {
      logger.error(
        '[GoogleOAuth] Authorization code exchange failed',
        error,
        stackTrace,
      );
      throw GoogleOAuthException(
        'Google sign-in failed: network or server error '
        '(status ${error.response?.statusCode ?? 'unavailable'}).',
      );
    }
    if (response.statusCode != 200 || response.data == null) {
      throw GoogleOAuthException(
        'Google sign-in failed: the server returned status '
        '${response.statusCode ?? 'unavailable'}.',
      );
    }
    return response.data!;
  }

  Future<GoogleAccount> _completeSignIn(Map<String, dynamic> tokenData) async {
    final accessToken = tokenData['access_token'] as String?;
    final expiresIn = (tokenData['expires_in'] as num?)?.toInt();
    if (accessToken == null || accessToken.isEmpty || expiresIn == null) {
      throw const GoogleOAuthException(
        'Google sign-in failed: the token response was incomplete.',
      );
    }
    await _persistTokens(
      accessToken: accessToken,
      expiresIn: expiresIn,
      refreshToken: tokenData['refresh_token'] as String?,
    );
    logger.debug('[GoogleOAuth] Tokens persisted, loading the account');
    return _fetchAccount(accessToken);
  }

  Future<GoogleAccount> _fetchAccount(String accessToken) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>(
        _userinfoEndpoint,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (error, stackTrace) {
      logger.error('[GoogleOAuth] Account fetch failed', error, stackTrace);
      throw GoogleOAuthException(
        'Google sign-in failed: network or server error '
        '(status ${error.response?.statusCode ?? 'unavailable'}).',
      );
    }
    if (response.statusCode != 200 || response.data == null) {
      throw GoogleOAuthException(
        'Google sign-in failed: the account could not be loaded '
        '(status ${response.statusCode ?? 'unavailable'}).',
      );
    }
    final email = response.data!['email'] as String?;
    if (email == null || email.isEmpty) {
      throw const GoogleOAuthException(
        'Google sign-in failed: the account has no e-mail.',
      );
    }
    final account = GoogleAccount(
      email: email,
      name: response.data!['name'] as String?,
    );
    logger.info('[GoogleOAuth] Signed in as ${account.email}');
    return account;
  }

  Future<void> _persistTokens({
    required String accessToken,
    required int expiresIn,
    String? refreshToken,
  }) async {
    final expiry = DateTime.now().add(Duration(seconds: expiresIn));
    _cachedAccessToken = accessToken;
    _cachedAccessTokenExpiry = expiry;
    await _tokenStore.save(<String, String>{
      _accessTokenKey: accessToken,
      _accessTokenExpiryKey: expiry.millisecondsSinceEpoch.toString(),
      if (refreshToken != null && refreshToken.isNotEmpty)
        _refreshTokenKey: refreshToken,
    });
  }

  Future<void> _clearSession() async {
    _cachedAccessToken = null;
    _cachedAccessTokenExpiry = null;
    await _tokenStore.clear();
  }

  static String _generatePkceVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(64, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _generateState() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _pkceChallenge(String verifier) {
    final digest = sha256.convert(ascii.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}

final googleOAuthServiceProvider = Provider<GoogleOAuthService>(
  (ref) => GoogleOAuthServiceImpl(),
);
