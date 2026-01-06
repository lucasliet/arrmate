import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/domain/models/notification/ntfy_message.dart';

void main() {
  group('NtfyMessage', () {
    group('fromJson', () {
      test('should parse a complete ntfy message', () {
        // Given
        final json = {
          'id': 'abc123',
          'time': 1704067200,
          'event': 'message',
          'topic': 'arrmate-test',
          'title': 'Movie Downloaded',
          'message': 'Inception (2010) has been downloaded',
          'priority': 3,
          'tags': ['movie', 'downloaded'],
          'click': 'arrmate://movie/123',
        };

        // When
        final message = NtfyMessage.fromJson(json);

        // Then
        expect(message.id, 'abc123');
        expect(message.time, 1704067200);
        expect(message.event, 'message');
        expect(message.topic, 'arrmate-test');
        expect(message.title, 'Movie Downloaded');
        expect(message.message, 'Inception (2010) has been downloaded');
        expect(message.priority, 3);
        expect(message.tags, ['movie', 'downloaded']);
        expect(message.click, 'arrmate://movie/123');
      });

      test('should handle minimal message with only required fields', () {
        // Given
        final json = {
          'id': 'xyz789',
          'time': 1704067200,
          'event': 'open',
          'topic': 'test-topic',
        };

        // When
        final message = NtfyMessage.fromJson(json);

        // Then
        expect(message.id, 'xyz789');
        expect(message.event, 'open');
        expect(message.title, isNull);
        expect(message.message, isNull);
        expect(message.priority, isNull);
        expect(message.tags, isNull);
        expect(message.click, isNull);
      });

      test('should provide default values for missing required fields', () {
        // Given
        final json = <String, dynamic>{};

        // When
        final message = NtfyMessage.fromJson(json);

        // Then
        expect(message.id, '');
        expect(message.time, 0);
        expect(message.event, 'message');
        expect(message.topic, '');
      });
    });

    group('toJson', () {
      test('should serialize all fields correctly', () {
        // Given
        const message = NtfyMessage(
          id: 'test-id',
          time: 1704067200,
          event: 'message',
          topic: 'test-topic',
          title: 'Test Title',
          message: 'Test message body',
          priority: 4,
          tags: ['tag1', 'tag2'],
          click: 'https://example.com',
        );

        // When
        final json = message.toJson();

        // Then
        expect(json['id'], 'test-id');
        expect(json['time'], 1704067200);
        expect(json['event'], 'message');
        expect(json['topic'], 'test-topic');
        expect(json['title'], 'Test Title');
        expect(json['message'], 'Test message body');
        expect(json['priority'], 4);
        expect(json['tags'], ['tag1', 'tag2']);
        expect(json['click'], 'https://example.com');
      });

      test('should omit null optional fields', () {
        // Given
        const message = NtfyMessage(
          id: 'test-id',
          time: 1704067200,
          event: 'keepalive',
          topic: 'test-topic',
        );

        // When
        final json = message.toJson();

        // Then
        expect(json.containsKey('title'), isFalse);
        expect(json.containsKey('message'), isFalse);
        expect(json.containsKey('priority'), isFalse);
        expect(json.containsKey('tags'), isFalse);
        expect(json.containsKey('click'), isFalse);
      });
    });

    group('event type helpers', () {
      test('isMessage should return true for message events', () {
        // Given
        const message = NtfyMessage(
          id: 'test',
          time: 0,
          event: 'message',
          topic: 'test',
        );

        // Then
        expect(message.isMessage, isTrue);
        expect(message.isOpen, isFalse);
        expect(message.isKeepalive, isFalse);
      });

      test('isOpen should return true for open events', () {
        // Given
        const message = NtfyMessage(
          id: 'test',
          time: 0,
          event: 'open',
          topic: 'test',
        );

        // Then
        expect(message.isMessage, isFalse);
        expect(message.isOpen, isTrue);
        expect(message.isKeepalive, isFalse);
      });

      test('isKeepalive should return true for keepalive events', () {
        // Given
        const message = NtfyMessage(
          id: 'test',
          time: 0,
          event: 'keepalive',
          topic: 'test',
        );

        // Then
        expect(message.isMessage, isFalse);
        expect(message.isOpen, isFalse);
        expect(message.isKeepalive, isTrue);
      });
    });

    group('timestamp', () {
      test('should convert unix timestamp to DateTime', () {
        // Given - 1704067200 = 2024-01-01 00:00:00 UTC
        const message = NtfyMessage(
          id: 'test',
          time: 1704067200,
          event: 'message',
          topic: 'test',
        );

        // When
        final timestamp = message.timestamp;

        // Then
        expect(timestamp.toUtc().year, 2024);
        expect(timestamp.toUtc().month, 1);
        expect(timestamp.toUtc().day, 1);
      });
    });

    group('equality', () {
      test(
        'should be equal when id, time, event, topic, title, message match',
        () {
          // Given
          const message1 = NtfyMessage(
            id: 'test-id',
            time: 1704067200,
            event: 'message',
            topic: 'test-topic',
            title: 'Test',
            message: 'Body',
          );
          const message2 = NtfyMessage(
            id: 'test-id',
            time: 1704067200,
            event: 'message',
            topic: 'test-topic',
            title: 'Test',
            message: 'Body',
            priority: 5,
          );

          // Then
          expect(message1, equals(message2));
        },
      );
    });
  });
}
