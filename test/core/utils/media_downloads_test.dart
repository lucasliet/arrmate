import 'package:arrmate/core/utils/media_downloads.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

void main() {
  group('isDownloadEvent', () {
    test('should accept grabbed and imported events only', () {
      expect(isDownloadEvent(_event(eventType: 'grabbed')), isTrue);
      expect(
        isDownloadEvent(_event(eventType: 'downloadFolderImported')),
        isTrue,
      );
      expect(isDownloadEvent(_event(eventType: 'downloadFailed')), isFalse);
      expect(isDownloadEvent(_event(eventType: 'movieFileDeleted')), isFalse);
      expect(isDownloadEvent(_event(eventType: 'downloadIgnored')), isFalse);
    });
  });

  group('MediaDownloads.hashesBeyond', () {
    test('should return the hashes covering an episode outside the scope', () {
      // Given
      const downloads = MediaDownloads(
        episodesByHash: {
          'season': {1, 2},
          'complete': {1, 2, 11},
          'movie': {},
        },
      );

      // Then
      expect(downloads.hashesBeyond([1, 2]), {'complete'});
      expect(downloads.hashesBeyond([1, 2, 11]), isEmpty);
      expect(downloads.hashesBeyond(const []), {'season', 'complete'});
    });
  });

  group('collectMovieDownloads', () {
    test('should merge history and queue hashes in lowercase', () async {
      // Given
      final repository = MockMovieRepository();
      when(() => repository.getMovieHistory(7)).thenAnswer(
        (_) async => [
          _event(eventType: 'grabbed', downloadId: 'AABB'),
          _event(eventType: 'downloadFolderImported', downloadId: 'aabb'),
          _event(eventType: 'downloadFailed', downloadId: 'FAILED'),
          _event(eventType: 'grabbed'),
          _event(eventType: 'grabbed', downloadId: ''),
        ],
      );
      _stubMovieQueue(repository, [
        _queuePage([
          _queueItem(id: 10, movieId: 7, downloadId: 'CCDD'),
          _queueItem(id: 11, movieId: 7, downloadId: 'AABB'),
          _queueItem(id: 12, movieId: 8, downloadId: 'OTHER'),
          _queueItem(id: 13, movieId: 7),
        ]),
      ]);

      // When
      final downloads = await collectMovieDownloads(repository, 7);

      // Then
      expect(downloads.hashes, {'aabb', 'ccdd'});
      expect(downloads.queueIds, [10, 11, 13]);
      expect(downloads.queueHashes, {10: 'ccdd', 11: 'aabb'});
      expect(downloads.episodesByHash['aabb'], isEmpty);
    });

    test('should walk every queue page until a short page', () async {
      // Given two full pages followed by a short one
      final repository = MockMovieRepository();
      when(
        () => repository.getMovieHistory(7),
      ).thenAnswer((_) async => const []);
      _stubMovieQueue(repository, [
        _queuePage(
          _fullPage(offset: 0, matchAt: 5, downloadId: 'PAGE1'),
          total: 250,
        ),
        _queuePage(
          _fullPage(offset: 100, matchAt: 42, downloadId: 'PAGE2'),
          total: 250,
        ),
        _queuePage([
          _queueItem(id: 999, movieId: 7, downloadId: 'PAGE3'),
        ], total: 250),
      ]);

      // When
      final downloads = await collectMovieDownloads(repository, 7);

      // Then
      expect(downloads.hashes, {'page1', 'page2', 'page3'});
      expect(downloads.queueIds, [5, 142, 999]);
      verify(() => repository.getQueue(page: 3, pageSize: 100)).called(1);
      verifyNever(() => repository.getQueue(page: 4, pageSize: 100));
    });

    test('should stop after a full page holding every record', () async {
      // Given exactly one full page and no more records on the server
      final repository = MockMovieRepository();
      when(
        () => repository.getMovieHistory(7),
      ).thenAnswer((_) async => const []);
      _stubMovieQueue(repository, [
        _queuePage(
          _fullPage(offset: 0, matchAt: 0, downloadId: 'ONLY'),
          total: 100,
        ),
      ]);

      // When
      await collectMovieDownloads(repository, 7);

      // Then
      verify(() => repository.getQueue(page: 1, pageSize: 100)).called(1);
      verifyNever(() => repository.getQueue(page: 2, pageSize: 100));
    });
  });

  group('collectSeriesDownloads', () {
    test('should group episodes by hash from history and queue', () async {
      // Given a season pack in history and an episode still downloading
      final repository = MockSeriesRepository();
      when(() => repository.getSeriesHistory(3)).thenAnswer(
        (_) async => [
          _event(eventType: 'grabbed', downloadId: 'PACK', episodeId: 1),
          _event(eventType: 'grabbed', downloadId: 'PACK', episodeId: 2),
          _event(
            eventType: 'downloadFolderImported',
            downloadId: 'pack',
            episodeId: 3,
          ),
        ],
      );
      _stubSeriesQueue(repository, [
        _queuePage([
          _queueItem(id: 20, seriesId: 3, episodeId: 9, downloadId: 'LIVE'),
          _queueItem(id: 21, seriesId: 4, episodeId: 1, downloadId: 'OTHER'),
        ]),
      ]);

      // When
      final downloads = await collectSeriesDownloads(repository, 3);

      // Then
      expect(downloads.episodesByHash, {
        'pack': {1, 2, 3},
        'live': {9},
      });
      expect(downloads.queueIds, [20]);
    });
  });

  group('collectSeasonDownloads', () {
    test(
      'should keep only hashes touching the season, with their full coverage',
      () async {
        // Given a single-season pack, a complete-series pack and a later grab
        final repository = MockSeriesRepository();
        when(() => repository.getSeriesHistory(3)).thenAnswer(
          (_) async => [
            _event(eventType: 'grabbed', downloadId: 'S01', episodeId: 1),
            _event(eventType: 'grabbed', downloadId: 'S01', episodeId: 2),
            _event(eventType: 'grabbed', downloadId: 'ALL', episodeId: 2),
            _event(eventType: 'grabbed', downloadId: 'ALL', episodeId: 11),
            _event(eventType: 'grabbed', downloadId: 'S02', episodeId: 11),
          ],
        );

        // When
        final downloads = await collectSeasonDownloads(repository, 3, [1, 2]);

        // Then the complete pack keeps its season 2 episode for the caller
        expect(downloads.episodesByHash, {
          's01': {1, 2},
          'all': {2, 11},
        });
        expect(downloads.queueIds, isEmpty);
        verifyNever(
          () => repository.getQueue(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          ),
        );
      },
    );
  });
}

