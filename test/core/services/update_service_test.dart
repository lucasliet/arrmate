import 'package:arrmate/core/services/update_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UpdateService service;
  late MockDio dio;

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Arrmate',
      packageName: 'com.example.arrmate',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
      installerStore: null,
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dio = MockDio();
    service = UpdateService(dio);
  });

  group('UpdateService version tracking', () {
    test(
      'should persist and return the last seen version across calls',
      () async {
        // Given
        expect(await service.lastSeenVersion(), isNull);

        // When
        await service.markVersionSeen('1.2.3');

        // Then
        expect(await service.lastSeenVersion(), '1.2.3');
      },
    );

    test(
      'should return no what\'s new when the version was already seen',
      () async {
        // Given
        await service.markVersionSeen('1.0.0');

        // When
        final result = await service.whatsNewForCurrentVersion();

        // Then
        expect(result, isNull);
        verifyNever(() => dio.get(any(), options: any(named: 'options')));
      },
    );
  });
}
