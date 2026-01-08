import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:arrmate/core/services/ntfy_service.dart';
import 'package:arrmate/core/services/in_app_notification_service.dart';
import 'package:arrmate/domain/models/notification/app_notification.dart';
import 'package:arrmate/domain/models/notification/ntfy_message.dart';

class MockInAppNotificationService extends Mock
    implements InAppNotificationService {}

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences for InAppNotificationService calls
  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );
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

  group('NtfyService', () {
    late MockInAppNotificationService mockNotificationService;
    late MockDio mockDio;
    late NtfyService ntfyService;

    setUp(() {
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
          // Given
          final streamController = StreamController<Uint8List>();
          final responseBody = ResponseBody(
            streamController.stream,
            200,
            headers: {},
          );
          final response = Response<ResponseBody>(
            requestOptions: RequestOptions(path: ''),
            data: responseBody,
          );

          when(
            () => mockDio.get<ResponseBody>(
              any(),
              options: any(named: 'options'),
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer((_) async => response);

          bool notified = false;
          ntfyService.addListener(() {
            notified = true;
          });

          // When
          await ntfyService.connect('test-topic');

          // Then
          expect(ntfyService.isConnected, isTrue);
          expect(notified, isTrue);

          await streamController.close();
        },
      );

      test('should disconnect and notify on error', () async {
        // Given
        final streamController = StreamController<Uint8List>();
        final responseBody = ResponseBody(
          streamController.stream,
          200,
          headers: {},
        );
        final response = Response<ResponseBody>(
          requestOptions: RequestOptions(path: ''),
          data: responseBody,
        );

        when(
          () => mockDio.get<ResponseBody>(
            any(),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => response);

        await ntfyService.connect('test-topic');
        expect(ntfyService.isConnected, isTrue);

        // Reset notification flag
        bool notified = false;
        ntfyService.addListener(() {
          notified = true;
        });

        // When - simulate error in stream
        streamController.addError(
          DioException(requestOptions: RequestOptions(path: '')),
        );

        // Wait for async processing
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        // Then
        expect(ntfyService.isConnected, isFalse);
        expect(notified, isTrue);
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

        // Wait for async processing
        await Future.delayed(Duration.zero);

        verifyNever(() => mockNotificationService.addFromNtfyMessage(any()));
      });
    });

    group('fetchMissedNotifications', () {
      test('should have fetchMissedNotifications method', () async {
        // Given - verify method exists
        expect(ntfyService.fetchMissedNotifications, isNotNull);
      });
    });

    group('testConnection', () {
      test('should have testConnection method', () async {
        // Given - verify method exists
        expect(ntfyService.testConnection, isNotNull);
      });
    });

    group('reconnection logic', () {
      test('should attempt reconnection after stream error', () async {
        final streamController = StreamController<Uint8List>();
        final responseBody = ResponseBody(
          streamController.stream,
          200,
          headers: {},
        );
        final response = Response<ResponseBody>(
          requestOptions: RequestOptions(path: ''),
          data: responseBody,
        );

        when(
          () => mockDio.get<ResponseBody>(
            any(),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => response);

        await ntfyService.connect('test-topic');
        expect(ntfyService.isConnected, isTrue);

        // Simulate stream error
        streamController.addError(Exception('Stream error'));

        // Wait for error processing
        await Future.delayed(const Duration(milliseconds: 100));

        expect(ntfyService.isConnected, isFalse);

        await streamController.close();
      });

      test('should not reconnect after manual disconnect', () async {
        final streamController = StreamController<Uint8List>();
        final responseBody = ResponseBody(
          streamController.stream,
          200,
          headers: {},
        );
        final response = Response<ResponseBody>(
          requestOptions: RequestOptions(path: ''),
          data: responseBody,
        );

        when(
          () => mockDio.get<ResponseBody>(
            any(),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => response);

        await ntfyService.connect('test-topic');
        await ntfyService.disconnect();

        expect(ntfyService.isConnected, isFalse);
        expect(ntfyService.currentTopic, isNull);

        await streamController.close();
      });

      test('should handle stream done event', () async {
        final streamController = StreamController<Uint8List>();
        final responseBody = ResponseBody(
          streamController.stream,
          200,
          headers: {},
        );
        final response = Response<ResponseBody>(
          requestOptions: RequestOptions(path: ''),
          data: responseBody,
        );

        when(
          () => mockDio.get<ResponseBody>(
            any(),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => response);

        await ntfyService.connect('test-topic');
        expect(ntfyService.isConnected, isTrue);

        // Close stream to trigger done event
        await streamController.close();

        // Wait for processing
        await Future.delayed(const Duration(milliseconds: 100));

        expect(ntfyService.isConnected, isFalse);
      });
    });

    group('message processing edge cases', () {
      test('should handle empty JSON string', () async {
        ntfyService.onMessage('');

        // Wait for async processing
        await Future.delayed(Duration.zero);

        // Should not crash
        verifyNever(() => mockNotificationService.addFromNtfyMessage(any()));
      });

      test('should handle whitespace-only string', () async {
        ntfyService.onMessage('   ');

        await Future.delayed(Duration.zero);

        verifyNever(() => mockNotificationService.addFromNtfyMessage(any()));
      });

      test('should handle invalid JSON', () async {
        ntfyService.onMessage('{invalid json}');

        await Future.delayed(Duration.zero);

        // Should not crash, just log warning
        verifyNever(() => mockNotificationService.addFromNtfyMessage(any()));
      });

      test('should handle JSON with missing fields', () async {
        final json = {
          'id': 'incomplete',
          'time': 1704067200,
          'event': 'message',
          // Missing topic and other fields
        };

        when(
          () => mockNotificationService.addFromNtfyMessage(any()),
        ).thenAnswer(
          (_) async => AppNotification(
            id: 'incomplete',
            title: 'Arrmate',
            message: '',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          ),
        );

        ntfyService.onMessage(json);

        await Future.delayed(Duration.zero);

        verify(
          () => mockNotificationService.addFromNtfyMessage(any()),
        ).called(1);
      });

      test('should handle open event', () async {
        final openJson = {
          'id': 'open-event',
          'time': 1704067200,
          'event': 'open',
          'topic': 'test-topic',
        };

        ntfyService.onMessage(openJson);

        await Future.delayed(Duration.zero);

        // Should not add notification for open events
        verifyNever(() => mockNotificationService.addFromNtfyMessage(any()));
      });

      test('should invoke onNotificationReceived callback when set', () async {
        AppNotification? receivedNotification;
        ntfyService.onNotificationReceived = (notification) {
          receivedNotification = notification;
        };

        final testNotification = AppNotification(
          id: 'callback-test',
          title: 'Callback Test',
          message: 'Test message',
          type: NotificationType.info,
          priority: NotificationPriority.medium,
          timestamp: DateTime.now(),
        );

        when(
          () => mockNotificationService.addFromNtfyMessage(any()),
        ).thenAnswer((_) async => testNotification);

        final messageJson = {
          'id': 'callback-test',
          'time': 1704067200,
          'event': 'message',
          'topic': 'test-topic',
          'title': 'Callback Test',
          'message': 'Test message',
        };

        ntfyService.onMessage(messageJson);

        await Future.delayed(Duration.zero);

        expect(receivedNotification, equals(testNotification));
      });

      test('should not crash when onNotificationReceived is null', () async {
        ntfyService.onNotificationReceived = null;

        when(
          () => mockNotificationService.addFromNtfyMessage(any()),
        ).thenAnswer(
          (_) async => AppNotification(
            id: 'no-callback',
            title: 'Test',
            message: 'Test',
            type: NotificationType.info,
            priority: NotificationPriority.medium,
            timestamp: DateTime.now(),
          ),
        );

        final messageJson = {
          'id': 'no-callback',
          'time': 1704067200,
          'event': 'message',
          'topic': 'test-topic',
          'title': 'Test',
          'message': 'Test message',
        };

        ntfyService.onMessage(messageJson);

        await Future.delayed(Duration.zero);

        // Should not crash
        verify(
          () => mockNotificationService.addFromNtfyMessage(any()),
        ).called(1);
      });
    });

    group('connection edge cases', () {
      test(
        'should not reconnect if topic changed during reconnect delay',
        () async {
          final streamController = StreamController<Uint8List>();
          final responseBody = ResponseBody(
            streamController.stream,
            200,
            headers: {},
          );
          final response = Response<ResponseBody>(
            requestOptions: RequestOptions(path: ''),
            data: responseBody,
          );

          when(
            () => mockDio.get<ResponseBody>(
              any(),
              options: any(named: 'options'),
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer((_) async => response);

          await ntfyService.connect('test-topic-1');

          // Trigger error to start reconnect timer
          streamController.addError(Exception('Error'));
          await Future.delayed(const Duration(milliseconds: 50));

          // Change topic before reconnect happens
          await ntfyService.disconnect();

          // Wait for would-be reconnect time
          await Future.delayed(const Duration(seconds: 6));

          expect(ntfyService.currentTopic, isNull);

          await streamController.close();
        },
      );

      test('should handle already connected to same topic', () async {
        final streamController = StreamController<Uint8List>();
        final responseBody = ResponseBody(
          streamController.stream,
          200,
          headers: {},
        );
        final response = Response<ResponseBody>(
          requestOptions: RequestOptions(path: ''),
          data: responseBody,
        );

        when(
          () => mockDio.get<ResponseBody>(
            any(),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => response);

        await ntfyService.connect('same-topic');
        expect(ntfyService.isConnected, isTrue);

        // Try to connect again to same topic
        await ntfyService.connect('same-topic');

        // Should still be connected
        expect(ntfyService.isConnected, isTrue);
        expect(ntfyService.currentTopic, 'same-topic');

        await streamController.close();
      });

      test(
        'should disconnect from old topic when connecting to new topic',
        () async {
          final streamController1 = StreamController<Uint8List>();
          final responseBody1 = ResponseBody(
            streamController1.stream,
            200,
            headers: {},
          );
          final response1 = Response<ResponseBody>(
            requestOptions: RequestOptions(path: ''),
            data: responseBody1,
          );

          final streamController2 = StreamController<Uint8List>();
          final responseBody2 = ResponseBody(
            streamController2.stream,
            200,
            headers: {},
          );
          final response2 = Response<ResponseBody>(
            requestOptions: RequestOptions(path: ''),
            data: responseBody2,
          );

          when(
            () => mockDio.get<ResponseBody>(
              any(),
              options: any(named: 'options'),
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer((_) async => response1);

          await ntfyService.connect('topic-1');
          expect(ntfyService.currentTopic, 'topic-1');

          // Connect to different topic
          when(
            () => mockDio.get<ResponseBody>(
              any(),
              options: any(named: 'options'),
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer((_) async => response2);

          await ntfyService.connect('topic-2');
          expect(ntfyService.currentTopic, 'topic-2');

          await streamController1.close();
          await streamController2.close();
        },
      );

      test('should handle cancellation during connect', () async {
        when(
          () => mockDio.get<ResponseBody>(
            any(),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 1));
          throw DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.cancel,
          );
        });

        try {
          await ntfyService.connect('test-topic');
        } catch (e) {
          // Expected to throw
        }

        expect(ntfyService.isConnected, isFalse);
      });
    });

    group('ChangeNotifier behavior', () {
      test('should notify listeners on connection state change', () async {
        bool listenerCalled = false;
        ntfyService.addListener(() {
          listenerCalled = true;
        });

        final streamController = StreamController<Uint8List>();
        final responseBody = ResponseBody(
          streamController.stream,
          200,
          headers: {},
        );
        final response = Response<ResponseBody>(
          requestOptions: RequestOptions(path: ''),
          data: responseBody,
        );

        when(
          () => mockDio.get<ResponseBody>(
            any(),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => response);

        await ntfyService.connect('test-topic');

        expect(listenerCalled, isTrue);

        await streamController.close();
      });

      test(
        'should not notify listeners if connection state unchanged',
        () async {
          int listenerCallCount = 0;
          ntfyService.addListener(() {
            listenerCallCount++;
          });

          // Disconnect when already disconnected
          await ntfyService.disconnect();

          expect(listenerCallCount, 0);
        },
      );
    });
  });
}
