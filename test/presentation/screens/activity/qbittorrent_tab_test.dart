import 'package:arrmate/data/api/qbittorrent_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/screens/activity/providers/qbittorrent_provider.dart';
import 'package:arrmate/presentation/screens/activity/qbittorrent_tab.dart';
import 'package:arrmate/presentation/screens/activity/widgets/torrent_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockQBittorrentService extends Mock implements QBittorrentService {}

class _StaticTorrentsNotifier extends QBittorrentNotifier {
  final List<Torrent> torrents;

  /// Every `deleteTorrents` call, as `hashes|deleteFiles`.
  final List<String> deletions = [];

  _StaticTorrentsNotifier(this.torrents);

  @override
  Future<List<Torrent>> build() async => torrents;

  @override
  Future<void> deleteTorrents(
    List<String> hashes, {
    bool deleteFiles = false,
  }) async {
    deletions.add('${hashes.join(',')}|$deleteFiles');
  }
}

const _twentyOneDays = 21 * 86400;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('should show the visible and hidden torrent counts', (
    tester,
  ) async {
    // Given
    final torrents = [
      _torrent(name: 'Alpha', status: TorrentStatus.pausedDL),
      _torrent(name: 'Bravo', status: TorrentStatus.uploading),
      _torrent(name: 'Charlie', status: TorrentStatus.downloading),
    ];

    // When
    await _pumpTab(tester, torrents);

    // Then
    expect(find.byKey(const Key('torrentResultCount')), findsOneWidget);
    expect(find.text('3 torrents'), findsOneWidget);
  });

  testWidgets('should sort by name when the option is selected', (
    tester,
  ) async {
    // Given
    final torrents = [
      _torrent(name: 'Bravo', status: TorrentStatus.downloading),
      _torrent(name: 'Charlie', status: TorrentStatus.downloading),
      _torrent(name: 'Alpha', status: TorrentStatus.pausedDL),
    ];
    await _pumpTab(tester, torrents);
    expect(_renderedNames(tester), ['Bravo', 'Charlie', 'Alpha']);

    // When
    await tester.tap(find.byKey(const Key('torrentSortButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('torrentSortDirectionButton')));
    await tester.pumpAndSettle();

    // Then
    expect(_renderedNames(tester), ['Alpha', 'Bravo', 'Charlie']);
  });

  testWidgets('should apply the paused filter from the filters sheet', (
    tester,
  ) async {
    // Given
    final torrents = [
      _torrent(name: 'Alpha', status: TorrentStatus.pausedDL),
      _torrent(name: 'Bravo', status: TorrentStatus.uploading),
      _torrent(name: 'Charlie', status: TorrentStatus.downloading),
    ];
    await _pumpTab(tester, torrents);

    // When
    await tester.tap(find.byKey(const Key('torrentFilterButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Paused'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('applyTorrentFiltersButton')));
    await tester.pumpAndSettle();

    // Then
    expect(_renderedNames(tester), ['Alpha']);
    expect(find.text('1 torrents · 2 hidden'), findsOneWidget);
    expect(find.byKey(const Key('clearTorrentFiltersButton')), findsOneWidget);
  });

  testWidgets('should apply the tag filter from the filters sheet', (
    tester,
  ) async {
    // Given
    final torrents = [
      _torrent(name: 'Alpha', status: TorrentStatus.pausedDL, tags: ['movies']),
      _torrent(name: 'Bravo', status: TorrentStatus.uploading),
      _torrent(
        name: 'Charlie',
        status: TorrentStatus.downloading,
        tags: ['series'],
      ),
    ];
    await _pumpTab(tester, torrents);

    // When
    await tester.tap(find.byKey(const Key('torrentFilterButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'movies'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('applyTorrentFiltersButton')));
    await tester.pumpAndSettle();

    // Then
    expect(_renderedNames(tester), ['Alpha']);
    expect(find.text('1 torrents · 2 hidden'), findsOneWidget);
    expect(find.byKey(const Key('clearTorrentFiltersButton')), findsOneWidget);
  });

  testWidgets('should apply the category filter from the filters sheet', (
    tester,
  ) async {
    // Given
    final torrents = [
      _torrent(
        name: 'Alpha',
        status: TorrentStatus.pausedDL,
        category: 'movies',
      ),
      _torrent(name: 'Bravo', status: TorrentStatus.uploading),
      _torrent(
        name: 'Charlie',
        status: TorrentStatus.downloading,
        category: 'series',
      ),
    ];
    await _pumpTab(tester, torrents);

    // When
    await tester.tap(find.byKey(const Key('torrentFilterButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'movies'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('applyTorrentFiltersButton')));
    await tester.pumpAndSettle();

    // Then
    expect(_renderedNames(tester), ['Alpha']);
    expect(find.text('1 torrents · 2 hidden'), findsOneWidget);
    expect(find.byKey(const Key('clearTorrentFiltersButton')), findsOneWidget);
  });

  testWidgets('should show category and tag chips on the torrent card', (
    tester,
  ) async {
    // Given
    final torrents = [
      _torrent(
        name: 'Alpha',
        status: TorrentStatus.pausedDL,
        category: 'radarr',
        tags: ['movies', '4k'],
      ),
      _torrent(name: 'Bravo', status: TorrentStatus.uploading),
    ];

    // When
    await _pumpTab(tester, torrents);

    // Then
    expect(find.byKey(const Key('torrent-category-radarr')), findsOneWidget);
    expect(find.byKey(const Key('torrent-tag-movies')), findsOneWidget);
    expect(find.byKey(const Key('torrent-tag-4k')), findsOneWidget);
  });

  testWidgets('should restore every torrent when filters are cleared', (
    tester,
  ) async {
    // Given
    final torrents = [
      _torrent(name: 'Alpha', status: TorrentStatus.pausedDL),
      _torrent(name: 'Bravo', status: TorrentStatus.uploading),
    ];
    await _pumpTab(tester, torrents);
    await tester.tap(find.byKey(const Key('torrentFilterButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Paused'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('applyTorrentFiltersButton')));
    await tester.pumpAndSettle();
    expect(_renderedNames(tester), ['Alpha']);

    // When
    await tester.tap(find.byKey(const Key('clearTorrentFiltersButton')));
    await tester.pumpAndSettle();

    // Then
    expect(_renderedNames(tester), ['Bravo', 'Alpha']);
    expect(find.text('2 torrents'), findsOneWidget);
  });

  testWidgets('should filter by the search query', (tester) async {
    // Given
    final torrents = [
      _torrent(name: 'Alpha', status: TorrentStatus.downloading),
      _torrent(name: 'Bravo', status: TorrentStatus.downloading),
    ];
    await _pumpTab(tester, torrents);

    // When
    await tester.enterText(
      find.byKey(const Key('torrentSearchField')),
      'bravo',
    );
    await tester.pumpAndSettle();

    // Then
    expect(_renderedNames(tester), ['Bravo']);
    expect(find.text('1 torrents · 1 hidden'), findsOneWidget);
  });

  testWidgets(
    'should show the empty state message when filters match nothing',
    (tester) async {
      // Given
      final torrents = [
        _torrent(name: 'Alpha', status: TorrentStatus.uploading),
      ];
      await _pumpTab(tester, torrents);
      await tester.tap(find.byKey(const Key('torrentFilterButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Paused'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('applyTorrentFiltersButton')));
      await tester.pumpAndSettle();

      // When
      final showsMessage = find.text('No torrents match the current filters');

      // Then
      expect(showsMessage, findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);
      expect(find.byType(TorrentListItem), findsNothing);
    },
  );

  group('bulk delete', () {
    testWidgets('should enter selection mode on long press', (tester) async {
      // Given
      final torrents = [
        _torrent(name: 'Alpha', status: TorrentStatus.pausedUP),
        _torrent(name: 'Bravo', status: TorrentStatus.pausedUP),
      ];
      await _pumpTab(tester, torrents);

      // When
      await tester.longPress(find.text('Alpha'));
      await tester.pumpAndSettle();

      // Then
      expect(find.byKey(const Key('torrentSelectionHeader')), findsOneWidget);
      expect(find.byKey(const Key('torrentSearchField')), findsNothing);
      expect(find.text('1 selected'), findsNWidgets(2));
      expect(find.text('Delete with files'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('should toggle selection on tap while selecting', (
      tester,
    ) async {
      // Given
      final torrents = [
        _torrent(name: 'Alpha', status: TorrentStatus.pausedUP),
        _torrent(name: 'Bravo', status: TorrentStatus.pausedUP),
      ];
      await _pumpTab(tester, torrents);
      await tester.longPress(find.text('Alpha'));
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.text('Bravo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('1 selected'), findsNWidgets(2));
      expect(_selectedNames(tester), ['Bravo']);
    });

    testWidgets('should select only the visible torrents on select all', (
      tester,
    ) async {
      // Given
      final torrents = [
        _torrent(name: 'Alpha', status: TorrentStatus.pausedDL),
        _torrent(name: 'Bravo', status: TorrentStatus.uploading),
        _torrent(name: 'Charlie', status: TorrentStatus.pausedUP),
      ];
      await _pumpTab(tester, torrents);
      await tester.tap(find.byKey(const Key('torrentFilterButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Paused'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('applyTorrentFiltersButton')));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Alpha'));
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.byKey(const Key('torrentSelectAllButton')));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('2 selected'), findsNWidgets(2));
      expect(_selectedNames(tester), ['Alpha', 'Charlie']);
    });

    testWidgets('should delete the selected torrents with their files', (
      tester,
    ) async {
      // Given
      final torrents = [
        _torrent(
          name: 'Alpha',
          status: TorrentStatus.pausedUP,
          seedingTime: _twentyOneDays,
        ),
        _torrent(
          name: 'Bravo',
          status: TorrentStatus.pausedUP,
          seedingTime: _twentyOneDays,
        ),
        _torrent(name: 'Charlie', status: TorrentStatus.pausedUP),
      ];
      final notifier = await _pumpTab(tester, torrents);
      await tester.longPress(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bravo'));
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.text('Delete with files'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Torrents still seeding'), findsNothing);
      expect(notifier.deletions, ['Alpha,Bravo|true']);
      expect(find.text('Deleted 2 torrents and files'), findsOneWidget);
      expect(find.byKey(const Key('torrentSelectionHeader')), findsNothing);
    });

    testWidgets(
      'should keep torrents below the minimum seeding time when asked',
      (tester) async {
        // Given
        final torrents = [
          _torrent(
            name: 'Alpha',
            status: TorrentStatus.pausedUP,
            seedingTime: _twentyOneDays,
          ),
          _torrent(
            name: 'Bravo',
            status: TorrentStatus.uploading,
            seedingTime: 3600,
          ),
        ];
        final notifier = await _pumpTab(tester, torrents);
        await tester.longPress(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('torrentSelectAllButton')));
        await tester.pumpAndSettle();

        // When
        await tester.tap(find.text('Delete with files'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        expect(find.text('Torrents still seeding'), findsOneWidget);
        await tester.tap(find.text('Keep seeding'));
        await tester.pumpAndSettle();

        // Then
        expect(notifier.deletions, ['Alpha|true']);
        expect(
          find.text('Deleted 1 torrent and files (kept 1 still seeding)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should delete every torrent when the seeding warning is overridden',
      (tester) async {
        // Given
        final torrents = [
          _torrent(name: 'Alpha', status: TorrentStatus.uploading),
          _torrent(name: 'Bravo', status: TorrentStatus.uploading),
        ];
        final notifier = await _pumpTab(tester, torrents);
        await tester.longPress(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('torrentSelectAllButton')));
        await tester.pumpAndSettle();

        // When
        await tester.tap(find.text('Delete with files'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete all'));
        await tester.pumpAndSettle();

        // Then
        expect(notifier.deletions, ['Alpha,Bravo|true']);
      },
    );

    testWidgets('should delete nothing when the seeding warning is cancelled', (
      tester,
    ) async {
      // Given
      final torrents = [
        _torrent(name: 'Alpha', status: TorrentStatus.uploading),
      ];
      final notifier = await _pumpTab(tester, torrents);
      await tester.longPress(find.text('Alpha'));
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.text('Delete with files'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Then
      expect(notifier.deletions, isEmpty);
    });
  });
}

Future<_StaticTorrentsNotifier> _pumpTab(
  WidgetTester tester,
  List<Torrent> torrents,
) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final notifier = _StaticTorrentsNotifier(torrents);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        qbittorrentTorrentsProvider.overrideWith(() => notifier),
        qbittorrentServiceProvider.overrideWithValue(_MockQBittorrentService()),
      ],
      child: const MaterialApp(home: QBittorrentTab()),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

List<String> _selectedNames(WidgetTester tester) {
  return tester
      .widgetList<TorrentListItem>(find.byType(TorrentListItem))
      .where((item) => item.isSelected)
      .map((item) => item.torrent.name)
      .toList();
}

List<String> _renderedNames(WidgetTester tester) {
  return tester
      .widgetList<TorrentListItem>(find.byType(TorrentListItem))
      .map((item) => item.torrent.name)
      .toList();
}

Torrent _torrent({
  required String name,
  required TorrentStatus status,
  String? category,
  List<String> tags = const [],
  int seedingTime = 0,
}) {
  return Torrent(
    hash: name,
    name: name,
    size: 1024,
    progress: status == TorrentStatus.uploading ? 1 : 0.5,
    dlspeed: 0,
    upspeed: 0,
    eta: -1,
    ratio: 1,
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
    addedOn: 0,
    priority: 0,
    seedingTime: seedingTime,
  );
}
