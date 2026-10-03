import 'package:arrmate/core/services/update_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  group('platform release packages', () {
    const checksum =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    final releaseAssets = [
      'app-arm64-v8a-release.apk',
      'app-armeabi-v7a-release.apk',
      'arrmate-windows-x64.zip',
      'arrmate-linux-x64.AppImage',
      'arrmate-macos.zip',
    ];
    void mockRelease({
      List<String>? names,
      String? digest = 'sha256:$checksum',
    }) {
      when(() => dio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/releases/latest'),
          statusCode: 200,
          data: {
            'tag_name': 'v2.1.0',
            'body': 'Update notes',
            'published_at': '2026-10-02T00:00:00Z',
            'assets': [
              for (final name in names ?? releaseAssets)
                {
                  'name': name,
                  'size': 123,
                  'digest': digest,
                  'browser_download_url':
                      'https://github.com/lucasliet/arrmate/releases/download/v2.1.0/$name',
                },
            ],
          },
        ),
      );
    }

    for (final entry in {
      TargetPlatform.windows: 'arrmate-windows-x64.zip',
      TargetPlatform.linux: 'arrmate-linux-x64.AppImage',
      TargetPlatform.macOS: 'arrmate-macos.zip',
      TargetPlatform.android: 'app-arm64-v8a-release.apk',
    }.entries) {
      test(
        'selects ${entry.key.name} without falling back to another platform',
        () async {
          mockRelease();
          service = UpdateService(
            dio,
            targetPlatform: entry.key,
            androidAbis: () async => ['arm64-v8a'],
          );
          final update = await service.checkForUpdate(force: true);
          expect(update!.assetName, entry.value);
          expect(update.sha256Digest, checksum);
          expect(update.sizeBytes, 123);
          expect(update.version, '2.1.0');
        },
      );
    }
    test(
      'reports a missing Linux AppImage instead of offering an APK',
      () async {
        mockRelease(names: ['app-arm64-v8a-release.apk']);
        service = UpdateService(dio, targetPlatform: TargetPlatform.linux);
        await expectLater(
          service.checkForUpdate(force: true),
          throwsStateError,
        );
      },
    );
    test('rejects a desktop package without a checksum', () async {
      mockRelease(digest: null);
      service = UpdateService(dio, targetPlatform: TargetPlatform.windows);
      await expectLater(service.checkForUpdate(force: true), throwsStateError);
    });
    test('does not check iOS through the Android updater', () async {
      service = UpdateService(dio, targetPlatform: TargetPlatform.iOS);
      expect(await service.checkForUpdate(force: true), isNull);
      verifyNever(() => dio.get(any(), options: any(named: 'options')));
    });
  });
}
