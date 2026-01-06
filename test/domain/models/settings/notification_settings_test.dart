import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/domain/models/settings/notification_settings.dart';

void main() {
  group('NotificationSettings', () {
    group('constructor', () {
      test('should have correct default values', () {
        // When
        const settings = NotificationSettings();

        // Then
        expect(settings.enabled, isFalse);
        expect(settings.ntfyTopic, isNull);
        expect(settings.notifyOnGrab, isTrue);
        expect(settings.notifyOnImport, isTrue);
        expect(settings.notifyOnDownloadFailed, isTrue);
        expect(settings.notifyOnHealthIssue, isFalse);
      });

      test('should accept custom values', () {
        // When
        const settings = NotificationSettings(
          enabled: true,
          ntfyTopic: 'arrmate-abc123',
          notifyOnGrab: false,
          notifyOnImport: false,
          notifyOnDownloadFailed: false,
          notifyOnHealthIssue: true,
        );

        // Then
        expect(settings.enabled, isTrue);
        expect(settings.ntfyTopic, 'arrmate-abc123');
        expect(settings.notifyOnGrab, isFalse);
        expect(settings.notifyOnImport, isFalse);
        expect(settings.notifyOnDownloadFailed, isFalse);
        expect(settings.notifyOnHealthIssue, isTrue);
      });
    });

    group('ntfyServer constant', () {
      test('should be ntfy.sh', () {
        // Then
        expect(NotificationSettings.ntfyServer, 'ntfy.sh');
      });
    });

    group('URL getters', () {
      test('ntfyTopicUrl should return correct URL when topic is set', () {
        // Given
        const settings = NotificationSettings(ntfyTopic: 'my-topic');

        // Then
        expect(settings.ntfyTopicUrl, 'https://ntfy.sh/my-topic');
      });

      test('ntfyTopicUrl should return null when topic is null', () {
        // Given
        const settings = NotificationSettings();

        // Then
        expect(settings.ntfyTopicUrl, isNull);
      });

      test(
        'ntfyWebSocketUrl should return correct WebSocket URL when topic is set',
        () {
          // Given
          const settings = NotificationSettings(ntfyTopic: 'my-topic');

          // Then
          expect(settings.ntfyWebSocketUrl, 'wss://ntfy.sh/my-topic/ws');
        },
      );

      test('ntfyWebSocketUrl should return null when topic is null', () {
        // Given
        const settings = NotificationSettings();

        // Then
        expect(settings.ntfyWebSocketUrl, isNull);
      });

      test(
        'ntfyJsonStreamUrl should return correct JSON stream URL when topic is set',
        () {
          // Given
          const settings = NotificationSettings(ntfyTopic: 'my-topic');

          // Then
          expect(settings.ntfyJsonStreamUrl, 'https://ntfy.sh/my-topic/json');
        },
      );

      test('ntfyJsonStreamUrl should return null when topic is null', () {
        // Given
        const settings = NotificationSettings();

        // Then
        expect(settings.ntfyJsonStreamUrl, isNull);
      });
    });

    group('copyWith', () {
      test('should copy all values when no arguments provided', () {
        // Given
        const original = NotificationSettings(
          enabled: true,
          ntfyTopic: 'test-topic',
          notifyOnGrab: false,
          notifyOnImport: false,
          notifyOnDownloadFailed: false,
          notifyOnHealthIssue: true,
        );

        // When
        final copy = original.copyWith();

        // Then
        expect(copy.enabled, original.enabled);
        expect(copy.ntfyTopic, original.ntfyTopic);
        expect(copy.notifyOnGrab, original.notifyOnGrab);
        expect(copy.notifyOnImport, original.notifyOnImport);
        expect(copy.notifyOnDownloadFailed, original.notifyOnDownloadFailed);
        expect(copy.notifyOnHealthIssue, original.notifyOnHealthIssue);
      });

      test('should override specified values only', () {
        // Given
        const original = NotificationSettings(
          enabled: false,
          ntfyTopic: 'original-topic',
        );

        // When
        final copy = original.copyWith(enabled: true, ntfyTopic: 'new-topic');

        // Then
        expect(copy.enabled, isTrue);
        expect(copy.ntfyTopic, 'new-topic');
        expect(copy.notifyOnGrab, original.notifyOnGrab);
      });
    });

    group('fromJson', () {
      test('should parse all fields correctly', () {
        // Given
        final json = {
          'enabled': true,
          'ntfyTopic': 'arrmate-xyz',
          'notifyOnGrab': false,
          'notifyOnImport': true,
          'notifyOnDownloadFailed': false,
          'notifyOnHealthIssue': true,
        };

        // When
        final settings = NotificationSettings.fromJson(json);

        // Then
        expect(settings.enabled, isTrue);
        expect(settings.ntfyTopic, 'arrmate-xyz');
        expect(settings.notifyOnGrab, isFalse);
        expect(settings.notifyOnImport, isTrue);
        expect(settings.notifyOnDownloadFailed, isFalse);
        expect(settings.notifyOnHealthIssue, isTrue);
      });

      test('should use default values for missing fields', () {
        // Given
        final json = <String, dynamic>{};

        // When
        final settings = NotificationSettings.fromJson(json);

        // Then
        expect(settings.enabled, isFalse);
        expect(settings.ntfyTopic, isNull);
        expect(settings.notifyOnGrab, isTrue);
        expect(settings.notifyOnImport, isTrue);
        expect(settings.notifyOnDownloadFailed, isTrue);
        expect(settings.notifyOnHealthIssue, isFalse);
      });

      test('should handle legacy data without ntfyTopic', () {
        // Given
        final json = {'enabled': true, 'notifyOnGrab': true};

        // When
        final settings = NotificationSettings.fromJson(json);

        // Then
        expect(settings.enabled, isTrue);
        expect(settings.ntfyTopic, isNull);
        expect(settings.notifyOnGrab, isTrue);
      });
    });

    group('toJson', () {
      test('should serialize all fields correctly', () {
        // Given
        const settings = NotificationSettings(
          enabled: true,
          ntfyTopic: 'test-topic',
          notifyOnGrab: false,
          notifyOnImport: true,
          notifyOnDownloadFailed: false,
          notifyOnHealthIssue: true,
        );

        // When
        final json = settings.toJson();

        // Then
        expect(json['enabled'], isTrue);
        expect(json['ntfyTopic'], 'test-topic');
        expect(json['notifyOnGrab'], isFalse);
        expect(json['notifyOnImport'], isTrue);
        expect(json['notifyOnDownloadFailed'], isFalse);
        expect(json['notifyOnHealthIssue'], isTrue);
      });

      test('should serialize null ntfyTopic', () {
        // Given
        const settings = NotificationSettings();

        // When
        final json = settings.toJson();

        // Then
        expect(json['ntfyTopic'], isNull);
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        // Given
        const settings1 = NotificationSettings(
          enabled: true,
          ntfyTopic: 'topic',
          notifyOnGrab: true,
        );
        const settings2 = NotificationSettings(
          enabled: true,
          ntfyTopic: 'topic',
          notifyOnGrab: true,
        );

        // Then
        expect(settings1, equals(settings2));
      });

      test('should not be equal when properties differ', () {
        // Given
        const settings1 = NotificationSettings(ntfyTopic: 'topic1');
        const settings2 = NotificationSettings(ntfyTopic: 'topic2');

        // Then
        expect(settings1, isNot(equals(settings2)));
      });
    });
  });
}
