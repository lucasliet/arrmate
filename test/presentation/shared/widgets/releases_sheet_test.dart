import 'dart:convert';
import 'dart:async';

import 'package:arrmate/core/services/release_query_store.dart';
import 'package:arrmate/domain/models/shared/release.dart';
import 'package:arrmate/domain/models/shared/release_query.dart';
import 'package:arrmate/presentation/shared/providers/releases_provider.dart';
import 'package:arrmate/presentation/shared/widgets/releases_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('should disable every download action for a rejected release', (
    tester,
  ) async {
    // Given
    final release = _release(rejected: true);

    // When
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movieReleasesProvider(1).overrideWith((ref) async => [release]),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ReleasesSheet(id: 1, isMovie: true, title: 'Example Movie'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Then
    final downloadButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download),
    );
    final releaseTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, release.title),
    );
    expect(downloadButton.onPressed, isNull);
    expect(releaseTile.onTap, isNull);
    expect(releaseTile.enabled, isFalse);
  });

  testWidgets('should search releases and show the hidden result count', (
    tester,
  ) async {
    // Given
    final matching = _release(
      rejected: false,
      title: 'Example.Movie.2020.HEVC',
    );
    final hidden = _release(rejected: false, title: 'Example.Movie.2020.H264');

    // When
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movieReleasesProvider(
            1,
          ).overrideWith((ref) async => [matching, hidden]),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ReleasesSheet(id: 1, isMovie: true, title: 'Example Movie'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('releaseSearchField')), 'HEVC');
    await tester.pump();

    // Then
    expect(find.text(matching.title), findsOneWidget);
    expect(find.text(hidden.title), findsNothing);
    expect(find.text('1 results · 1 hidden'), findsOneWidget);
  });

  testWidgets('should expose all rejection reasons in release details', (
    tester,
  ) async {
    // Given
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final release = _release(
      rejected: true,
      rejections: const ['Wrong quality', 'Not enough seeders'],
    );

    // When
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movieReleasesProvider(1).overrideWith((ref) async => [release]),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const ReleasesSheet(
                    id: 1,
                    isMovie: true,
                    title: 'Example Movie',
                  ),
                ),
                child: const Text('Open releases'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open releases'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    // Then
    expect(find.text('Wrong quality'), findsWidgets);
    expect(find.text('Not enough seeders'), findsOneWidget);
    final downloadButton = tester.widget<FilledButton>(
      find.byKey(const Key('releaseDetailsDownloadButton')),
    );
    expect(downloadButton.onPressed, isNull);
  });

  testWidgets(
    'should hide an unavailable remembered original language filter',
    (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({
        'remember_movie_release_query': true,
        'movie_release_query': jsonEncode(
          const ReleaseQuery(originalLanguageOnly: true).toJson(),
        ),
      });
      final release = _release(rejected: false);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieReleasesProvider(1).overrideWith((ref) async => [release]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ReleasesSheet(id: 1, isMovie: true, title: 'Example Movie'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      final badge = tester.widget<Badge>(
        find.descendant(
          of: find.byKey(const Key('releaseFilterButton')),
          matching: find.byType(Badge),
        ),
      );
      expect(badge.isLabelVisible, isFalse);
      expect(find.byKey(const Key('clearReleaseFiltersButton')), findsNothing);
      expect(find.text(release.title), findsOneWidget);
      expect(find.text('1 results'), findsOneWidget);
    },
  );

  testWidgets(
    'should preserve edits made before saved filters finish loading',
    (tester) async {
      // Given
      final loadCompleter = Completer<SavedReleaseQuery>();
      final matching = _release(rejected: false, title: 'Movie.HEVC');
      final persistedMatch = _release(rejected: false, title: 'Movie.H264');
      final store = _DelayedReleaseQueryStore(loadCompleter.future);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieReleasesProvider(
              1,
            ).overrideWith((ref) async => [matching, persistedMatch]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReleasesSheet(
                id: 1,
                isMovie: true,
                title: 'Example Movie',
                queryStore: store,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('releaseSearchField')),
        'HEVC',
      );
      loadCompleter.complete(
        const SavedReleaseQuery(
          query: ReleaseQuery(search: 'H264'),
          remember: true,
        ),
      );
      await tester.pumpAndSettle();

      // Then
      final searchField = tester.widget<TextField>(
        find.byKey(const Key('releaseSearchField')),
      );
      expect(searchField.controller?.text, 'HEVC');
      expect(find.text(matching.title), findsOneWidget);
      expect(find.text(persistedMatch.title), findsNothing);
      expect(store.savedQuery, const ReleaseQuery(search: 'HEVC'));
      expect(store.savedRemember, isTrue);
      await tester.tap(find.byKey(const Key('releaseFilterButton')));
      await tester.pumpAndSettle();
      final rememberSwitch = tester.widget<SwitchListTile>(
        find.byKey(const Key('rememberReleaseFiltersSwitch')),
      );
      expect(rememberSwitch.value, isTrue);
    },
  );

  testWidgets('should show progress on the release being grabbed', (
    tester,
  ) async {
    // Given
    final grab = Completer<void>();
    final release = _release(rejected: false);

    // When
    await tester.pumpWidget(
      _sheetUnderTest(releases: [release], grab: grab.future),
    );
    await tester.pumpAndSettle();
    await _confirmDownloadOf(tester, release);

    // Then
    expect(find.byKey(const Key('releaseGrabProgress')), findsOneWidget);
    expect(find.byIcon(Icons.download), findsNothing);
  });

  testWidgets('should block a second grab while one is still running', (
    tester,
  ) async {
    // Given
    final grab = Completer<void>();
    final grabbed = _release(
      rejected: false,
      title: 'Example.Movie.2020.HEVC',
      guid: 'grabbed-guid',
    );
    final other = _release(
      rejected: false,
      title: 'Example.Movie.2020.H264',
      guid: 'other-guid',
    );

    // When
    await tester.pumpWidget(
      _sheetUnderTest(releases: [grabbed, other], grab: grab.future),
    );
    await tester.pumpAndSettle();
    await _confirmDownloadOf(tester, grabbed);

    // Then
    final otherButton = tester.widget<IconButton>(
      find.descendant(
        of: find.widgetWithText(ListTile, other.title),
        matching: find.widgetWithIcon(IconButton, Icons.download),
      ),
    );
    expect(otherButton.onPressed, isNull);
  });

  testWidgets('should restore the download action when a grab fails', (
    tester,
  ) async {
    // Given
    final grab = Completer<void>();
    final release = _release(rejected: false);

    // When
    await tester.pumpWidget(
      _sheetUnderTest(releases: [release], grab: grab.future),
    );
    await tester.pumpAndSettle();
    await _confirmDownloadOf(tester, release);
    grab.completeError(Exception('indexer is down'));
    await tester.pump();
    await tester.pump();

    // Then
    expect(find.byKey(const Key('releaseGrabProgress')), findsNothing);
    expect(
      find.text('Error grabbing release: Exception: indexer is down'),
      findsOneWidget,
    );
    final downloadButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download),
    );
    expect(downloadButton.onPressed, isNotNull);
  });
}