/// Answers the movie queue with [pages], in order.
void _stubMovieQueue(MockMovieRepository repository, List<QueueItems> pages) {
  when(
    () => repository.getQueue(
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
      sortKey: any(named: 'sortKey'),
      sortDirection: any(named: 'sortDirection'),
    ),
  ).thenAnswer((invocation) async {
    final page = invocation.namedArguments[#page] as int;
    return pages[page - 1];
  });
}

/// Answers the series queue with [pages], in order.
void _stubSeriesQueue(MockSeriesRepository repository, List<QueueItems> pages) {
  when(
    () => repository.getQueue(
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
      sortKey: any(named: 'sortKey'),
      sortDirection: any(named: 'sortDirection'),
    ),
  ).thenAnswer((invocation) async {
    final page = invocation.namedArguments[#page] as int;
    return pages[page - 1];
  });
}

/// A full queue page of 100 items belonging to another movie, except the one
/// at [matchAt], which belongs to movie `7` and carries [downloadId].
List<QueueItem> _fullPage({
  required int offset,
  required int matchAt,
  required String downloadId,
}) {
  return [
    for (var i = 0; i < 100; i++)
      i == matchAt
          ? _queueItem(id: offset + i, movieId: 7, downloadId: downloadId)
          : _queueItem(id: offset + i, movieId: 99, downloadId: 'X$i'),
  ];
}

QueueItems _queuePage(List<QueueItem> records, {int? total}) {
  return QueueItems(
    page: 1,
    pageSize: 100,
    sortKey: 'timeleft',
    sortDirection: 'ascending',
    totalRecords: total ?? records.length,
    records: records,
  );
}

QueueItem _queueItem({
  required int id,
  int? movieId,
  int? seriesId,
  int? episodeId,
  String? downloadId,
}) {
  return QueueItem.fromJson({
    'id': id,
    'movieId': ?movieId,
    'seriesId': ?seriesId,
    'episodeId': ?episodeId,
    'title': 'Queued release',
    'protocol': 'torrent',
    'sizeleft': 0,
    'status': 'downloading',
    'downloadId': ?downloadId,
  });
}

HistoryEvent _event({
  required String eventType,
  String? downloadId,
  int? episodeId,
}) {
  return HistoryEvent.fromJson({
    'id': 1,
    'eventType': eventType,
    'date': '2026-01-01T00:00:00Z',
    'sourceTitle': 'Release',
    'episodeId': ?episodeId,
    'downloadId': ?downloadId,
    'quality': {
      'quality': {'id': 1, 'name': '1080p'},
      'revision': {'version': 1, 'real': 0},
    },
  });
}
