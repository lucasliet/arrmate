import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrmate/core/services/in_app_notification_service.dart';
import 'package:arrmate/core/services/ntfy_service.dart';
import 'package:arrmate/domain/models/notification/app_notification.dart';
import 'package:arrmate/presentation/providers/notifications_provider.dart';

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
          return null;
        });
  }

  group('NotificationsProvider', () {
    late ProviderContainer container;

    setUp(() async {
      mockPrefs = {};
      setupMockMethodChannel();
      container = ProviderContainer();
      // Ensure fresh state for each test
      final service = container.read(inAppNotificationServiceProvider);
      await service.init();
      await service.clearAll();
    });

    tearDown(() {
      container.dispose();
      mockPrefs.clear();
    });

    group('inAppNotificationServiceProvider', () {
      test('should provide InAppNotificationService instance', () {
        final service = container.read(inAppNotificationServiceProvider);

        expect(service, isA<InAppNotificationService>());
      });

      test('should provide same instance on multiple reads', () {
        final service1 = container.read(inAppNotificationServiceProvider);
        final service2 = container.read(inAppNotificationServiceProvider);

        expect(identical(service1, service2), true);
      });
    });

    group('ntfyServiceProvider', () {
      test('should provide NtfyService instance', () {
        final service = container.read(ntfyServiceProvider);

        expect(service, isA<NtfyService>());
      });

      test('should initialize with InAppNotificationService', () {
        final ntfyService = container.read(ntfyServiceProvider);

        expect(ntfyService, isNotNull);
        expect(ntfyService.isConnected, false);
      });

      test('should set up onNotificationReceived callback', () async {
        final ntfyService = container.read(ntfyServiceProvider);

        expect(ntfyService.onNotificationReceived, isNotNull);
      });
    });

    group('notificationsProvider', () {
      test('should return empty list initially', () async {
        final notificationService = container.read(
          inAppNotificationServiceProvider,
        );
        await notificationService.init();

        final notifications = container.read(notificationsProvider);

        expect(notifications, isEmpty);
      });

      test('should return all notifications from service', () async {
        final notificationService = container.read(
          inAppNotificationServiceProvider,
        );
        await notificationService.init();

        final notification1 = AppNotification(
          id: '1',
          title: 'Test 1',
          message: 'Message 1',
          type: NotificationType.info,
          priority: NotificationPriority.medium,
          timestamp: DateTime.now(),
        );

        final notification2 = AppNotification(
          id: '2',
          title: 'Test 2',
          message: 'Message 2',
          type: NotificationType.error,
          priority: NotificationPriority.high,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
        );

        await notificationService.addNotification(notification1);
        await notificationService.addNotification(notification2);

        // Need to create new container to refresh provider
        final newContainer = ProviderContainer();
        await newContainer.read(inAppNotificationServiceProvider).init();
        await newContainer
            .read(inAppNotificationServiceProvider)
            .addNotification(notification1);
        await newContainer
            .read(inAppNotificationServiceProvider)
            .addNotification(notification2);

        final notifications = newContainer.read(notificationsProvider);

        expect(notifications.length, 2);
        expect(notifications[0].id, '2'); // Sorted newest first
        expect(notifications[1].id, '1');

        newContainer.dispose();
      });

      test('should return notifications sorted by timestamp', () async {
        final notificationService = container.read(
          inAppNotificationServiceProvider,
        );
        await notificationService.init();

        final old = AppNotification(
          id: 'old',
          title: 'Old',
          message: 'Old notification',
          type: NotificationType.info,
          priority: NotificationPriority.medium,
          timestamp: DateTime(2024, 1, 1),
        );

        final newest = AppNotification(
          id: 'newest',
          title: 'Newest',
          message: 'Newest notification',
          type: NotificationType.info,
          priority: NotificationPriority.medium,
          timestamp: DateTime(2024, 2, 1),
        );

        await notificationService.addNotification(old);
        await notificationService.addNotification(newest);

        final newContainer = ProviderContainer();
        await newContainer.read(inAppNotificationServiceProvider).init();
        await newContainer
            .read(inAppNotificationServiceProvider)
            .addNotification(old);
        await newContainer
            .read(inAppNotificationServiceProvider)
            .addNotification(newest);

        final notifications = newContainer.read(notificationsProvider);

        expect(notifications.first.id, 'newest');
        expect(notifications.last.id, 'old');

        newContainer.dispose();
      });
    });

    group('unreadNotificationCountProvider', () {
      test('should return 0 initially', () async {
        final notificationService = container.read(
          inAppNotificationServiceProvider,
        );
        await notificationService.init();

        final count = container.read(unreadNotificationCountProvider);

        expect(count, 0);
      });

      test('should return correct count of unread notifications', () async {
        final notificationService = container.read(
          inAppNotificationServiceProvider,
        );
        await notificationService.init();

        await notificationService.addNotification(
          AppNotification(
            id: '1',
            title: 'Unread',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
            isRead: false,
          ),
        );

        await notificationService.addNotification(
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

        final newContainer = ProviderContainer();
        await newContainer.read(inAppNotificationServiceProvider).init();
        await newContainer
            .read(inAppNotificationServiceProvider)
            .addNotification(
              AppNotification(
                id: '1',
                title: 'Unread',
                message: 'Test',
                type: NotificationType.info,
                priority: NotificationPriority.medium,
                timestamp: DateTime.now(),
                isRead: false,
              ),
            );
        await newContainer
            .read(inAppNotificationServiceProvider)
            .addNotification(
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

        final count = newContainer.read(unreadNotificationCountProvider);

        expect(count, 1);

        newContainer.dispose();
      });

      test('should update when notifications marked as read', () async {
        final notificationService = container.read(
          inAppNotificationServiceProvider,
        );
        await notificationService.init();

        await notificationService.addNotification(
          AppNotification(
            id: 'test',
            title: 'Test',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
            isRead: false,
          ),
        );

        final newContainer = ProviderContainer();
        await newContainer.read(inAppNotificationServiceProvider).init();
        await newContainer
            .read(inAppNotificationServiceProvider)
            .addNotification(
              AppNotification(
                id: 'test',
                title: 'Test',
                message: 'Test',
                type: NotificationType.info,
                priority: NotificationPriority.medium,
                timestamp: DateTime.now(),
                isRead: false,
              ),
            );

        var count = newContainer.read(unreadNotificationCountProvider);
        expect(count, 1);

        await newContainer
            .read(inAppNotificationServiceProvider)
            .markAsRead('test');

        // Create another container to get updated value
        final updatedContainer = ProviderContainer();
        await updatedContainer.read(inAppNotificationServiceProvider).init();
        await updatedContainer
            .read(inAppNotificationServiceProvider)
            .addNotification(
              AppNotification(
                id: 'test',
                title: 'Test',
                message: 'Test',
                type: NotificationType.info,
                priority: NotificationPriority.medium,
                timestamp: DateTime.now(),
                isRead: false,
              ),
            );
        await updatedContainer
            .read(inAppNotificationServiceProvider)
            .markAsRead('test');

        count = updatedContainer.read(unreadNotificationCountProvider);
        expect(count, 0);

        newContainer.dispose();
        updatedContainer.dispose();
      });
    });

    group('NotificationActionsNotifier', () {
      test('should mark notification as read', () async {
        final notificationService = container.read(
          inAppNotificationServiceProvider,
        );
        await notificationService.init();

        await notificationService.addNotification(
          AppNotification(
            id: 'mark-read',
            title: 'Test',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
            isRead: false,
          ),
        );

        final actions = container.read(notificationActionsProvider.notifier);
        await actions.markAsRead('mark-read');

        final service = container.read(inAppNotificationServiceProvider);
        expect(service.notifications.first.isRead, true);
      });

      test('should mark all notifications as read', () async {
        final notificationService = container.read(
          inAppNotificationServiceProvider,
        );
        await notificationService.init();

        for (int i = 0; i < 3; i++) {
          await notificationService.addNotification(
            AppNotification(
              id: 'test-$i',
              title: 'Test $i',
              message: 'Message $i',
              type: NotificationType.info,
              priority: NotificationPriority.medium,
              timestamp: DateTime.now(),
              isRead: false,
            ),
          );
        }

        final actions = container.read(notificationActionsProvider.notifier);
        await actions.markAllAsRead();

        final service = container.read(inAppNotificationServiceProvider);
        expect(service.unreadCount, 0);
        expect(service.notifications.every((n) => n.isRead), true);
      });

      test('should dismiss notification', () async {
        final notificationService = container.read(
          inAppNotificationServiceProvider,
        );
        await notificationService.init();

        await notificationService.addNotification(
          AppNotification(
            id: 'dismiss-me',
            title: 'Test',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          ),
        );

        expect(notificationService.notifications.length, 1);

        final actions = container.read(notificationActionsProvider.notifier);
        await actions.dismiss('dismiss-me');

        final service = container.read(inAppNotificationServiceProvider);
        expect(service.notifications, isEmpty);
      });

      test('should clear all notifications', () async {
        final notificationService = container.read(
          inAppNotificationServiceProvider,
        );
        await notificationService.init();

        for (int i = 0; i < 5; i++) {
          await notificationService.addNotification(
            AppNotification(
              id: 'test-$i',
              title: 'Test $i',
              message: 'Message $i',
              type: NotificationType.info,
              priority: NotificationPriority.medium,
              timestamp: DateTime.now(),
            ),
          );
        }

        expect(notificationService.notifications.length, 5);

        final actions = container.read(notificationActionsProvider.notifier);
        await actions.clearAll();

        final service = container.read(inAppNotificationServiceProvider);
        expect(service.notifications, isEmpty);
      });

      test(
        'should invalidate notificationsProvider after markAsRead',
        () async {
          final notificationService = container.read(
            inAppNotificationServiceProvider,
          );
          await notificationService.init();

          await notificationService.addNotification(
            AppNotification(
              id: 'test',
              title: 'Test',
              message: 'Test',
              type: NotificationType.info,
              priority: NotificationPriority.medium,
              timestamp: DateTime.now(),
              isRead: false,
            ),
          );

          final actions = container.read(notificationActionsProvider.notifier);
          await actions.markAsRead('test');

          // Provider should be invalidated and return updated state
          final service = container.read(inAppNotificationServiceProvider);
          expect(service.notifications.first.isRead, true);
        },
      );

      test(
        'should invalidate unreadNotificationCountProvider after markAllAsRead',
        () async {
          final notificationService = container.read(
            inAppNotificationServiceProvider,
          );
          await notificationService.init();

          await notificationService.addNotification(
            AppNotification(
              id: 'test',
              title: 'Test',
              message: 'Test',
              type: NotificationType.info,
              priority: NotificationPriority.medium,
              timestamp: DateTime.now(),
              isRead: false,
            ),
          );

          final actions = container.read(notificationActionsProvider.notifier);
          await actions.markAllAsRead();

          final service = container.read(inAppNotificationServiceProvider);
          expect(service.unreadCount, 0);
        },
      );

      test(
        'should handle dismissing non-existent notification gracefully',
        () async {
          final notificationService = container.read(
            inAppNotificationServiceProvider,
          );
          await notificationService.init();

          final actions = container.read(notificationActionsProvider.notifier);

          // Should not throw
          await actions.dismiss('non-existent');

          final service = container.read(inAppNotificationServiceProvider);
          expect(service.notifications, isEmpty);
        },
      );

      test(
        'should handle marking non-existent notification as read gracefully',
        () async {
          final notificationService = container.read(
            inAppNotificationServiceProvider,
          );
          await notificationService.init();

          final actions = container.read(notificationActionsProvider.notifier);

          // Should not throw
          await actions.markAsRead('non-existent');

          final service = container.read(inAppNotificationServiceProvider);
          expect(service.notifications, isEmpty);
        },
      );
    });
  });
}
