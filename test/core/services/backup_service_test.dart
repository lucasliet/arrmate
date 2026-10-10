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
      await prefs.setStringList('movie_sort', ['title', 'year']);
      final service = BackupService();

      // When
      final payload = await service.createPayload();
      final encoded = payload.toEncodedJson();
      SharedPreferences.setMockInitialValues({
        'appearance': 'dark',
        'google_oauth_tokens': 'current-session',
        'stale_key': true,
      });
      final restoredPayload = BackupPayload.fromEncodedJson(encoded);
      final summary = await BackupService().restore(restoredPayload);
      final restoredPrefs = await SharedPreferences.getInstance();

      // Then
      expect(payload.schema, 1);
      expect(payload.appVersion, '2.3.0');
      expect(payload.preferences.containsKey('google_oauth_tokens'), isFalse);
      expect(restoredPayload.preferences, hasLength(4));
      expect(restoredPrefs.getString('instances'), instancesJson);
      expect(restoredPrefs.getInt('minimum_seeding_days'), 30);
      expect(restoredPrefs.getBool('remember_torrent_query'), isTrue);
      expect(restoredPrefs.getStringList('movie_sort'), ['title', 'year']);
      expect(restoredPrefs.containsKey('appearance'), isFalse);
      expect(restoredPrefs.getString('google_oauth_tokens'), 'current-session');
      expect(restoredPrefs.getBool('stale_key'), isTrue);
      expect(summary.restoredKeys, 4);
      expect(summary.removedKeys, 1);
      expect(summary.instanceCount, 2);
    });

    test('shouldOmitKeysOutsideTheAllowlist', () async {
      // Given
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'google_oauth_tokens',
        '{"refresh_token":"secret"}',
      );
      await prefs.setString('flutter.someInternal', 'framework value');
      await prefs.setString('last_backup_at', '2026-01-01T00:00:00.000Z');
      await prefs.setInt('last_update_check', 5);
      await prefs.setString('view_mode', 'grid');
      await prefs.setString(
        'movie_add_defaults_radarr-1',
        '{"qualityProfileId":1}',
      );
      await prefs.setString(
        'series_add_defaults_sonarr-1',
        '{"seasonFolder":true}',
      );

      // When
      final payload = await BackupService().createPayload();

      // Then
      expect(payload.preferences.containsKey('google_oauth_tokens'), isFalse);
      expect(payload.preferences.containsKey('flutter.someInternal'), isFalse);
      expect(payload.preferences.containsKey('last_backup_at'), isFalse);
      expect(payload.preferences.containsKey('last_update_check'), isFalse);
      expect(payload.preferences.keys, {
        'view_mode',
        'movie_add_defaults_radarr-1',
        'series_add_defaults_sonarr-1',
      });
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
          'view_mode': {'t': 's', 'v': 'grid'},
          'appearance': {'t': 'x', 'v': 'unknown'},
        },
      );

      // When
      final summary = await BackupService().restore(payload);
      final prefs = await SharedPreferences.getInstance();

      // Then
      expect(summary.restoredKeys, 1);
      expect(prefs.getString('view_mode'), 'grid');
      expect(prefs.containsKey('appearance'), isFalse);
    });

    test('shouldLeaveOauthTokensUntouchedOnRestore', () async {
      // Given
      SharedPreferences.setMockInitialValues({
        'google_oauth_tokens': 'current-session',
        'movie_add_defaults_old': '{"qualityProfileId":1}',
        'last_update_check': 10,
      });
      final payload = BackupPayload(
        schema: 1,
        appVersion: '2.3.0',
        platform: 'web',
        createdAt: DateTime.utc(2026, 10, 9),
        preferences: {
          'view_mode': {'t': 's', 'v': 'grid'},
          'google_oauth_tokens': {'t': 's', 'v': 'old-session'},
          'movie_add_defaults_radarr-1': {
            't': 's',
            'v': '{"qualityProfileId":2}',
          },
          'last_update_check': {'t': 'i', 'v': 99},
        },
      );

      // When
      final summary = await BackupService().restore(payload);
      final prefs = await SharedPreferences.getInstance();

      // Then
      expect(prefs.getString('google_oauth_tokens'), 'current-session');
      expect(prefs.getInt('last_update_check'), 10);
      expect(prefs.containsKey('movie_add_defaults_old'), isFalse);
      expect(prefs.getString('view_mode'), 'grid');
      expect(
        prefs.getString('movie_add_defaults_radarr-1'),
        '{"qualityProfileId":2}',
      );
      expect(summary.restoredKeys, 2);
      expect(summary.removedKeys, 1);
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
