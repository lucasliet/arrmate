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
  });
}
