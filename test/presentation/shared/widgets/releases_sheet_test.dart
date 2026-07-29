import 'package:arrmate/domain/models/shared/release.dart';
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
}

Release _release({
  required bool rejected,
  String title = 'Example.Movie.2020.1080p',
  List<String>? rejections,
}) {
  return Release(
    guid: 'release-guid',
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
