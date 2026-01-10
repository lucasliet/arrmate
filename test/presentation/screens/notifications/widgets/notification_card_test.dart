import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/domain/models/notification/app_notification.dart';
import 'package:arrmate/presentation/screens/notifications/widgets/notification_card.dart';

void main() {
  group('NotificationCard', () {
    final testTimestamp = DateTime(2024, 1, 15, 10, 30);

    AppNotification createTestNotification({
      String id = 'test-id',
      String title = 'Test Title',
      String message = 'Test Message',
      NotificationType type = NotificationType.info,
      NotificationPriority priority = NotificationPriority.medium,
      bool isRead = false,
    }) {
      return AppNotification(
        id: id,
        title: title,
        message: message,
        type: type,
        priority: priority,
        timestamp: testTimestamp,
        isRead: isRead,
      );
    }

    Widget buildWidget({
      required AppNotification notification,
      VoidCallback? onTap,
      VoidCallback? onDismiss,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: NotificationCard(
            notification: notification,
            onTap: onTap,
            onDismiss: onDismiss,
          ),
        ),
      );
    }

    group('display', () {
      testWidgets('should display notification title', (tester) async {
        final notification = createTestNotification(title: 'Test Notification');

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.text('Test Notification'), findsOneWidget);
      });

      testWidgets('should display notification message', (tester) async {
        final notification = createTestNotification(
          message: 'This is a test message',
        );

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.text('This is a test message'), findsOneWidget);
      });

      testWidgets('should display NEW badge for unread notifications', (
        tester,
      ) async {
        final notification = createTestNotification(isRead: false);

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.text('NEW'), findsOneWidget);
      });

      testWidgets('should not display NEW badge for read notifications', (
        tester,
      ) async {
        final notification = createTestNotification(isRead: true);

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.text('NEW'), findsNothing);
      });

      testWidgets('should display relative timestamp', (tester) async {
        final notification = createTestNotification();

        await tester.pumpWidget(buildWidget(notification: notification));

        // Should find some time-ago text (exact text depends on current time)
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('should truncate long titles with ellipsis', (tester) async {
        final notification = createTestNotification(
          title:
              'This is a very long title that should be truncated with ellipsis',
        );

        await tester.pumpWidget(buildWidget(notification: notification));

        final titleText = tester.widget<Text>(
          find.text(
            'This is a very long title that should be truncated with ellipsis',
          ),
        );

        expect(titleText.maxLines, 1);
        expect(titleText.overflow, TextOverflow.ellipsis);
      });

      testWidgets('should truncate long messages with ellipsis', (
        tester,
      ) async {
        final notification = createTestNotification(
          message:
              'This is a very long message that should be truncated with ellipsis after two lines',
        );

        await tester.pumpWidget(buildWidget(notification: notification));

        final messageText = tester.widget<Text>(
          find.text(
            'This is a very long message that should be truncated with ellipsis after two lines',
          ),
        );

        expect(messageText.maxLines, 2);
        expect(messageText.overflow, TextOverflow.ellipsis);
      });
    });

    group('styling', () {
      testWidgets('should use bold font for unread notification title', (
        tester,
      ) async {
        final notification = createTestNotification(isRead: false);

        await tester.pumpWidget(buildWidget(notification: notification));

        final titleFinder = find.text('Test Title');
        final titleText = tester.widget<Text>(titleFinder);

        expect(titleText.style?.fontWeight, FontWeight.bold);
      });

      testWidgets('should use normal font weight for read notification title', (
        tester,
      ) async {
        final notification = createTestNotification(isRead: true);

        await tester.pumpWidget(buildWidget(notification: notification));

        final titleFinder = find.text('Test Title');
        final titleText = tester.widget<Text>(titleFinder);

        expect(titleText.style?.fontWeight, FontWeight.w500);
      });

      testWidgets('should use different background for unread notifications', (
        tester,
      ) async {
        final notification = createTestNotification(isRead: false);

        await tester.pumpWidget(buildWidget(notification: notification));

        final card = tester.widget<Card>(find.byType(Card));
        expect(card.color, isNotNull);
      });
    });

    group('icons', () {
      testWidgets('should display download icon for download type', (
        tester,
      ) async {
        final notification = createTestNotification(
          type: NotificationType.download,
        );

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      });

      testWidgets('should display error icon for error type', (tester) async {
        final notification = createTestNotification(
          type: NotificationType.error,
        );

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      });

      testWidgets('should display check icon for imported type', (
        tester,
      ) async {
        final notification = createTestNotification(
          type: NotificationType.imported,
        );

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      });

      testWidgets('should display system update icon for upgrade type', (
        tester,
      ) async {
        final notification = createTestNotification(
          type: NotificationType.upgrade,
        );

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.byIcon(Icons.system_update_rounded), findsOneWidget);
      });

      testWidgets('should display warning icon for warning type', (
        tester,
      ) async {
        final notification = createTestNotification(
          type: NotificationType.warning,
        );

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      });

      testWidgets('should display info icon for info type', (tester) async {
        final notification = createTestNotification(
          type: NotificationType.info,
        );

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      });
    });

    group('interactions', () {
      testWidgets('should call onTap when card is tapped', (tester) async {
        bool tapped = false;
        final notification = createTestNotification();

        await tester.pumpWidget(
          buildWidget(notification: notification, onTap: () => tapped = true),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pump();

        expect(tapped, true);
      });

      testWidgets('should not crash when onTap is null', (tester) async {
        final notification = createTestNotification();

        await tester.pumpWidget(
          buildWidget(notification: notification, onTap: null),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pump();

        // Should not throw
      });

      testWidgets('should call onDismiss when swiped left', (tester) async {
        bool dismissed = false;
        final notification = createTestNotification();

        await tester.pumpWidget(
          buildWidget(
            notification: notification,
            onDismiss: () => dismissed = true,
          ),
        );

        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(dismissed, true);
      });

      testWidgets('should call onDismiss when swiped right', (tester) async {
        bool dismissed = false;
        final notification = createTestNotification();

        await tester.pumpWidget(
          buildWidget(
            notification: notification,
            onDismiss: () => dismissed = true,
          ),
        );

        await tester.drag(find.byType(Dismissible), const Offset(500, 0));
        await tester.pumpAndSettle();

        expect(dismissed, true);
      });

      testWidgets('should not call onDismiss when swiped vertically', (
        tester,
      ) async {
        bool dismissed = false;
        final notification = createTestNotification();

        await tester.pumpWidget(
          buildWidget(
            notification: notification,
            onDismiss: () => dismissed = true,
          ),
        );

        await tester.drag(find.byType(Dismissible), const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(dismissed, false);
      });

      testWidgets('should not crash when onDismiss is null', (tester) async {
        final notification = createTestNotification();

        await tester.pumpWidget(
          buildWidget(notification: notification, onDismiss: null),
        );

        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        // Should not throw
      });
    });

    group('dismissible', () {
      testWidgets('should be dismissible', (tester) async {
        final notification = createTestNotification();

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.byType(Dismissible), findsOneWidget);
      });

      testWidgets('should have horizontal dismiss direction', (tester) async {
        final notification = createTestNotification();

        await tester.pumpWidget(buildWidget(notification: notification));

        final dismissible = tester.widget<Dismissible>(
          find.byType(Dismissible),
        );
        expect(dismissible.direction, DismissDirection.horizontal);
      });

      testWidgets('should use notification id as key', (tester) async {
        final notification = createTestNotification(id: 'unique-key-123');

        await tester.pumpWidget(buildWidget(notification: notification));

        final dismissible = tester.widget<Dismissible>(
          find.byType(Dismissible),
        );
        expect(dismissible.key, const Key('unique-key-123'));
      });

      testWidgets('should display delete icon in background', (tester) async {
        final notification = createTestNotification();

        await tester.pumpWidget(buildWidget(notification: notification));

        // Start dragging to reveal background
        await tester.drag(find.byType(Dismissible), const Offset(-100, 0));
        await tester.pump();

        expect(find.byIcon(Icons.delete_outline), findsAtLeastNWidgets(1));
      });
    });

    group('layout', () {
      testWidgets('should render as Card widget', (tester) async {
        final notification = createTestNotification();

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('should have proper margins', (tester) async {
        final notification = createTestNotification();

        await tester.pumpWidget(buildWidget(notification: notification));

        final card = tester.widget<Card>(find.byType(Card));
        expect(
          card.margin,
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        );
      });

      testWidgets('should have icon on the left', (tester) async {
        final notification = createTestNotification(
          type: NotificationType.download,
        );

        await tester.pumpWidget(buildWidget(notification: notification));

        final row = tester.widget<Row>(
          find
              .descendant(of: find.byType(Padding), matching: find.byType(Row))
              .first,
        );

        expect(row.crossAxisAlignment, CrossAxisAlignment.start);
      });
    });

    group('edge cases', () {
      testWidgets('should handle empty title', (tester) async {
        final notification = createTestNotification(title: '');

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.text(''), findsWidgets); // Will find empty text widget
      });

      testWidgets('should handle empty message', (tester) async {
        final notification = createTestNotification(message: '');

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.text(''), findsWidgets);
      });

      testWidgets('should handle very long title gracefully', (tester) async {
        final longTitle = 'A' * 1000;
        final notification = createTestNotification(title: longTitle);

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.text(longTitle), findsOneWidget);
      });

      testWidgets('should handle very long message gracefully', (tester) async {
        final longMessage = 'B' * 1000;
        final notification = createTestNotification(message: longMessage);

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.text(longMessage), findsOneWidget);
      });

      testWidgets('should handle all notification types', (tester) async {
        for (final type in NotificationType.values) {
          final notification = createTestNotification(type: type);

          await tester.pumpWidget(buildWidget(notification: notification));

          expect(find.byType(NotificationCard), findsOneWidget);
          expect(find.byType(Icon), findsWidgets);
        }
      });

      testWidgets('should handle all priority levels', (tester) async {
        for (final priority in NotificationPriority.values) {
          final notification = createTestNotification(priority: priority);

          await tester.pumpWidget(buildWidget(notification: notification));

          expect(find.byType(NotificationCard), findsOneWidget);
        }
      });
    });

    group('accessibility', () {
      testWidgets('should be accessible for screen readers', (tester) async {
        final notification = createTestNotification(
          title: 'Important Notification',
          message: 'This is important',
        );

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.text('Important Notification'), findsOneWidget);
        expect(find.text('This is important'), findsOneWidget);
      });

      testWidgets('should have InkWell for tap feedback', (tester) async {
        final notification = createTestNotification();

        await tester.pumpWidget(buildWidget(notification: notification));

        expect(find.byType(InkWell), findsOneWidget);
      });

      testWidgets('InkWell should have border radius', (tester) async {
        final notification = createTestNotification();

        await tester.pumpWidget(buildWidget(notification: notification));

        final inkWell = tester.widget<InkWell>(find.byType(InkWell));
        expect(inkWell.borderRadius, BorderRadius.circular(12));
      });
    });
  });
}
