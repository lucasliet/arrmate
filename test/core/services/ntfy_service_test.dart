import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:arrmate/core/services/ntfy_service.dart';
import 'package:arrmate/core/services/notification_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockDio extends Mock implements Dio {}

void main() {
  group('NtfyService', () {
    late MockNotificationService mockNotificationService;
    late MockDio mockDio;
    late NtfyService ntfyService;

    setUp(() {
      mockNotificationService = MockNotificationService();
      mockDio = MockDio();
      ntfyService = NtfyService(mockNotificationService, dio: mockDio);

      // Default mock behavior for Dio
      registerFallbackValue(RequestOptions(path: ''));
      registerFallbackValue(Options());
      registerFallbackValue(CancelToken());
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
      test('should show notification for message events', () async {
        when(
          () => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

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

        verify(
          () => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: 'Movie Downloaded',
            body: 'Inception has been downloaded',
            payload: 'arrmate://movie/123',
          ),
        ).called(1);
      });

      test('should use default title when not provided', () async {
        when(
          () => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        final messageJson = {
          'id': 'test456',
          'time': 1704067200,
          'event': 'message',
          'topic': 'test-topic',
          'message': 'Something happened',
        };

        ntfyService.onMessage(messageJson);

        verify(
          () => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: 'Arrmate',
            body: 'Something happened',
            payload: null,
          ),
        ).called(1);
      });

      test('should handle string JSON input', () {
        when(
          () => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        const jsonString =
            '{"id":"str123","time":1704067200,"event":"message","topic":"test","title":"Test","message":"Test msg"}';

        ntfyService.onMessage(jsonString);

        verify(
          () => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: 'Test',
            body: 'Test msg',
            payload: null,
          ),
        ).called(1);
      });
    });
  });
}
