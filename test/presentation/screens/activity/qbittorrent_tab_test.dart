import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/screens/activity/providers/qbittorrent_provider.dart';
import 'package:arrmate/presentation/screens/activity/qbittorrent_tab.dart';
import 'package:arrmate/presentation/screens/activity/widgets/torrent_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StaticTorrentsNotifier extends QBittorrentNotifier {
  final List<Torrent> torrents;

  _StaticTorrentsNotifier(this.torrents);

  @override
  Future<List<Torrent>> build() async => torrents;
}

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
}

Future<void> _pumpTab(WidgetTester tester, List<Torrent> torrents) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        qbittorrentTorrentsProvider.overrideWith(
          () => _StaticTorrentsNotifier(torrents),
        ),
      ],
      child: const MaterialApp(home: QBittorrentTab()),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _renderedNames(WidgetTester tester) {
  return tester
      .widgetList<TorrentListItem>(find.byType(TorrentListItem))
      .map((item) => item.torrent.name)
      .toList();
}

Torrent _torrent({required String name, required TorrentStatus status}) {
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
    tags: const [],
    savePath: '',
    numSeeds: 0,
    numLeechs: 0,
    downloaded: 0,
    uploaded: 0,
    amountLeft: 0,
    addedOn: 0,
    priority: 0,
  );
}