/// Builds a sheet whose grab completes only when [grab] does, so the in-flight
/// state stays observable.
Widget _sheetUnderTest({
  required List<Release> releases,
  required Future<void> grab,
}) {
  return ProviderScope(
    overrides: [
      movieReleasesProvider(1).overrideWith((ref) async => releases),
      releaseActionsProvider.overrideWith(() => _PendingReleaseActions(grab)),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: ReleasesSheet(id: 1, isMovie: true, title: 'Example Movie'),
      ),
    ),
  );
}

/// Taps the download action of [release] and confirms the dialog, leaving the
/// grab in flight.
Future<void> _confirmDownloadOf(WidgetTester tester, Release release) async {
  await tester.tap(
    find.descendant(
      of: find.widgetWithText(ListTile, release.title),
      matching: find.widgetWithIcon(IconButton, Icons.download),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Download'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

class _PendingReleaseActions extends ReleaseActions {
  final Future<void> pending;

  _PendingReleaseActions(this.pending);

  @override
  Future<void> downloadRelease({
    required String guid,
    required String indexerId,
    required bool isMovie,
  }) => pending;
}

class _DelayedReleaseQueryStore extends ReleaseQueryStore {
  final Future<SavedReleaseQuery> result;
  ReleaseQuery? savedQuery;
  bool? savedRemember;

  _DelayedReleaseQueryStore(this.result);

  @override
  Future<SavedReleaseQuery> load({required bool isMovie}) => result;

  @override
  Future<void> save({
    required bool isMovie,
    required ReleaseQuery query,
    required bool remember,
  }) async {
    savedQuery = query;
    savedRemember = remember;
  }
}

Release _release({
  required bool rejected,
  String title = 'Example.Movie.2020.1080p',
  String guid = 'release-guid',
  List<String>? rejections,
}) {
  return Release(
    guid: guid,
    title: title,
    size: 1024,
    link: '',
    indexer: 'Example Indexer',
    indexerId: '1',
    protocol: 'torrent',
    rejected: rejected,
    rejections:
        rejections ??
        (rejected ? const ['Release rejected by profile'] : const []),
    age: 1,
    quality: const ReleaseQuality(
      quality: ReleaseQualityItem(id: 1, name: 'HDTV-1080p'),
      revision: ReleaseQualityRevision(),
    ),
  );
}
