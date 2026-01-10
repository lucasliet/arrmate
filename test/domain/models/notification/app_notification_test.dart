import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/domain/models/notification/app_notification.dart';

void main() {
  group('NotificationType', () {
    test('should have all expected notification types', () {
      expect(NotificationType.values.length, 6);
      expect(NotificationType.values, contains(NotificationType.download));
      expect(NotificationType.values, contains(NotificationType.error));
      expect(NotificationType.values, contains(NotificationType.imported));
      expect(NotificationType.values, contains(NotificationType.upgrade));
      expect(NotificationType.values, contains(NotificationType.warning));
      expect(NotificationType.values, contains(NotificationType.info));
    });
  });

  group('NotificationPriority', () {
    test('should have all expected priority levels', () {
      expect(NotificationPriority.values.length, 3);
      expect(NotificationPriority.values, contains(NotificationPriority.low));
      expect(
        NotificationPriority.values,
        contains(NotificationPriority.medium),
      );
      expect(NotificationPriority.values, contains(NotificationPriority.high));
    });
  });

  group('AppNotification', () {
    final testTimestamp = DateTime(2024, 1, 15, 10, 30);
    final testMetadata = {'movieId': '123', 'eventType': 'download'};

    AppNotification createTestNotification({
      String id = 'test-id',
      String title = 'Test Title',
      String message = 'Test Message',
      NotificationType type = NotificationType.info,
      NotificationPriority priority = NotificationPriority.medium,
      DateTime? timestamp,
      bool isRead = false,
      Map<String, dynamic>? metadata,
    }) {
      return AppNotification(
        id: id,
        title: title,
        message: message,
        type: type,
        priority: priority,
        timestamp: timestamp ?? testTimestamp,
        isRead: isRead,
        metadata: metadata,
      );
    }

    group('constructor', () {
      test('should create notification with all required fields', () {
        final notification = createTestNotification();

        expect(notification.id, 'test-id');
        expect(notification.title, 'Test Title');
        expect(notification.message, 'Test Message');
        expect(notification.type, NotificationType.info);
        expect(notification.priority, NotificationPriority.medium);
        expect(notification.timestamp, testTimestamp);
        expect(notification.isRead, false);
        expect(notification.metadata, isNull);
      });

      test('should create notification with optional metadata', () {
        final notification = createTestNotification(metadata: testMetadata);

        expect(notification.metadata, testMetadata);
        expect(notification.metadata!['movieId'], '123');
      });

      test('should default isRead to false', () {
        final notification = createTestNotification();
        expect(notification.isRead, false);
      });
    });

    group('copyWith', () {
      test('should create copy with updated id', () {
        final original = createTestNotification();
        final copy = original.copyWith(id: 'new-id');

        expect(copy.id, 'new-id');
        expect(copy.title, original.title);
        expect(copy.message, original.message);
      });

      test('should create copy with updated title', () {
        final original = createTestNotification();
        final copy = original.copyWith(title: 'New Title');

        expect(copy.title, 'New Title');
        expect(copy.id, original.id);
      });

      test('should create copy with updated message', () {
        final original = createTestNotification();
        final copy = original.copyWith(message: 'New Message');

        expect(copy.message, 'New Message');
        expect(copy.title, original.title);
      });

      test('should create copy with updated type', () {
        final original = createTestNotification();
        final copy = original.copyWith(type: NotificationType.error);

        expect(copy.type, NotificationType.error);
        expect(copy.priority, original.priority);
      });

      test('should create copy with updated priority', () {
        final original = createTestNotification();
        final copy = original.copyWith(priority: NotificationPriority.high);

        expect(copy.priority, NotificationPriority.high);
        expect(copy.type, original.type);
      });

      test('should create copy with updated timestamp', () {
        final original = createTestNotification();
        final newTimestamp = DateTime(2024, 2, 1);
        final copy = original.copyWith(timestamp: newTimestamp);

        expect(copy.timestamp, newTimestamp);
        expect(copy.id, original.id);
      });

      test('should create copy with updated isRead', () {
        final original = createTestNotification(isRead: false);
        final copy = original.copyWith(isRead: true);

        expect(copy.isRead, true);
        expect(original.isRead, false);
      });

      test('should create copy with updated metadata', () {
        final original = createTestNotification();
        final newMetadata = {'seriesId': '456'};
        final copy = original.copyWith(metadata: newMetadata);

        expect(copy.metadata, newMetadata);
        expect(original.metadata, isNull);
      });

      test('should preserve all fields when no changes', () {
        final original = createTestNotification(metadata: testMetadata);
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.message, original.message);
        expect(copy.type, original.type);
        expect(copy.priority, original.priority);
        expect(copy.timestamp, original.timestamp);
        expect(copy.isRead, original.isRead);
        expect(copy.metadata, original.metadata);
      });
    });

    group('fromJson', () {
      test('should deserialize from valid JSON', () {
        final json = {
          'id': 'json-id',
          'title': 'JSON Title',
          'message': 'JSON Message',
          'type': 'download',
          'priority': 'high',
          'timestamp': 1705315800000,
          'isRead': true,
          'metadata': {'key': 'value'},
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.id, 'json-id');
        expect(notification.title, 'JSON Title');
        expect(notification.message, 'JSON Message');
        expect(notification.type, NotificationType.download);
        expect(notification.priority, NotificationPriority.high);
        expect(
          notification.timestamp,
          DateTime.fromMillisecondsSinceEpoch(1705315800000),
        );
        expect(notification.isRead, true);
        expect(notification.metadata, {'key': 'value'});
      });

      test('should handle missing optional fields with defaults', () {
        final json = {'type': 'info', 'priority': 'medium'};

        final notification = AppNotification.fromJson(json);

        expect(notification.id, '');
        expect(notification.title, '');
        expect(notification.message, '');
        expect(notification.type, NotificationType.info);
        expect(notification.priority, NotificationPriority.medium);
        expect(notification.isRead, false);
        expect(notification.metadata, isNull);
      });

      test('should use default type for invalid type string', () {
        final json = {
          'id': 'test',
          'title': 'Test',
          'message': 'Test',
          'type': 'invalid_type',
          'priority': 'medium',
          'timestamp': 1705315800000,
        };

        final notification = AppNotification.fromJson(json);
        expect(notification.type, NotificationType.info);
      });

      test('should use default priority for invalid priority string', () {
        final json = {
          'id': 'test',
          'title': 'Test',
          'message': 'Test',
          'type': 'error',
          'priority': 'invalid_priority',
          'timestamp': 1705315800000,
        };

        final notification = AppNotification.fromJson(json);
        expect(notification.priority, NotificationPriority.medium);
      });

      test('should handle metadata as Map<dynamic, dynamic>', () {
        final json = {
          'id': 'test',
          'title': 'Test',
          'message': 'Test',
          'type': 'info',
          'priority': 'medium',
          'timestamp': 1705315800000,
          'metadata': <dynamic, dynamic>{'key': 'value', 'count': 42},
        };

        final notification = AppNotification.fromJson(json);
        expect(notification.metadata, isNotNull);
        expect(notification.metadata!['key'], 'value');
        expect(notification.metadata!['count'], 42);
      });

      test('should handle null metadata', () {
        final json = {
          'id': 'test',
          'title': 'Test',
          'message': 'Test',
          'type': 'info',
          'priority': 'medium',
          'timestamp': 1705315800000,
          'metadata': null,
        };

        final notification = AppNotification.fromJson(json);
        expect(notification.metadata, isNull);
      });

      test('should use current time for missing timestamp', () {
        final before = DateTime.now();
        final json = {
          'id': 'test',
          'title': 'Test',
          'message': 'Test',
          'type': 'info',
          'priority': 'medium',
        };

        final notification = AppNotification.fromJson(json);
        final after = DateTime.now();

        expect(
          notification.timestamp.isAfter(
            before.subtract(const Duration(seconds: 1)),
          ),
          true,
        );
        expect(
          notification.timestamp.isBefore(
            after.add(const Duration(seconds: 1)),
          ),
          true,
        );
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        final notification = createTestNotification(
          id: 'json-id',
          title: 'JSON Title',
          message: 'JSON Message',
          type: NotificationType.error,
          priority: NotificationPriority.high,
          timestamp: DateTime.fromMillisecondsSinceEpoch(1705315800000),
          isRead: true,
          metadata: testMetadata,
        );

        final json = notification.toJson();

        expect(json['id'], 'json-id');
        expect(json['title'], 'JSON Title');
        expect(json['message'], 'JSON Message');
        expect(json['type'], 'error');
        expect(json['priority'], 'high');
        expect(json['timestamp'], 1705315800000);
        expect(json['isRead'], true);
        expect(json['metadata'], testMetadata);
      });

      test('should omit metadata if null', () {
        final notification = createTestNotification();
        final json = notification.toJson();

        expect(json.containsKey('metadata'), false);
      });

      test('should include metadata if present', () {
        final notification = createTestNotification(metadata: testMetadata);
        final json = notification.toJson();

        expect(json.containsKey('metadata'), true);
        expect(json['metadata'], testMetadata);
      });

      test('should round-trip through JSON serialization', () {
        final original = createTestNotification(
          id: 'round-trip',
          title: 'Round Trip',
          message: 'Round Trip Message',
          type: NotificationType.imported,
          priority: NotificationPriority.low,
          isRead: true,
          metadata: testMetadata,
        );

        final json = original.toJson();
        final deserialized = AppNotification.fromJson(json);

        expect(deserialized.id, original.id);
        expect(deserialized.title, original.title);
        expect(deserialized.message, original.message);
        expect(deserialized.type, original.type);
        expect(deserialized.priority, original.priority);
        expect(
          deserialized.timestamp.millisecondsSinceEpoch,
          original.timestamp.millisecondsSinceEpoch,
        );
        expect(deserialized.isRead, original.isRead);
        expect(deserialized.metadata, original.metadata);
      });
    });

    group('iconName', () {
      test('should return correct icon for download type', () {
        final notification = createTestNotification(
          type: NotificationType.download,
        );
        expect(notification.iconName, 'download');
      });

      test('should return correct icon for error type', () {
        final notification = createTestNotification(
          type: NotificationType.error,
        );
        expect(notification.iconName, 'error');
      });

      test('should return correct icon for imported type', () {
        final notification = createTestNotification(
          type: NotificationType.imported,
        );
        expect(notification.iconName, 'check_circle');
      });

      test('should return correct icon for upgrade type', () {
        final notification = createTestNotification(
          type: NotificationType.upgrade,
        );
        expect(notification.iconName, 'system_update');
      });

      test('should return correct icon for warning type', () {
        final notification = createTestNotification(
          type: NotificationType.warning,
        );
        expect(notification.iconName, 'warning');
      });

      test('should return correct icon for info type', () {
        final notification = createTestNotification(
          type: NotificationType.info,
        );
        expect(notification.iconName, 'info');
      });
    });

    group('equality', () {
      test('should be equal for identical notifications', () {
        final notification1 = createTestNotification(metadata: testMetadata);
        final notification2 = createTestNotification(metadata: testMetadata);

        expect(notification1, equals(notification2));
      });

      test('should not be equal for different ids', () {
        final notification1 = createTestNotification(id: 'id1');
        final notification2 = createTestNotification(id: 'id2');

        expect(notification1, isNot(equals(notification2)));
      });

      test('should not be equal for different titles', () {
        final notification1 = createTestNotification(title: 'Title 1');
        final notification2 = createTestNotification(title: 'Title 2');

        expect(notification1, isNot(equals(notification2)));
      });

      test('should not be equal for different types', () {
        final notification1 = createTestNotification(
          type: NotificationType.info,
        );
        final notification2 = createTestNotification(
          type: NotificationType.error,
        );

        expect(notification1, isNot(equals(notification2)));
      });

      test('should not be equal for different isRead status', () {
        final notification1 = createTestNotification(isRead: false);
        final notification2 = createTestNotification(isRead: true);

        expect(notification1, isNot(equals(notification2)));
      });

      test('should not be equal for different metadata', () {
        final notification1 = createTestNotification(
          metadata: {'key': 'value1'},
        );
        final notification2 = createTestNotification(
          metadata: {'key': 'value2'},
        );

        expect(notification1, isNot(equals(notification2)));
      });

      test('should have same hashCode for equal notifications', () {
        final notification1 = createTestNotification(metadata: testMetadata);
        final notification2 = createTestNotification(metadata: testMetadata);

        expect(notification1.hashCode, equals(notification2.hashCode));
      });
    });
  });
}
