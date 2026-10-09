import 'package:arrmate/core/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Arrmate',
      packageName: 'br.com.lucasliet.arrmate',
      version: '2.3.0',
      buildNumber: '42',
      buildSignature: '',
      installerStore: null,
    );
    SharedPreferences.setMockInitialValues({});
  });

  group('BackupService round trip', () {
    test('shouldRoundTripEveryPreferenceType', () async {
      // Given
      const instancesJson = '''[
        {"id": "radarr-1", "name": "Main Radarr", "apiKey": "abc"},
        {"id": "sonarr-1", "name": "Main Sonarr", "apiKey": "def"}
      ]''';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('instances', instancesJson);
      await prefs.setInt('minimum_seeding_days', 30);
      await prefs.setBool('remember_torrent_query', true);
      await prefs.setStringList('movie_genres', ['action', 'drama']);
      final service = BackupService();

      // When
      final payload = await service.createPayload();
      final encoded = payload.toEncodedJson();
      SharedPreferences.setMockInitialValues({'stale_key': true});
      final restoredPayload = BackupPayload.fromEncodedJson(encoded);
      final summary = await BackupService().restore(restoredPayload);
      final restoredPrefs = await SharedPreferences.getInstance();

      // Then
      expect(payload.schema, 1);
      expect(payload.appVersion, '2.3.0');
      expect(restoredPayload.preferences, hasLength(4));
      expect(restoredPrefs.getString('instances'), instancesJson);
      expect(restoredPrefs.getInt('minimum_seeding_days'), 30);
      expect(restoredPrefs.getBool('remember_torrent_query'), isTrue);
      expect(restoredPrefs.getStringList('movie_genres'), ['action', 'drama']);
      expect(restoredPrefs.containsKey('stale_key'), isFalse);
      expect(summary.restoredKeys, 4);
      expect(summary.removedKeys, 1);
      expect(summary.instanceCount, 2);
    });

    test('shouldExcludeFrameworkKeys', () async {
      // Given
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('flutter.someInternal', 'framework value');
      await prefs.setString('view_mode', 'grid');

      // When
      final payload = await BackupService().createPayload();

      // Then
      expect(payload.preferences.keys, ['view_mode']);
    });
  });

  group('BackupPayload.fromEncodedJson validation', () {
    test('shouldRejectUnsupportedSchema', () {
      // Given
      const source =
          '{"schema": 99, "appVersion": "2.3.0", "platform": "android", '
          '"createdAt": "2026-10-09T00:00:00Z", "preferences": {}}';

      // When
      void action() => BackupPayload.fromEncodedJson(source);

      // Then
      expect(action, throwsA(isA<BackupFormatException>()));
    });

    test('shouldRejectGarbageJson', () {
      // Given
      const source = 'this is not a backup at all';

      // When
      void action() => BackupPayload.fromEncodedJson(source);

      // Then
      expect(action, throwsA(isA<BackupFormatException>()));
    });

    test('shouldRejectNonMapJson', () {
      // Given
      const source = '[1, 2, 3]';

      // When
      void action() => BackupPayload.fromEncodedJson(source);

      // Then
      expect(action, throwsA(isA<BackupFormatException>()));
    });

    test('shouldRejectMissingPreferencesMap', () {
      // Given
      const source = '{"schema": 1, "appVersion": "2.3.0"}';

      // When
      void action() => BackupPayload.fromEncodedJson(source);

      // Then
      expect(action, throwsA(isA<BackupFormatException>()));
    });
  });

  group('BackupService restore resilience', () {
    test('shouldDropMalformedEntries_whenRestoring', () async {
      // Given
      final payload = BackupPayload(
        schema: 1,
        appVersion: '2.3.0',
        platform: 'android',
        createdAt: DateTime.utc(2026, 10, 9),
        preferences: {
          'valid_key': {'t': 's', 'v': 'kept'},
          'mystery_key': {'t': 'x', 'v': 'unknown'},
        },
      );

      // When
      final summary = await BackupService().restore(payload);
      final prefs = await SharedPreferences.getInstance();

      // Then
      expect(summary.restoredKeys, 1);
      expect(prefs.getString('valid_key'), 'kept');
      expect(prefs.containsKey('mystery_key'), isFalse);
    });

    test('shouldTolerateBrokenInstancesJson', () async {
      // Given
      final payload = BackupPayload(
        schema: 1,
        appVersion: '2.3.0',
        platform: 'android',
        createdAt: DateTime.utc(2026, 10, 9),
        preferences: {
          'instances': {'t': 's', 'v': 'not-json{{['},
        },
      );

      // When
      final summary = await BackupService().restore(payload);

      // Then
      expect(payload.instanceCount, 0);
      expect(summary.instanceCount, 0);
      expect(summary.restoredKeys, 1);
    });
  });
}
