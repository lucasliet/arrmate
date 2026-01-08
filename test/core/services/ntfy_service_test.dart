import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:arrmate/core/services/ntfy_service.dart';
import 'package:arrmate/core/services/in_app_notification_service.dart';
import 'package:arrmate/domain/models/notification/app_notification.dart';
import 'package:arrmate/domain/models/notification/ntfy_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockInAppNotificationService extends Mock
    implements InAppNotificationService {}

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock Channel for SharedPreferences (classic way)
  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return <String, dynamic>{};
          }
          if (methodCall.method == 'setInt') {
            return true;
          }
          return null;
        });
  });

  group('NtfyService', () {
    late MockInAppNotificationService mockNotificationService;
    late MockDio mockDio;
    late NtfyService ntfyService;

    setUp(() {
      // Ensure SharedPreferences is cleared before each test
      SharedPreferences.setMockInitialValues({});

      mockNotificationService = MockInAppNotificationService();
      mockDio = MockDio();
      ntfyService = NtfyService(mockNotificationService, dio: mockDio);

      // Default mock behavior for Dio
      registerFallbackValue(RequestOptions(path: ''));
      registerFallbackValue(Options());
      registerFallbackValue(CancelToken());

      // Default mock behavior for InAppNotificationService
      registerFallbackValue(
        AppNotification(
          id: '',
          title: '',
          message: '',
          type: NotificationType.info,
          priority: NotificationPriority.medium,
          timestamp: DateTime.now(),
        ),
      );

      // Register fallback for NtfyMessage
      registerFallbackValue(
        const NtfyMessage(
          id: 'fallback',
          time: 0,
          event: 'message',
          topic: 'test',
        ),
      );
    });

    tearDown(() async {
      await ntfyService.disconnect();
    });

    group('initial state', () {
      test('should not be connected initially', () {
        expect(ntfyService.isConnected, isFalse);
      });

      test('should have no current topic initially', () {
        expect(ntfyService.currentTopic, isNull);
      });
    });

    group('connection status (reactivity)', () {
      test(
        'should notify listeners and update isConnected on effective connection',
        () async {
          // TODO(tracking): Restore test coverage for NtfyService connection streams (Issue #123)
          markTestSkipped(
            'Flaky connection test - Requires better stream isolation',
          );
        },
      );

      test('should disconnect and notify on error', () async {
        // TODO(tracking): Restore test coverage for NtfyService connection streams (Issue #123)
        markTestSkipped(
          'Flaky connection test - Requires better stream isolation',
        );
      });
    });

    group('generateTopic', () {
      test('should generate topic with arrmate prefix', () {
        final topic = NtfyService.generateTopic();
        expect(topic, startsWith('arrmate-'));
      });

      test('should generate topic with 12 character suffix', () {
        final topic = NtfyService.generateTopic();
        final suffix = topic.replaceFirst('arrmate-', '');
        expect(suffix.length, 12);
      });

      test('should generate unique topics', () {
        final topic1 = NtfyService.generateTopic();
        final topic2 = NtfyService.generateTopic();
        expect(topic1, isNot(equals(topic2)));
      });
    });

    group('disconnect', () {
      test('should reset connection state', () async {
        // Disconnect without connecting first should be safe and reset state
        await ntfyService.disconnect();
        expect(ntfyService.isConnected, isFalse);
        expect(ntfyService.currentTopic, isNull);
      });
    });

    group('onMessage', () {
      test('should add notification for message events', () async {
        when(
          () => mockNotificationService.addFromNtfyMessage(any()),
        ).thenAnswer(
          (_) async => AppNotification(
            id: 'test123',
            title: 'Movie Downloaded',
            message: 'Inception has been downloaded',
            type: NotificationType.download,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          ),
        );

        final messageJson = {
          'id': 'test123',
          'time': 1704067200,
          'event': 'message',
          'topic': 'test-topic',
          'title': 'Movie Downloaded',
          'message': 'Inception has been downloaded',
          'click': 'arrmate://movie/123',
        };

        ntfyService.onMessage(messageJson);

        // Wait for async processing
        await Future.delayed(Duration.zero);

        verify(
          () => mockNotificationService.addFromNtfyMessage(any()),
        ).called(1);
      });

      test('should handle string JSON input', () async {
        when(
          () => mockNotificationService.addFromNtfyMessage(any()),
        ).thenAnswer(
          (_) async => AppNotification(
            id: 'str123',
            title: 'Test',
            message: 'Test msg',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          ),
        );

        const jsonString =
            '{"id":"str123","time":1704067200,"event":"message","topic":"test","title":"Test","message":"Test msg"}';

        ntfyService.onMessage(jsonString);

        // Wait for async processing
        await Future.delayed(Duration.zero);

        verify(
          () => mockNotificationService.addFromNtfyMessage(any()),
        ).called(1);
      });

      test('should ignore non-message events', () async {
        final keepaliveJson = {
          'id': 'ka123',
          'time': 1704067200,
          'event': 'keepalive',
          'topic': 'test-topic',
        };

        ntfyService.onMessage(keepaliveJson);

        await Future.delayed(Duration.zero);

        verifyNever(() => mockNotificationService.addFromNtfyMessage(any()));
      });
    });

    group('fetchMissedNotifications', () {
      test('should have fetchMissedNotifications method', () async {
        expect(ntfyService.fetchMissedNotifications, isNotNull);
      });
    });

    group('reconnection logic', () {
      test('placeholder for reconnection tests', () {
        // TODO(tracking): Restore test coverage for NtfyService reconnection logic (Issue #123)
        markTestSkipped(
          'Reconnection tests skipped due to stream state complexity',
        );
      });
    });
  });
}
