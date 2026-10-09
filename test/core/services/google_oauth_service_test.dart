import 'dart:convert';

import 'package:arrmate/core/services/google_auth.dart';
import 'package:arrmate/core/services/google_oauth_code_listener.dart';
import 'package:arrmate/core/services/google_oauth_service.dart';
import 'package:arrmate/core/services/google_token_store.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockGoogleTokenStore extends Mock implements GoogleTokenStore {}

class FakeGoogleCodeListener implements GoogleCodeListener {
  final Object? _result;

  FakeGoogleCodeListener({Object? result}) : _result = result;

  String? lastAuthorizationUrl;

  @override
  Future<String> prepareRedirect() async => 'http://localhost:49152';

  @override
  Future<String> waitForCode(String authorizationUrl) async {
    lastAuthorizationUrl = authorizationUrl;
    final result = _result;
    if (result is String) {
      return result;
    }
    throw result!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDio dio;
  late MockGoogleTokenStore tokenStore;

  setUpAll(() {
    registerFallbackValue(<String, String>{});
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = MockDio();
    tokenStore = MockGoogleTokenStore();
    when(
      () => tokenStore.readAll(),
    ).thenAnswer((_) async => <String, String>{});
    when(() => tokenStore.save(any())).thenAnswer((_) async {});
    when(() => tokenStore.clear()).thenAnswer((_) async {});
  });

  GoogleOAuthServiceImpl createService(FakeGoogleCodeListener listener) =>
      GoogleOAuthServiceImpl(
        dio: dio,
        tokenStore: tokenStore,
        codeListener: listener,
      );

  void stubTokenExchange({
    String accessToken = 'access-token',
    String? refreshToken = 'refresh-token',
    num expiresIn = 3600,
  }) {
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/token'),
        statusCode: 200,
        data: {
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'expires_in': expiresIn,
        },
      ),
    );
  }

  void stubUserinfo({
    String email = 'user@example.com',
    String? name = 'Test User',
  }) {
    when(
      () =>
          dio.get<Map<String, dynamic>>(any(), options: any(named: 'options')),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/userinfo'),
        statusCode: 200,
        data: {'email': email, 'name': name},
      ),
    );
  }

  Map<String, String> capturedTokenForm() =>
      verify(
            () => dio.post<Map<String, dynamic>>(
              any(),
              data: captureAny(named: 'data'),
              options: any(named: 'options'),
            ),
          ).captured.single
          as Map<String, String>;

  group('GoogleOAuthServiceImpl signIn', () {
    test('shouldExchangeAuthorizationCode_withPkceAndClientSecret', () async {
      // Given
      final listener = FakeGoogleCodeListener(result: 'auth-code');
      final service = createService(listener);
      stubTokenExchange();
      stubUserinfo();

      // When
      final account = await service.signIn();

      // Then
      final form = capturedTokenForm();
      expect(form['grant_type'], 'authorization_code');
      expect(form['code'], 'auth-code');
      expect(form['client_id'], isNotNull);
      expect(form['client_secret'], isNotNull);
      expect(form['redirect_uri'], 'http://localhost:49152');
      expect(form['code_verifier'], isNotEmpty);

      final authorizationParams = Uri.parse(
        listener.lastAuthorizationUrl!,
      ).queryParameters;
      final expectedChallenge = base64Url
          .encode(sha256.convert(ascii.encode(form['code_verifier']!)).bytes)
          .replaceAll('=', '');
      expect(authorizationParams['code_challenge'], expectedChallenge);
      expect(authorizationParams['code_challenge_method'], 'S256');
      expect(authorizationParams['scope'], contains('drive.appdata'));

      final userinfoOptions =
          verify(
                () => dio.get<Map<String, dynamic>>(
                  any(),
                  options: captureAny(named: 'options'),
                ),
              ).captured.single
              as Options;
      expect(userinfoOptions.headers?['Authorization'], 'Bearer access-token');
      expect(account.email, 'user@example.com');
      expect(account.name, 'Test User');
    });

    test('shouldPersistTokensAfterSignIn', () async {
      // Given
      final listener = FakeGoogleCodeListener(result: 'auth-code');
      final service = createService(listener);
      stubTokenExchange();
      stubUserinfo();

      // When
      await service.signIn();

      // Then
      final savedMaps = verify(
        () => tokenStore.save(captureAny()),
      ).captured.cast<Map<String, String>>();
      final tokenSave = savedMaps.firstWhere(
        (map) => map.containsKey('access_token'),
      );
      expect(tokenSave['access_token'], 'access-token');
      expect(tokenSave['refresh_token'], 'refresh-token');
      expect(tokenSave['access_token_expiry'], isNotNull);
    });

    test('shouldThrowReadableError_whenConsentDenied', () async {
      // Given
      final listener = FakeGoogleCodeListener(
        result: const GoogleOAuthException(
          'Google sign-in was cancelled: consent was denied.',
        ),
      );
      final service = createService(listener);

      // When
      final signInCall = service.signIn();

      // Then
      await expectLater(
        signInCall,
        throwsA(
          isA<GoogleOAuthException>().having(
            (error) => error.message,
            'message',
            contains('denied'),
          ),
        ),
      );
      verifyNever(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    });

    test('shouldRethrowRedirectPending_onWebRedirect', () async {
      // Given
      final listener = FakeGoogleCodeListener(
        result: const GoogleOAuthRedirectPending(),
      );
      final service = createService(listener);

      // When
      final signInCall = service.signIn();

      // Then
      await expectLater(signInCall, throwsA(isA<GoogleOAuthRedirectPending>()));
    });
  });

  group('GoogleOAuthServiceImpl access tokens', () {
    test('shouldRefreshExpiredAccessToken', () async {
      // Given
      when(() => tokenStore.readAll()).thenAnswer(
        (_) async => <String, String>{
          'refresh_token': 'stored-refresh',
          'access_token': 'expired-access',
          'access_token_expiry': '1000',
        },
      );
      stubTokenExchange(accessToken: 'fresh-access', refreshToken: null);
      final service = createService(
        FakeGoogleCodeListener(result: 'auth-code'),
      );

      // When
      final token = await service.getValidAccessToken();

      // Then
      expect(token, 'fresh-access');
      final form = capturedTokenForm();
      expect(form['grant_type'], 'refresh_token');
      expect(form['refresh_token'], 'stored-refresh');
    });

    test('shouldKeepCachedTokenBeforeExpiry', () async {
      // Given
      when(() => tokenStore.readAll()).thenAnswer(
        (_) async => <String, String>{'refresh_token': 'stored-refresh'},
      );
      stubTokenExchange();
      final service = createService(
        FakeGoogleCodeListener(result: 'auth-code'),
      );
      expect(await service.getValidAccessToken(), 'access-token');
      clearInteractions(dio);

      // When
      final token = await service.getValidAccessToken();

      // Then
      expect(token, 'access-token');
      verifyNever(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    });

    test('shouldClearSession_whenRefreshIsRejected', () async {
      // Given
      when(() => tokenStore.readAll()).thenAnswer(
        (_) async => <String, String>{'refresh_token': 'stored-refresh'},
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/token'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/token'),
            statusCode: 400,
            data: {'error': 'invalid_grant'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      final service = createService(
        FakeGoogleCodeListener(result: 'auth-code'),
      );

      // When
      final token = await service.getValidAccessToken();

      // Then
      expect(token, isNull);
      verify(() => tokenStore.clear()).called(1);
    });
  });

  group('GoogleOAuthServiceImpl signOut', () {
    test('shouldRevokeAndClear_onSignOut', () async {
      // Given
      when(() => tokenStore.readAll()).thenAnswer(
        (_) async => <String, String>{'refresh_token': 'stored-refresh'},
      );
      when(
        () => dio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/revoke'),
          statusCode: 200,
        ),
      );
      final service = createService(
        FakeGoogleCodeListener(result: 'auth-code'),
      );

      // When
      await service.signOut();

      // Then
      final captured = verify(
        () => dio.post(
          captureAny(),
          data: captureAny(named: 'data'),
          options: any(named: 'options'),
        ),
      ).captured;
      expect(captured[0], 'https://oauth2.googleapis.com/revoke');
      final revokeForm = captured[1] as Map<String, String>;
      expect(revokeForm['token'], 'stored-refresh');
      verify(() => tokenStore.clear()).called(1);
    });
  });
}
