import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/domain/models/shared/media_file.dart';

void main() {
  group('MediaFile Model', () {
    test('should parse valid JSON with valid dateAdded', () {
      // Given
      final json = {
        'id': 1,
        'relativePath': '/path/to/file.mkv',
        'path': '/absolute/path/to/file.mkv',
        'size': 1024,
        'dateAdded': '2024-01-15T10:30:00Z',
      };

      // When
      final mediaFile = MediaFile.fromJson(json);

      // Then
      expect(mediaFile.id, 1);
      expect(mediaFile.relativePath, '/path/to/file.mkv');
      expect(mediaFile.path, '/absolute/path/to/file.mkv');
      expect(mediaFile.size, 1024);
      expect(mediaFile.dateAdded.year, 2024);
      expect(mediaFile.dateAdded.month, 1);
      expect(mediaFile.dateAdded.day, 15);
    });

    test('should use DateTime.now() fallback when dateAdded is null', () {
      // Given
      final json = {'id': 2, 'size': 512, 'dateAdded': null};
      final beforeTest = DateTime.now();

      // When
      final mediaFile = MediaFile.fromJson(json);
      final afterTest = DateTime.now();

      // Then
      expect(mediaFile.id, 2);
      expect(
        mediaFile.dateAdded.isAfter(
              beforeTest.subtract(const Duration(seconds: 1)),
            ) &&
            mediaFile.dateAdded.isBefore(
              afterTest.add(const Duration(seconds: 1)),
            ),
        isTrue,
      );
    });

    test(
      'should use DateTime.now() fallback when dateAdded is invalid format',
      () {
        // Given
        final json = {'id': 3, 'size': 256, 'dateAdded': 'invalid-date-format'};
        final beforeTest = DateTime.now();

        // When
        final mediaFile = MediaFile.fromJson(json);
        final afterTest = DateTime.now();

        // Then
        expect(mediaFile.id, 3);
        expect(
          mediaFile.dateAdded.isAfter(
                beforeTest.subtract(const Duration(seconds: 1)),
              ) &&
              mediaFile.dateAdded.isBefore(
                afterTest.add(const Duration(seconds: 1)),
              ),
          isTrue,
        );
      },
    );

    test(
      'should use DateTime.now() fallback when dateAdded is empty string',
      () {
        // Given
        final json = {'id': 4, 'size': 128, 'dateAdded': ''};
        final beforeTest = DateTime.now();

        // When
        final mediaFile = MediaFile.fromJson(json);
        final afterTest = DateTime.now();

        // Then
        expect(mediaFile.id, 4);
        expect(
          mediaFile.dateAdded.isAfter(
                beforeTest.subtract(const Duration(seconds: 1)),
              ) &&
              mediaFile.dateAdded.isBefore(
                afterTest.add(const Duration(seconds: 1)),
              ),
          isTrue,
        );
      },
    );

    test('should use default size of 0 when size is null', () {
      // Given
      final json = {'id': 5, 'dateAdded': '2024-01-01T00:00:00Z'};

      // When
      final mediaFile = MediaFile.fromJson(json);

      // Then
      expect(mediaFile.size, 0);
    });

    test('should parse quality info correctly', () {
      // Given
      final json = {
        'id': 6,
        'size': 2048,
        'dateAdded': '2024-06-01T12:00:00Z',
        'quality': {
          'quality': {
            'id': 1,
            'name': '1080p',
            'source': 'bluray',
            'resolution': 1080,
          },
          'revision': {'version': 2},
        },
      };

      // When
      final mediaFile = MediaFile.fromJson(json);

      // Then
      expect(mediaFile.quality, isNotNull);
      expect(mediaFile.quality!.quality.name, '1080p');
      expect(mediaFile.quality!.quality.resolution, 1080);
      expect(mediaFile.quality!.revision, 2);
    });

    test('should parse languages correctly', () {
      // Given
      final json = {
        'id': 7,
        'size': 1024,
        'dateAdded': '2024-03-15T08:00:00Z',
        'languages': [
          {'id': 1, 'name': 'English'},
          {'id': 2, 'name': 'Portuguese'},
        ],
      };

      // When
      final mediaFile = MediaFile.fromJson(json);

      // Then
      expect(mediaFile.languages, isNotNull);
      expect(mediaFile.languages!.length, 2);
      expect(mediaFile.languages![0].name, 'English');
      expect(mediaFile.languages![1].name, 'Portuguese');
    });

    test('should convert to JSON correctly', () {
      // Given
      final mediaFile = MediaFile(
        id: 8,
        relativePath: '/relative/path.mkv',
        path: '/absolute/path.mkv',
        size: 4096,
        dateAdded: DateTime.parse('2024-07-01T00:00:00Z'),
      );

      // When
      final json = mediaFile.toJson();

      // Then
      expect(json['id'], 8);
      expect(json['relativePath'], '/relative/path.mkv');
      expect(json['path'], '/absolute/path.mkv');
      expect(json['size'], 4096);
      expect(json['dateAdded'], '2024-07-01T00:00:00.000Z');
    });
  });
}
