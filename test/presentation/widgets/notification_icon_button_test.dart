import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrmate/presentation/providers/notifications_provider.dart';
import 'package:arrmate/presentation/widgets/notification_icon_button.dart';

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

  group('NotificationIconButton', () {
    setUp(() {
      mockPrefs = {};
      setupMockMethodChannel();
    });

    tearDown(() {
      mockPrefs.clear();
    });

    Widget buildWidget({int unreadCount = 0}) {
      return ProviderScope(
        overrides: [
          unreadNotificationCountProvider.overrideWith((ref) => unreadCount),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                  appBar: AppBar(actions: const [NotificationIconButton()]),
                  body: const Center(child: Text('Home')),
                ),
              ),
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Notifications Screen')),
                ),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('should display notification bell icon', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('should display tooltip', (tester) async {
      await tester.pumpWidget(buildWidget());

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));

      expect(iconButton.tooltip, 'Notifications');
    });

    testWidgets('should not show badge when unread count is 0', (tester) async {
      await tester.pumpWidget(buildWidget(unreadCount: 0));

      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, false);
    });

    testWidgets('should show badge when unread count is greater than 0', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(unreadCount: 5));

      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, true);
    });

    testWidgets('should display correct unread count in badge', (tester) async {
      await tester.pumpWidget(buildWidget(unreadCount: 5));

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should display "99+" when unread count exceeds 99', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(unreadCount: 150));

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('should display exact count for 99 unread notifications', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(unreadCount: 99));

      expect(find.text('99'), findsOneWidget);
    });

    testWidgets(
      'should display exact count for 100 unread notifications as 99+',
      (tester) async {
        await tester.pumpWidget(buildWidget(unreadCount: 100));

        expect(find.text('99+'), findsOneWidget);
      },
    );

    testWidgets('should navigate to notifications screen when tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.text('Notifications Screen'), findsOneWidget);
    });

    testWidgets('badge visibility should reflect initial unread count of 5', (
      tester,
    ) async {
      // Given
      await tester.pumpWidget(buildWidget(unreadCount: 5));

      // Then
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, true);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('badge visibility should reflect initial unread count of 0', (
      tester,
    ) async {
      // Given
      await tester.pumpWidget(buildWidget(unreadCount: 0));

      // Then
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, false);
    });

    testWidgets('should render badge with small font size', (tester) async {
      await tester.pumpWidget(buildWidget(unreadCount: 5));

      final badge = tester.widget<Badge>(find.byType(Badge));
      final label = badge.label as Text;
      final style = label.style;

      expect(style?.fontSize, 10);
    });

    testWidgets('badge should be a child of icon button', (tester) async {
      await tester.pumpWidget(buildWidget(unreadCount: 5));

      final iconButton = find.byType(IconButton);
      final badge = find.byType(Badge);

      expect(find.descendant(of: iconButton, matching: badge), findsOneWidget);
    });

    testWidgets('should handle single unread notification', (tester) async {
      await tester.pumpWidget(buildWidget(unreadCount: 1));

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('should handle edge case of exactly 100 notifications', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(unreadCount: 100));

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('should handle very large unread counts', (tester) async {
      await tester.pumpWidget(buildWidget(unreadCount: 9999));

      expect(find.text('99+'), findsOneWidget);
    });
  });
}
