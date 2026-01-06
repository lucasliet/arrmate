import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:arrmate/core/services/ntfy_service.dart';
import 'package:arrmate/core/services/notification_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('NtfyService', () {
    late MockNotificationService mockNotificationService;
    late NtfyService ntfyService;

    setUp(() {
      mockNotificationService = MockNotificationService();
      ntfyService = NtfyService(mockNotificationService);
    });

    tearDown(() async {
      await ntfyService.disconnect();
    });

    group('initial state', () {
      test('should not be connected initially', () {
        // Then
        expect(ntfyService.isConnected, isFalse);
      });

      test('should have no current topic initially', () {
        // Then
        expect(ntfyService.currentTopic, isNull);
      });
    });

    group('generateTopic', () {
      test('should generate topic with arrmate prefix', () {
        // When
        final topic = NtfyService.generateTopic();

        // Then
        expect(topic, startsWith('arrmate-'));
      });

      test('should generate topic with 12 character suffix', () {
        // When
        final topic = NtfyService.generateTopic();

        // Then
        final suffix = topic.replaceFirst('arrmate-', '');
        expect(suffix.length, 12);
      });

      test('should generate unique topics', () {
        // When
        final topic1 = NtfyService.generateTopic();
        final topic2 = NtfyService.generateTopic();

        // Then
        expect(topic1, isNot(equals(topic2)));
      });

      test('should generate topic without dashes in suffix', () {
        // When
        final topic = NtfyService.generateTopic();

        // Then
        final suffix = topic.replaceFirst('arrmate-', '');
        expect(suffix.contains('-'), isFalse);
      });
    });

    group('disconnect', () {
      test('should reset connection state', () async {
        // When
        await ntfyService.disconnect();

        // Then
        expect(ntfyService.isConnected, isFalse);
        expect(ntfyService.currentTopic, isNull);
      });

      test('should be safe to call multiple times', () async {
        // When/Then
        await ntfyService.disconnect();
        await ntfyService.disconnect();
        await ntfyService.disconnect();

        expect(ntfyService.isConnected, isFalse);
      });
    });

    group('onMessage', () {
      test('should show notification for message events', () async {
        // Given
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

        // When
        ntfyService.onMessage(messageJson);

        // Then
        verify(
          () => mockNotificationService.showNotification(
            id: 'test123'.hashCode,
            title: 'Movie Downloaded',
            body: 'Inception has been downloaded',
            payload: 'arrmate://movie/123',
          ),
        ).called(1);
      });

      test('should use default title when not provided', () async {
        // Given
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

        // When
        ntfyService.onMessage(messageJson);

        // Then
        verify(
          () => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: 'Arrmate',
            body: 'Something happened',
            payload: null,
          ),
        ).called(1);
      });

      test('should not show notification for open events', () {
        // Given
        final openJson = {
          'id': 'open123',
          'time': 1704067200,
          'event': 'open',
          'topic': 'test-topic',
        };

        // When
        ntfyService.onMessage(openJson);

        // Then
        verifyNever(
          () => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          ),
        );
      });

      test('should not show notification for keepalive events', () {
        // Given
        final keepaliveJson = {
          'id': 'ka123',
          'time': 1704067200,
          'event': 'keepalive',
          'topic': 'test-topic',
        };

        // When
        ntfyService.onMessage(keepaliveJson);

        // Then
        verifyNever(
          () => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          ),
        );
      });

      test('should handle string JSON input', () {
        // Given
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

        // When
        ntfyService.onMessage(jsonString);

        // Then
        verify(
          () => mockNotificationService.showNotification(
            id: 'str123'.hashCode,
            title: 'Test',
            body: 'Test msg',
            payload: null,
          ),
        ).called(1);
      });

      test('should use empty string for missing message body', () {
        // Given
        when(
          () => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        final messageJson = {
          'id': 'nomsg123',
          'time': 1704067200,
          'event': 'message',
          'topic': 'test-topic',
          'title': 'Title Only',
        };

        // When
        ntfyService.onMessage(messageJson);

        // Then
        verify(
          () => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: 'Title Only',
            body: '',
            payload: null,
          ),
        ).called(1);
      });
    });
  });
}
