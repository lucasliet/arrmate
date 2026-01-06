import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileMediaInfo', () {
    test('Deve criar FileMediaInfo a partir de JSON completo', () {
      final json = {
        'audioBitrate': 320000,
        'audioChannels': 5.1,
        'audioCodec': 'AAC',
        'audioLanguages': 'eng',
        'audioStreamCount': 2,
        'videoBitDepth': 10,
        'videoBitrate': 5000000,
        'videoCodec': 'h264',
        'videoFps': 23.976,
        'resolution': '1920x1080',
        'runTime': '02:15:30',
        'scanType': 'Progressive',
        'subtitles': 'eng, por',
      };

      final mediaInfo = FileMediaInfo.fromJson(json);

      expect(mediaInfo.audioBitrate, 320000);
      expect(mediaInfo.audioChannels, 5.1);
      expect(mediaInfo.audioCodec, 'AAC');
      expect(mediaInfo.audioLanguages, 'eng');
      expect(mediaInfo.audioStreamCount, 2);
      expect(mediaInfo.videoBitDepth, 10);
      expect(mediaInfo.videoBitrate, 5000000);
      expect(mediaInfo.videoCodec, 'h264');
      expect(mediaInfo.videoFps, 23.976);
      expect(mediaInfo.resolution, '1920x1080');
      expect(mediaInfo.runTime, '02:15:30');
      expect(mediaInfo.scanType, 'Progressive');
      expect(mediaInfo.subtitles, 'eng, por');
    });

    test('Deve criar FileMediaInfo a partir de JSON com campos nulos', () {
      final json = <String, dynamic>{};

      final mediaInfo = FileMediaInfo.fromJson(json);

      expect(mediaInfo.audioBitrate, null);
      expect(mediaInfo.audioChannels, null);
      expect(mediaInfo.audioCodec, null);
      expect(mediaInfo.audioLanguages, null);
      expect(mediaInfo.audioStreamCount, null);
      expect(mediaInfo.videoBitDepth, null);
      expect(mediaInfo.videoBitrate, null);
      expect(mediaInfo.videoCodec, null);
      expect(mediaInfo.videoFps, null);
      expect(mediaInfo.resolution, null);
      expect(mediaInfo.runTime, null);
      expect(mediaInfo.scanType, null);
      expect(mediaInfo.subtitles, null);
    });

    test('Deve serializar FileMediaInfo para JSON', () {
      final mediaInfo = FileMediaInfo(
        audioBitrate: 320000,
        audioChannels: 5.1,
        audioCodec: 'AAC',
        videoCodec: 'h264',
        resolution: '1920x1080',
      );

      final json = mediaInfo.toJson();

      expect(json['audioBitrate'], 320000);
      expect(json['audioChannels'], 5.1);
      expect(json['audioCodec'], 'AAC');
      expect(json['videoCodec'], 'h264');
      expect(json['resolution'], '1920x1080');
    });
  });

  group('MediaFile', () {
    test('Deve criar MediaFile a partir de JSON completo', () {
      final json = {
        'id': 1,
        'movieId': 100,
        'relativePath': 'Movie.2023.1080p.mkv',
        'path': '/movies/Movie.2023.1080p.mkv',
        'size': 8589934592,
        'dateAdded': '2024-01-15T10:30:00Z',
        'sceneName': 'Movie.2023.1080p.BluRay.x264',
        'quality': {
          'quality': {
            'id': 7,
            'name': 'Bluray-1080p',
            'source': 'bluray',
            'resolution': 1080,
          },
        },
        'languages': [
          {'id': 1, 'name': 'English'},
        ],
        'mediaInfo': {'videoCodec': 'h264', 'resolution': '1920x1080'},
        'customFormats': [
          {'id': 1, 'name': 'Custom Format'},
        ],
        'customFormatScore': 100,
      };

      final mediaFile = MediaFile.fromJson(json);

      expect(mediaFile.id, 1);
      expect(mediaFile.relativePath, 'Movie.2023.1080p.mkv');
      expect(mediaFile.size, 8589934592);
      expect(mediaFile.quality, isNotNull);
      expect(mediaFile.quality!.quality.name, 'Bluray-1080p');
      expect(mediaFile.languages, isNotNull);
      expect(mediaFile.languages!.length, 1);
      expect(mediaFile.mediaInfo, isNotNull);
      expect(mediaFile.mediaInfo!.videoCodec, 'h264');
      expect(mediaFile.customFormats, isNotNull);
      expect(mediaFile.customFormats!.length, 1);
      expect(mediaFile.customFormatScore, 100);
    });

    test('Deve serializar MediaFile para JSON', () {
      final mediaFile = MediaFile(
        id: 1,
        size: 8589934592,
        dateAdded: DateTime.parse('2024-01-15T10:30:00Z'),
        relativePath: 'Movie.2023.1080p.mkv',
      );

      final json = mediaFile.toJson();

      expect(json['id'], 1);
      expect(json['size'], 8589934592);
      expect(json['relativePath'], 'Movie.2023.1080p.mkv');
    });
  });

  group('MovieExtraFile', () {
    test('Deve criar MovieExtraFile a partir de JSON', () {
      final json = {
        'id': 1,
        'movieId': 100,
        'movieFileId': 50,
        'relativePath': 'Subtitles/Movie.en.srt',
        'extension': '.srt',
        'type': 'subtitle',
      };

      final extraFile = MovieExtraFile.fromJson(json);

      expect(extraFile.id, 1);
      expect(extraFile.movieId, 100);
      expect(extraFile.movieFileId, 50);
      expect(extraFile.relativePath, 'Subtitles/Movie.en.srt');
      expect(extraFile.extension, '.srt');
      expect(extraFile.type, ExtraFileType.subtitle);
    });

    test('Deve mapear tipos de arquivo corretamente', () {
      expect(
        MovieExtraFile.fromJson({'id': 1, 'type': 'subtitle'}).type,
        ExtraFileType.subtitle,
      );
      expect(
        MovieExtraFile.fromJson({'id': 1, 'type': 'metadata'}).type,
        ExtraFileType.metadata,
      );
      expect(
        MovieExtraFile.fromJson({'id': 1, 'type': 'other'}).type,
        ExtraFileType.other,
      );
      expect(
        MovieExtraFile.fromJson({'id': 1, 'type': 'unknown'}).type,
        ExtraFileType.other,
      );
    });
  });

  group('SeriesExtraFile', () {
    test('Deve criar SeriesExtraFile a partir de JSON', () {
      final json = {
        'id': 1,
        'seriesId': 200,
        'seasonNumber': 1,
        'episodeFileId': 75,
        'relativePath': 'Subtitles/Series.S01E01.en.srt',
        'extension': '.srt',
        'type': 'subtitle',
      };

      final extraFile = SeriesExtraFile.fromJson(json);

      expect(extraFile.id, 1);
      expect(extraFile.seriesId, 200);
      expect(extraFile.seasonNumber, 1);
      expect(extraFile.episodeFileId, 75);
      expect(extraFile.relativePath, 'Subtitles/Series.S01E01.en.srt');
      expect(extraFile.extension, '.srt');
      expect(extraFile.type, ExtraFileType.subtitle);
    });
  });
}
