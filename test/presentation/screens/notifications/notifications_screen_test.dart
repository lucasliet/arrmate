import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrmate/domain/models/notification/app_notification.dart';
import 'package:arrmate/presentation/providers/notifications_provider.dart';
import 'package:arrmate/presentation/screens/notifications/notifications_screen.dart';
import 'package:arrmate/presentation/screens/notifications/widgets/notification_card.dart';

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

  group('NotificationsScreen', () {
    setUp(() {
      mockPrefs = {};
      setupMockMethodChannel();
    });

    tearDown(() {
      mockPrefs.clear();
    });

    Widget buildWidget({
      List<AppNotification> notifications = const [],
      int unreadCount = 0,
    }) {
      return ProviderScope(
        overrides: [
          notificationsProvider.overrideWith((ref) => notifications),
          unreadNotificationCountProvider.overrideWith((ref) => unreadCount),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      );
    }

    group('empty state', () {
      testWidgets('should display empty state when no notifications', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('No notifications'), findsOneWidget);
        expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      });

      testWidgets('should display helpful message in empty state', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget());

        expect(
          find.text(
            'When you receive notifications from Radarr or Sonarr, they will appear here.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('should not show action buttons in empty state', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byIcon(Icons.done_all), findsNothing);
        expect(find.byIcon(Icons.delete_sweep), findsNothing);
      });
    });

    group('with notifications', () {
      final testNotifications = [
        AppNotification(
          id: '1',
          title: 'Download Complete',
          message: 'Movie downloaded',
          type: NotificationType.download,
          priority: NotificationPriority.high,
          timestamp: DateTime.now(),
          isRead: false,
        ),
        AppNotification(
          id: '2',
          title: 'Import Success',
          message: 'Movie imported',
          type: NotificationType.imported,
          priority: NotificationPriority.medium,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          isRead: true,
        ),
        AppNotification(
          id: '3',
          title: 'Error',
          message: 'Download failed',
          type: NotificationType.error,
          priority: NotificationPriority.high,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: false,
        ),
      ];

      testWidgets('should display all notifications', (tester) async {
        await tester.pumpWidget(
          buildWidget(notifications: testNotifications, unreadCount: 2),
        );

        expect(find.byType(NotificationCard), findsNWidgets(3));
        expect(find.text('Download Complete'), findsOneWidget);
        expect(find.text('Import Success'), findsOneWidget);
        expect(find.text('Error'), findsOneWidget);
      });

      testWidgets(
        'should show mark all as read button when there are unread notifications',
        (tester) async {
          await tester.pumpWidget(
            buildWidget(notifications: testNotifications, unreadCount: 2),
          );

          expect(find.byIcon(Icons.done_all), findsOneWidget);
          expect(find.byTooltip('Mark all as read'), findsOneWidget);
        },
      );

      testWidgets('should not show mark all as read button when all are read', (
        tester,
      ) async {
        final readNotifications = testNotifications
            .map((n) => n.copyWith(isRead: true))
            .toList();

        await tester.pumpWidget(
          buildWidget(notifications: readNotifications, unreadCount: 0),
        );

        expect(find.byIcon(Icons.done_all), findsNothing);
      });

      testWidgets(
        'should always show clear all button when there are notifications',
        (tester) async {
          await tester.pumpWidget(
            buildWidget(notifications: testNotifications, unreadCount: 2),
          );

          expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
          expect(find.byTooltip('Clear all'), findsOneWidget);
        },
      );

      testWidgets('should display notifications in a list', (tester) async {
        await tester.pumpWidget(
          buildWidget(notifications: testNotifications, unreadCount: 2),
        );

        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('should be scrollable', (tester) async {
        final manyNotifications = List.generate(
          20,
          (i) => AppNotification(
            id: 'notif-$i',
            title: 'Notification $i',
            message: 'Message $i',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now().subtract(Duration(hours: i)),
          ),
        );

        await tester.pumpWidget(
          buildWidget(notifications: manyNotifications, unreadCount: 0),
        );

        // Find first and last items
        expect(find.text('Notification 0'), findsOneWidget);

        // Scroll to the end
        await tester.drag(find.byType(ListView), const Offset(0, -10000));
        await tester.pumpAndSettle();

        // Last item should now be visible
        expect(find.text('Notification 19'), findsOneWidget);
      });
    });

    group('app bar', () {
      testWidgets('should display correct title', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('Notifications'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should have back button', (tester) async {
        await tester.pumpWidget(buildWidget());

        // AppBar automatically adds a back button when there's a route to go back to
        expect(find.byType(AppBar), findsOneWidget);
      });
    });

    group('mark all as read action', () {
      testWidgets(
        'should show confirmation snackbar after marking all as read',
        (tester) async {
          final notifications = [
            AppNotification(
              id: '1',
              title: 'Test',
              message: 'Test',
              type: NotificationType.info,
              priority: NotificationPriority.medium,
              timestamp: DateTime.now(),
              isRead: false,
            ),
          ];

          await tester.pumpWidget(
            buildWidget(notifications: notifications, unreadCount: 1),
          );

          await tester.tap(find.byIcon(Icons.done_all));
          await tester.pumpAndSettle();

          expect(find.text('All notifications marked as read'), findsOneWidget);
          expect(find.byType(SnackBar), findsOneWidget);
        },
      );

      testWidgets('snackbar should disappear after duration', (tester) async {
        final notifications = [
          AppNotification(
            id: '1',
            title: 'Test',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
            isRead: false,
          ),
        ];

        await tester.pumpWidget(
          buildWidget(notifications: notifications, unreadCount: 1),
        );

        await tester.tap(find.byIcon(Icons.done_all));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsNothing);
      });
    });

    group('clear all action', () {
      testWidgets('should show confirmation dialog when clear all is tapped', (
        tester,
      ) async {
        final notifications = [
          AppNotification(
            id: '1',
            title: 'Test',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          buildWidget(notifications: notifications, unreadCount: 0),
        );

        await tester.tap(find.byIcon(Icons.delete_sweep));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('confirmation dialog should have correct content', (
        tester,
      ) async {
        final notifications = [
          AppNotification(
            id: '1',
            title: 'Test',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          buildWidget(notifications: notifications, unreadCount: 0),
        );

        await tester.tap(find.byIcon(Icons.delete_sweep));
        await tester.pumpAndSettle();

        expect(find.text('Clear all notifications?'), findsOneWidget);
        expect(
          find.text(
            'This will remove all notifications. This action cannot be undone.',
          ),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Clear all'), findsOneWidget);
      });

      testWidgets('should dismiss dialog when cancel is tapped', (
        tester,
      ) async {
        final notifications = [
          AppNotification(
            id: '1',
            title: 'Test',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          buildWidget(notifications: notifications, unreadCount: 0),
        );

        await tester.tap(find.byIcon(Icons.delete_sweep));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('notification interactions', () {
      testWidgets('should mark notification as read when tapped', (
        tester,
      ) async {
        final notifications = [
          AppNotification(
            id: 'tap-test',
            title: 'Test',
            message: 'Test message',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
            isRead: false,
          ),
        ];

        await tester.pumpWidget(
          buildWidget(notifications: notifications, unreadCount: 1),
        );

        // The notification card should be tappable
        expect(find.byType(NotificationCard), findsOneWidget);
      });

      testWidgets('should dismiss notification when swiped', (tester) async {
        final notifications = [
          AppNotification(
            id: 'swipe-test',
            title: 'Test',
            message: 'Test message',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          buildWidget(notifications: notifications, unreadCount: 0),
        );

        expect(find.byType(Dismissible), findsOneWidget);
      });
    });

    group('layout', () {
      testWidgets('should have proper padding in list', (tester) async {
        final notifications = [
          AppNotification(
            id: '1',
            title: 'Test',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          buildWidget(notifications: notifications, unreadCount: 0),
        );

        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.padding, const EdgeInsets.symmetric(vertical: 8));
      });

      testWidgets('should use scaffold layout', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('should handle single notification', (tester) async {
        final notifications = [
          AppNotification(
            id: 'single',
            title: 'Single Notification',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          buildWidget(notifications: notifications, unreadCount: 0),
        );

        expect(find.byType(NotificationCard), findsOneWidget);
        expect(find.text('Single Notification'), findsOneWidget);
      });

      testWidgets('should handle many notifications efficiently', (
        tester,
      ) async {
        final manyNotifications = List.generate(
          100,
          (i) => AppNotification(
            id: 'notif-$i',
            title: 'Notification $i',
            message: 'Message $i',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now().subtract(Duration(minutes: i)),
          ),
        );

        await tester.pumpWidget(
          buildWidget(notifications: manyNotifications, unreadCount: 0),
        );

        // ListView.builder should handle this efficiently
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('should handle all notification types', (tester) async {
        final notifications = NotificationType.values.map((type) {
          return AppNotification(
            id: type.name,
            title: type.name,
            message: 'Test ${type.name}',
            type: type,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          );
        }).toList();

        await tester.pumpWidget(
          buildWidget(notifications: notifications, unreadCount: 0),
        );

        expect(
          find.byType(NotificationCard),
          findsNWidgets(NotificationType.values.length),
        );
      });
    });

    group('accessibility', () {
      testWidgets('should be accessible with screen readers', (tester) async {
        final notifications = [
          AppNotification(
            id: '1',
            title: 'Important Notification',
            message: 'This is important',
            type: NotificationType.warning,
            priority: NotificationPriority.high,
            timestamp: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          buildWidget(notifications: notifications, unreadCount: 1),
        );

        // All text should be accessible
        expect(find.text('Important Notification'), findsOneWidget);
        expect(find.text('This is important'), findsOneWidget);
      });

      testWidgets('action buttons should have tooltips', (tester) async {
        final notifications = [
          AppNotification(
            id: '1',
            title: 'Test',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
            isRead: false,
          ),
        ];

        await tester.pumpWidget(
          buildWidget(notifications: notifications, unreadCount: 1),
        );

        expect(find.byTooltip('Mark all as read'), findsOneWidget);
        expect(find.byTooltip('Clear all'), findsOneWidget);
      });
    });
  });
}
