import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/core/services/in_app_notification_service.dart';
import 'package:arrmate/domain/models/notification/app_notification.dart';
import 'package:arrmate/domain/models/notification/ntfy_message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences
  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  Map<String, dynamic> mockPrefs = {};

  void setupMockMethodChannel() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return Map<String, dynamic>.from(mockPrefs);
          }
          if (methodCall.method == 'setString') {
            final key = methodCall.arguments['key'] as String;
            final value = methodCall.arguments['value'] as String;
            mockPrefs[key] = value;
            return true;
          }
          if (methodCall.method == 'setInt') {
            final key = methodCall.arguments['key'] as String;
            final value = methodCall.arguments['value'] as int;
            mockPrefs[key] = value;
            return true;
          }
          if (methodCall.method == 'getInt') {
            final key = methodCall.arguments['key'] as String;
            return mockPrefs[key] as int?;
          }
          if (methodCall.method == 'getString') {
            final key = methodCall.arguments['key'] as String;
            return mockPrefs[key] as String?;
          }
          if (methodCall.method == 'remove') {
            final key = methodCall.arguments['key'] as String;
            mockPrefs.remove(key);
            return true;
          }
          return null;
        });
  }

  group('InAppNotificationService', () {
    late InAppNotificationService service;

    setUp(() async {
      mockPrefs = {};
      setupMockMethodChannel();
      service = InAppNotificationService();
      await service.init();
      await service.clearAll();
    });

    tearDown(() {
      mockPrefs.clear();
    });

    group('initialization', () {
      test('should initialize with empty notifications list', () async {
        // Given - Service already initialized and cleared in setUp
        // Then
        expect(service.notifications, isEmpty);
        expect(service.unreadCount, 0);
      });

      test('should be ready for use after init', () async {
        // Given - Service already initialized in setUp
        // When - Add a notification to verify service works
        final notification = AppNotification(
          id: 'test-init',
          title: 'Test',
          message: 'Message',
          type: NotificationType.info,
          priority: NotificationPriority.medium,
          timestamp: DateTime.now(),
        );
        await service.addNotification(notification);

        // Then
        expect(service.notifications.length, 1);
        expect(service.notifications[0].id, 'test-init');
      });
    });

    group('addNotification', () {
      test('should add a new notification', () async {
        final notification = AppNotification(
          id: 'new-notif',
          title: 'New Notification',
          message: 'Test message',
          type: NotificationType.download,
          priority: NotificationPriority.high,
          timestamp: DateTime.now(),
        );

        await service.addNotification(notification);

        expect(service.notifications.length, 1);
        expect(service.notifications[0].id, 'new-notif');
        expect(service.unreadCount, 1);
      });

      test('should not add duplicate notifications', () async {
        final notification = AppNotification(
          id: 'duplicate',
          title: 'Duplicate',
          message: 'Test',
          type: NotificationType.info,
          priority: NotificationPriority.medium,
          timestamp: DateTime.now(),
        );

        await service.addNotification(notification);
        await service.addNotification(notification);

        expect(service.notifications.length, 1);
      });

      test('should trim notifications when exceeding max limit', () async {
        // Add 101 notifications (max is 100)
        for (int i = 0; i < 101; i++) {
          final notification = AppNotification(
            id: 'notif-$i',
            title: 'Notification $i',
            message: 'Message $i',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now().add(Duration(seconds: i)),
          );
          await service.addNotification(notification);
        }

        expect(service.notifications.length, 100);
        // Should keep the most recent ones
        expect(service.notifications.first.id, 'notif-100');
      });
    });

    group('addFromNtfyMessage', () {
      test(
        'should create notification from ntfy message with download tags',
        () async {
          final message = NtfyMessage(
            id: 'ntfy-1',
            time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            event: 'message',
            topic: 'test-topic',
            title: 'Download Started',
            message: 'Movie download started',
            tags: ['arrow_down'],
            priority: 4,
          );

          final notification = await service.addFromNtfyMessage(message);

          expect(notification.id, 'ntfy-1');
          expect(notification.title, 'Download Started');
          expect(notification.type, NotificationType.download);
          expect(notification.priority, NotificationPriority.high);
          expect(service.notifications.length, 1);
        },
      );

      test('should infer error type from tags', () async {
        final message = NtfyMessage(
          id: 'error-1',
          time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          event: 'message',
          topic: 'test-topic',
          title: 'Error',
          message: 'Something failed',
          tags: ['x'],
        );

        final notification = await service.addFromNtfyMessage(message);

        expect(notification.type, NotificationType.error);
      });

      test('should infer imported type from tags', () async {
        final message = NtfyMessage(
          id: 'import-1',
          time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          event: 'message',
          topic: 'test-topic',
          title: 'Imported',
          message: 'Movie imported successfully',
          tags: ['white_check_mark'],
        );

        final notification = await service.addFromNtfyMessage(message);

        expect(notification.type, NotificationType.imported);
      });

      test('should infer type from message content when no tags', () async {
        final message = NtfyMessage(
          id: 'content-1',
          time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          event: 'message',
          topic: 'test-topic',
          title: 'Download Failed',
          message: 'Error occurred during download',
        );

        final notification = await service.addFromNtfyMessage(message);

        expect(notification.type, NotificationType.error);
      });

      test('should infer upgrade type from message content', () async {
        final message = NtfyMessage(
          id: 'upgrade-1',
          time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          event: 'message',
          topic: 'test-topic',
          title: 'Upgrade Available',
          message: 'New version available',
        );

        final notification = await service.addFromNtfyMessage(message);

        expect(notification.type, NotificationType.upgrade);
      });

      test('should infer warning type from message content', () async {
        final message = NtfyMessage(
          id: 'warning-1',
          time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          event: 'message',
          topic: 'test-topic',
          title: 'Warning',
          message: 'Disk space low',
        );

        final notification = await service.addFromNtfyMessage(message);

        expect(notification.type, NotificationType.warning);
      });

      test('should default to info type when no matches', () async {
        final message = NtfyMessage(
          id: 'info-1',
          time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          event: 'message',
          topic: 'test-topic',
          title: 'Information',
          message: 'Just some info',
        );

        final notification = await service.addFromNtfyMessage(message);

        expect(notification.type, NotificationType.info);
      });

      test('should map ntfy priority to notification priority', () async {
        // Low priority (1-2)
        final lowMessage = NtfyMessage(
          id: 'low',
          time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          event: 'message',
          topic: 'test',
          priority: 2,
        );
        final lowNotif = await service.addFromNtfyMessage(lowMessage);
        expect(lowNotif.priority, NotificationPriority.low);

        // Medium priority (3)
        final medMessage = NtfyMessage(
          id: 'med',
          time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          event: 'message',
          topic: 'test',
          priority: 3,
        );
        final medNotif = await service.addFromNtfyMessage(medMessage);
        expect(medNotif.priority, NotificationPriority.medium);

        // High priority (4-5)
        final highMessage = NtfyMessage(
          id: 'high',
          time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          event: 'message',
          topic: 'test',
          priority: 5,
        );
        final highNotif = await service.addFromNtfyMessage(highMessage);
        expect(highNotif.priority, NotificationPriority.high);
      });

      test('should include metadata from ntfy message', () async {
        final message = NtfyMessage(
          id: 'meta-1',
          time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          event: 'message',
          topic: 'test-topic',
          title: 'Test',
          message: 'Test message',
          tags: ['test'],
          click: 'arrmate://movie/123',
        );

        final notification = await service.addFromNtfyMessage(message);

        expect(notification.metadata, isNotNull);
        expect(notification.metadata!['topic'], 'test-topic');
        expect(notification.metadata!['tags'], ['test']);
        expect(notification.metadata!['click'], 'arrmate://movie/123');
      });

      test('should use default title when ntfy message has no title', () async {
        final message = NtfyMessage(
          id: 'no-title',
          time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          event: 'message',
          topic: 'test-topic',
          message: 'Message without title',
        );

        final notification = await service.addFromNtfyMessage(message);

        expect(notification.title, 'Arrmate');
      });
    });

    group('markAsRead', () {
      test('should mark notification as read', () async {
        final notification = AppNotification(
          id: 'mark-read',
          title: 'Test',
          message: 'Test',
          type: NotificationType.info,
          priority: NotificationPriority.medium,
          timestamp: DateTime.now(),
          isRead: false,
        );

        await service.addNotification(notification);
        expect(service.unreadCount, 1);

        await service.markAsRead('mark-read');

        expect(service.unreadCount, 0);
        expect(service.notifications[0].isRead, true);
      });

      test('should do nothing for non-existent notification', () async {
        await service.markAsRead('non-existent');

        expect(service.notifications, isEmpty);
      });
    });

    group('markAllAsRead', () {
      test('should mark all notifications as read', () async {
        for (int i = 0; i < 5; i++) {
          await service.addNotification(
            AppNotification(
              id: 'notif-$i',
              title: 'Test $i',
              message: 'Message $i',
              type: NotificationType.info,
              priority: NotificationPriority.medium,
              timestamp: DateTime.now(),
              isRead: false,
            ),
          );
        }

        expect(service.unreadCount, 5);

        await service.markAllAsRead();

        expect(service.unreadCount, 0);
        expect(service.notifications.every((n) => n.isRead), true);
      });

      test('should handle empty notifications list', () async {
        await service.markAllAsRead();

        expect(service.notifications, isEmpty);
      });

      test('should not modify already read notifications', () async {
        await service.addNotification(
          AppNotification(
            id: 'already-read',
            title: 'Test',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
            isRead: true,
          ),
        );

        await service.markAllAsRead();

        expect(service.notifications[0].isRead, true);
      });
    });

    group('dismiss', () {
      test('should remove notification by id', () async {
        await service.addNotification(
          AppNotification(
            id: 'dismiss-me',
            title: 'Test',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          ),
        );

        expect(service.notifications.length, 1);

        await service.dismiss('dismiss-me');

        expect(service.notifications, isEmpty);
      });

      test(
        'should update unread count after dismissing unread notification',
        () async {
          await service.addNotification(
            AppNotification(
              id: 'unread',
              title: 'Test',
              message: 'Test',
              type: NotificationType.info,
              priority: NotificationPriority.medium,
              timestamp: DateTime.now(),
              isRead: false,
            ),
          );

          expect(service.unreadCount, 1);

          await service.dismiss('unread');

          expect(service.unreadCount, 0);
        },
      );

      test('should do nothing for non-existent notification', () async {
        await service.addNotification(
          AppNotification(
            id: 'existing',
            title: 'Test',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          ),
        );

        await service.dismiss('non-existent');

        expect(service.notifications.length, 1);
      });
    });

    group('clearAll', () {
      test('should remove all notifications', () async {
        for (int i = 0; i < 5; i++) {
          await service.addNotification(
            AppNotification(
              id: 'notif-$i',
              title: 'Test $i',
              message: 'Message $i',
              type: NotificationType.info,
              priority: NotificationPriority.medium,
              timestamp: DateTime.now(),
            ),
          );
        }

        expect(service.notifications.length, 5);

        await service.clearAll();

        expect(service.notifications, isEmpty);
        expect(service.unreadCount, 0);
      });
    });

    group('notifications sorting', () {
      test(
        'should return notifications sorted by timestamp (newest first)',
        () async {
          final old = AppNotification(
            id: 'old',
            title: 'Old',
            message: 'Old',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime(2024, 1, 1),
          );

          final middle = AppNotification(
            id: 'middle',
            title: 'Middle',
            message: 'Middle',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime(2024, 1, 15),
          );

          final newest = AppNotification(
            id: 'newest',
            title: 'Newest',
            message: 'Newest',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime(2024, 2, 1),
          );

          // Add in random order
          await service.addNotification(middle);
          await service.addNotification(old);
          await service.addNotification(newest);

          final notifications = service.notifications;
          expect(notifications[0].id, 'newest');
          expect(notifications[1].id, 'middle');
          expect(notifications[2].id, 'old');
        },
      );
    });

    group('unreadCount', () {
      test('should return correct count of unread notifications', () async {
        await service.addNotification(
          AppNotification(
            id: '1',
            title: 'Unread 1',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
            isRead: false,
          ),
        );

        await service.addNotification(
          AppNotification(
            id: '2',
            title: 'Read',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
            isRead: true,
          ),
        );

        await service.addNotification(
          AppNotification(
            id: '3',
            title: 'Unread 2',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
            isRead: false,
          ),
        );

        expect(service.unreadCount, 2);
      });
    });
  });
}
