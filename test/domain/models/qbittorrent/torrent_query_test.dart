import 'package:arrmate/domain/models/qbittorrent/torrent.dart';
import 'package:arrmate/domain/models/qbittorrent/torrent_link.dart';
import 'package:arrmate/domain/models/qbittorrent/torrent_query.dart';
import 'package:arrmate/domain/models/qbittorrent/torrent_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TorrentQuery', () {
    test('should preserve every option through JSON serialization', () {
      // Given
      const query = TorrentQuery(
        search: 'ubuntu',
        status: TorrentStatusFilter.paused,
        linkFilter: TorrentLinkFilter.orphan,
        categories: {'movies'},
        tags: {'cross-seed', 'movies'},
        sortOption: TorrentSortOption.size,
        sortAscending: true,
      );

      // When
      final restored = TorrentQuery.fromJson(query.toJson());

      // Then
      expect(restored, query);
    });

    test('should restore defaults for unknown enum names', () {
      // Given
      final json = {
        'status': 'removed',
        'linkFilter': 'unknown-filter',
        'sortOption': 'priority',
      };

      // When
      final restored = TorrentQuery.fromJson(json);

      // Then
      expect(restored, const TorrentQuery());
    });

    test('should ignore non-string tag entries when restoring', () {
      // Given
      final json = {
        'tags': ['movies', 42, null],
      };

      // When
      final restored = TorrentQuery.fromJson(json);

      // Then
      expect(restored.tags, {'movies'});
    });

    test('should clear filters while preserving the sorting', () {
      // Given
      const query = TorrentQuery(
        search: 'ubuntu',
        status: TorrentStatusFilter.seeding,
        linkFilter: TorrentLinkFilter.linked,
        categories: {'movies'},
        tags: {'movies'},
        sortOption: TorrentSortOption.ratio,
        sortAscending: true,
      );

      // When
      final cleared = query.clearFilters();

      // Then
      expect(cleared.search, isEmpty);
      expect(cleared.status, TorrentStatusFilter.all);
      expect(cleared.linkFilter, TorrentLinkFilter.all);
      expect(cleared.categories, isEmpty);
      expect(cleared.tags, isEmpty);
      expect(cleared.sortOption, TorrentSortOption.ratio);
      expect(cleared.sortAscending, isTrue);
      expect(cleared.hasActiveFilters, isFalse);
    });

    test('should match torrents carrying any of the selected tags', () {
      // Given
      final tagged = _torrent(name: 'Tagged', tags: ['movies', '4k']);
      final otherTag = _torrent(name: 'OtherTag', tags: ['series']);
      final overlapping = _torrent(name: 'Overlapping', tags: ['series', '4k']);
      final untagged = _torrent(name: 'Untagged');
      const query = TorrentQuery(tags: {'movies', 'series'});

      // When
      final results = applyTorrentQuery([
        tagged,
        otherTag,
        overlapping,
        untagged,
      ], query);

      // Then
      expect(
        results.map((torrent) => torrent.name),
        unorderedEquals(['Tagged', 'OtherTag', 'Overlapping']),
      );
    });

    test('should match torrents in any selected category', () {
      // Given
      final movies = _torrent(name: 'Movies', category: 'movies');
      final series = _torrent(name: 'Series', category: 'series');
      final uncategorized = _torrent(name: 'Uncategorized');
      const query = TorrentQuery(categories: {'movies', 'series'});

      // When
      final results = applyTorrentQuery([movies, series, uncategorized], query);

      // Then
      expect(
        results.map((torrent) => torrent.name),
        unorderedEquals(['Movies', 'Series']),
      );
    });

    test('should combine the category filter with the tag filter', () {
      // Given
      final matching = _torrent(
        name: 'Matching',
        category: 'movies',
        tags: ['4k'],
      );
      final wrongCategory = _torrent(
        name: 'WrongCategory',
        category: 'series',
        tags: ['4k'],
      );
      final wrongTag = _torrent(name: 'WrongTag', category: 'movies');
      const query = TorrentQuery(categories: {'movies'}, tags: {'4k'});

      // When
      final results = applyTorrentQuery([
        matching,
        wrongCategory,
        wrongTag,
      ], query);

      // Then
      expect(results, [matching]);
    });

    test('should combine the tag filter with status and search', () {
      // Given
      final matching = _torrent(
        name: 'Ubuntu.Iso',
        status: TorrentStatus.pausedDL,
        tags: ['movies'],
      );
      final wrongTag = _torrent(
        name: 'Ubuntu.Mini',
        status: TorrentStatus.pausedDL,
        tags: ['series'],
      );
      const query = TorrentQuery(
        search: 'ubuntu',
        status: TorrentStatusFilter.paused,
        tags: {'movies'},
      );

      // When
      final results = applyTorrentQuery([matching, wrongTag], query);

      // Then
      expect(results, [matching]);
    });

    test('should combine status, link and search filters', () {
      // Given
      final matching = _torrent(
        name: 'Ubuntu.Iso',
        status: TorrentStatus.pausedDL,
      );
      final wrongStatus = _torrent(
        name: 'Ubuntu.Mini',
        status: TorrentStatus.uploading,
      );
      final wrongLink = _torrent(
        name: 'Ubuntu.Server',
        status: TorrentStatus.pausedUP,
      );
      final wrongSearch = _torrent(
        name: 'Debian.Iso',
        status: TorrentStatus.pausedDL,
      );
      final links = {
        matching.name: TorrentLinkStatus.orphan,
        wrongStatus.name: TorrentLinkStatus.orphan,
        wrongLink.name: TorrentLinkStatus.linked,
        wrongSearch.name: TorrentLinkStatus.orphan,
      };
      const query = TorrentQuery(
        search: 'ubuntu',
        status: TorrentStatusFilter.paused,
        linkFilter: TorrentLinkFilter.orphan,
      );

      // When
      final results = applyTorrentQuery(
        [wrongStatus, wrongLink, matching, wrongSearch],
        query,
        linkResolver: (torrent) => links[torrent.name],
      );

      // Then
      expect(results, [matching]);
    });

    test('should skip the link filter when no resolver is provided', () {
      // Given
      final orphan = _torrent(name: 'Orphan', status: TorrentStatus.stalledDL);
      const query = TorrentQuery(linkFilter: TorrentLinkFilter.orphan);

      // When
      final results = applyTorrentQuery([orphan], query);

      // Then
      expect(results, [orphan]);
    });

    test('should sort active torrents first and fall back to name', () {
      // Given
      final pausedZeta = _torrent(name: 'Zeta', status: TorrentStatus.pausedDL);
      final activeAlpha = _torrent(
        name: 'Alpha',
        status: TorrentStatus.downloading,
      );
      final activeBeta = _torrent(
        name: 'Beta',
        status: TorrentStatus.uploading,
      );
      final pausedAlpha = _torrent(
        name: 'alpha',
        status: TorrentStatus.pausedUP,
      );

      // When
      final results = applyTorrentQuery([
        pausedZeta,
        activeBeta,
        pausedAlpha,
        activeAlpha,
      ], const TorrentQuery());

      // Then
      expect(results.map((torrent) => torrent.name), [
        'Alpha',
        'Beta',
        'alpha',
        'Zeta',
      ]);
    });

    test('should honor the sort direction for every field option', () {
      // Given
      final older = _torrent(
        name: 'Older',
        addedOn: 10,
        progress: 0.5,
        size: 100,
        dlspeed: 10,
        ratio: 0.5,
        seedingTime: 3600,
      );
      final newer = _torrent(
        name: 'Newer',
        addedOn: 20,
        progress: 0.9,
        size: 200,
        dlspeed: 20,
        ratio: 1.5,
        seedingTime: 7200,
      );

      // When
      final descending = {
        for (final option in TorrentSortOption.values.where(
          (option) =>
              option != TorrentSortOption.activity &&
              option != TorrentSortOption.name,
        ))
          option: applyTorrentQuery([
            older,
            newer,
          ], TorrentQuery(sortOption: option)),
      };
      final ascending = {
        for (final option in TorrentSortOption.values.where(
          (option) =>
              option != TorrentSortOption.activity &&
              option != TorrentSortOption.name,
        ))
          option: applyTorrentQuery([
            older,
            newer,
          ], TorrentQuery(sortOption: option, sortAscending: true)),
      };

      // Then
      for (final entry in descending.entries) {
        expect(
          entry.value.map((torrent) => torrent.name),
          ['Newer', 'Older'],
          reason: '${entry.key} descending',
        );
      }
      for (final entry in ascending.entries) {
        expect(
          entry.value.map((torrent) => torrent.name),
          ['Older', 'Newer'],
          reason: '${entry.key} ascending',
        );
      }
    });

    test('should invert the activity ranking when ascending', () {
      // Given
      final active = _torrent(
        name: 'Active',
        status: TorrentStatus.downloading,
      );
      final paused = _torrent(name: 'Paused', status: TorrentStatus.pausedDL);
      const query = TorrentQuery(
        sortOption: TorrentSortOption.activity,
        sortAscending: true,
      );

      // When
      final results = applyTorrentQuery([active, paused], query);

      // Then
      expect(results.map((torrent) => torrent.name), ['Paused', 'Active']);
    });

    test('should sort by name case-insensitively', () {
      // Given
      final upper = _torrent(name: 'Beta');
      final lower = _torrent(name: 'alpha');
      const query = TorrentQuery(
        sortOption: TorrentSortOption.name,
        sortAscending: true,
      );

      // When
      final results = applyTorrentQuery([upper, lower], query);

      // Then
      expect(results.map((torrent) => torrent.name), ['alpha', 'Beta']);
    });

    test('should keep seeding torrents out of the downloading filter', () {
      // Given
      final downloading = _torrent(
        name: 'Downloading',
        status: TorrentStatus.downloading,
      );
      final stalled = _torrent(
        name: 'Stalled',
        status: TorrentStatus.stalledDL,
      );
      final queued = _torrent(name: 'Queued', status: TorrentStatus.queuedDL);
      final checking = _torrent(
        name: 'Checking',
        status: TorrentStatus.checkingDL,
      );
      final seeding = _torrent(
        name: 'Seeding',
        status: TorrentStatus.uploading,
      );
      final stalledUp = _torrent(
        name: 'StalledUp',
        status: TorrentStatus.stalledUP,
      );
      const query = TorrentQuery(status: TorrentStatusFilter.downloading);

      // When
      final results = applyTorrentQuery([
        downloading,
        stalled,
        queued,
        checking,
        seeding,
        stalledUp,
      ], query);

      // Then
      expect(
        results.map((torrent) => torrent.name),
        unorderedEquals(['Downloading', 'Stalled', 'Queued', 'Checking']),
      );
    });
  });
}

Torrent _torrent({
  required String name,
  TorrentStatus status = TorrentStatus.downloading,
  int addedOn = 0,
  double progress = 0,
  int size = 0,
  int dlspeed = 0,
  double ratio = 0,
  int seedingTime = 0,
  String? category,
  List<String> tags = const [],
}) {
  return Torrent(
    hash: name,
    name: name,
    size: size,
    progress: progress,
    dlspeed: dlspeed,
    upspeed: 0,
    eta: -1,
    ratio: ratio,
    status: status,
    state: status.name,
    category: category,
    tags: tags,
    savePath: '',
    numSeeds: 0,
    numLeechs: 0,
    downloaded: 0,
    uploaded: 0,
    amountLeft: 0,
    addedOn: addedOn,
    priority: 0,
    seedingTime: seedingTime,
  );
}
