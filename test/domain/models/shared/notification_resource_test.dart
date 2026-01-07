import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/domain/models/shared/notification_resource.dart';

void main() {
  group('NotificationResource', () {
    group('constructor', () {
      test('should have correct default values', () {
        // When
        final resource = NotificationResource();

        // Then
        expect(resource.id, isNull);
        expect(resource.name, isNull);
        expect(resource.implementation, isNull);
        expect(resource.configContract, isNull);
        expect(resource.fields, isEmpty);
        expect(resource.onGrab, isFalse);
        expect(resource.onDownload, isFalse);
        expect(resource.onUpgrade, isFalse);
        expect(resource.onDownloadFailure, isFalse);
        expect(resource.onApplicationUpdate, isFalse);
        expect(resource.onHealthIssue, isFalse);
        expect(resource.onHealthRestored, isFalse);
        expect(resource.onMovieAdded, isFalse);
        expect(resource.onSeriesAdded, isFalse);
        expect(resource.onMovieDelete, isFalse);
        expect(resource.onSeriesDelete, isFalse);
        expect(resource.onMovieFileDelete, isFalse);
        expect(resource.onEpisodeFileDelete, isFalse);
        expect(resource.onManualInteractionRequired, isFalse);
        expect(resource.includeHealthWarnings, isFalse);
        expect(resource.extra, isEmpty);
      });
    });

    group('fromJson', () {
      test('should parse all fields correctly', () {
        // Given
        final json = {
          'id': 1,
          'name': 'Arrmate Notifications',
          'implementation': 'ntfy',
          'configContract': 'NtfySettings',
          'fields': [
            {'name': 'topic', 'value': 'arrmate-abc123'},
            {'name': 'serverUrl', 'value': 'https://ntfy.sh'},
          ],
          'onGrab': true,
          'onDownload': true,
          'onUpgrade': false,
          'onDownloadFailure': true,
          'onApplicationUpdate': false,
          'onHealthIssue': true,
          'onHealthRestored': true,
          'onMovieAdded': true,
          'onSeriesAdded': true,
          'onMovieDelete': false,
          'onSeriesDelete': false,
          'onMovieFileDelete': true,
          'onEpisodeFileDelete': true,
          'onManualInteractionRequired': false,
          'includeHealthWarnings': true,
          'unknownField': 'preservedValue',
        };

        // When
        final resource = NotificationResource.fromJson(json);

        // Then
        expect(resource.id, 1);
        expect(resource.name, 'Arrmate Notifications');
        expect(resource.implementation, 'ntfy');
        expect(resource.configContract, 'NtfySettings');
        expect(resource.fields.length, 2);
        expect(resource.fields[0].name, 'topic');
        expect(resource.fields[0].value, 'arrmate-abc123');
        expect(resource.onGrab, isTrue);
        expect(resource.onDownload, isTrue);
        expect(resource.onUpgrade, isFalse);
        expect(resource.onDownloadFailure, isTrue);
        expect(resource.onApplicationUpdate, isFalse);
        expect(resource.onHealthIssue, isTrue);
        expect(resource.onHealthRestored, isTrue);
        expect(resource.onMovieAdded, isTrue);
        expect(resource.onSeriesAdded, isTrue);
        expect(resource.onMovieDelete, isFalse);
        expect(resource.onSeriesDelete, isFalse);
        expect(resource.onMovieFileDelete, isTrue);
        expect(resource.onEpisodeFileDelete, isTrue);
        expect(resource.onManualInteractionRequired, isFalse);
        expect(resource.includeHealthWarnings, isTrue);
        expect(resource.extra['unknownField'], 'preservedValue');
      });

      test('should use default values for missing fields', () {
        // Given
        final json = <String, dynamic>{};

        // When
        final resource = NotificationResource.fromJson(json);

        // Then
        expect(resource.id, isNull);
        expect(resource.name, isNull);
        expect(resource.onGrab, isFalse);
        expect(resource.onHealthRestored, isFalse);
        expect(resource.fields, isEmpty);
        expect(resource.extra, isEmpty);
      });
    });

    group('toJson', () {
      test('should serialize all fields correctly', () {
        // Given
        final resource = NotificationResource(
          id: 5,
          name: 'Test Notification',
          implementation: 'ntfy',
          configContract: 'NtfySettings',
          fields: [NotificationField(name: 'topic', value: 'my-topic')],
          onGrab: true,
          onDownload: true,
          onUpgrade: false,
          onDownloadFailure: true,
          onApplicationUpdate: true,
          onHealthIssue: true,
          onHealthRestored: true,
          onMovieAdded: true,
          onSeriesAdded: false,
          onMovieDelete: true,
          onSeriesDelete: false,
          onMovieFileDelete: true,
          onEpisodeFileDelete: false,
          onManualInteractionRequired: true,
          includeHealthWarnings: true,
        );

        // When
        final json = resource.toJson();

        // Then
        expect(json['id'], 5);
        expect(json['name'], 'Test Notification');
        expect(json['implementation'], 'ntfy');
        expect(json['configContract'], 'NtfySettings');
        expect(json['onGrab'], isTrue);
        expect(json['onDownload'], isTrue);
        expect(json['onUpgrade'], isFalse);
        expect(json['onDownloadFailure'], isTrue);
        expect(json['onApplicationUpdate'], isTrue);
        expect(json['onHealthIssue'], isTrue);
        expect(json['onHealthRestored'], isTrue);
        expect(json['onMovieAdded'], isTrue);
        expect(json['onSeriesAdded'], isFalse);
        expect(json['onMovieDelete'], isTrue);
        expect(json['onSeriesDelete'], isFalse);
        expect(json['onMovieFileDelete'], isTrue);
        expect(json['onEpisodeFileDelete'], isFalse);
        expect(json['onManualInteractionRequired'], isTrue);
        expect(json['includeHealthWarnings'], isTrue);
      });

      test('should preserve extra fields in serialization', () {
        // Given
        final resource = NotificationResource(
          name: 'Test',
          extra: {'customField': 'customValue', 'anotherField': 123},
        );

        // When
        final json = resource.toJson();

        // Then
        expect(json['customField'], 'customValue');
        expect(json['anotherField'], 123);
      });
    });

    group('copyWith', () {
      test('should copy all values when no arguments provided', () {
        // Given
        final original = NotificationResource(
          id: 1,
          name: 'Original',
          implementation: 'ntfy',
          onGrab: true,
          onDownload: true,
          onHealthRestored: true,
        );

        // When
        final copy = original.copyWith();

        // Then
        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.implementation, original.implementation);
        expect(copy.onGrab, original.onGrab);
        expect(copy.onDownload, original.onDownload);
        expect(copy.onHealthRestored, original.onHealthRestored);
      });

      test('should override specified values only', () {
        // Given
        final original = NotificationResource(
          id: 1,
          name: 'Original',
          onGrab: true,
          onHealthRestored: false,
        );

        // When
        final copy = original.copyWith(
          name: 'Updated',
          onGrab: false,
          onHealthRestored: true,
        );

        // Then
        expect(copy.id, 1);
        expect(copy.name, 'Updated');
        expect(copy.onGrab, isFalse);
        expect(copy.onHealthRestored, isTrue);
      });
    });
  });

  group('NotificationField', () {
    test('should create field with name and value', () {
      // When
      final field = NotificationField(name: 'topic', value: 'my-topic');

      // Then
      expect(field.name, 'topic');
      expect(field.value, 'my-topic');
    });

    test('fromJson should parse correctly', () {
      // Given
      final json = {'name': 'serverUrl', 'value': 'https://ntfy.sh'};

      // When
      final field = NotificationField.fromJson(json);

      // Then
      expect(field.name, 'serverUrl');
      expect(field.value, 'https://ntfy.sh');
    });

    test('toJson should serialize correctly', () {
      // Given
      final field = NotificationField(
        name: 'topics',
        value: ['topic1', 'topic2'],
      );

      // When
      final json = field.toJson();

      // Then
      expect(json['name'], 'topics');
      expect(json['value'], ['topic1', 'topic2']);
    });
  });
}
