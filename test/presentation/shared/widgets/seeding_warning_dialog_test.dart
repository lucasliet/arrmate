import 'package:arrmate/core/services/purge_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/shared/widgets/seeding_warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_app.dart';

void main() {
  group('resolveSharedPackApprovals', () {
    testWidgets('should return only the packs the user approved', (
      tester,
    ) async {
      // Given two packs, the first one listed twice
      final candidates = [
        _torrent(hash: 'AABB', name: 'Show.Complete.1080p'),
        _torrent(hash: 'aabb', name: 'Show.Complete.1080p'),
        _torrent(hash: 'CCDD', name: 'Show.S01-S03.720p'),
      ];
      final result = await _run(
        tester,
        (context) => resolveSharedPackApprovals(
          context: context,
          sharedPackCandidates: candidates,
        ),
      );

      // When the first pack is approved
      expect(find.text('Multi-season pack found'), findsOneWidget);
      expect(
        find.textContaining('also holds episodes from seasons'),
        findsOneWidget,
      );
      expect(find.text('Show.Complete.1080p'), findsOneWidget);
      await tester.tap(find.text('Delete torrent'));
      await tester.pumpAndSettle();

      // And the second one is kept
      expect(find.text('Show.S01-S03.720p'), findsOneWidget);
      await tester.tap(find.text('Keep torrent'));
      await tester.pumpAndSettle();

      // Then the duplicate hash is asked once and only the approval counts
      expect(find.byType(AlertDialog), findsNothing);
      expect(await result, {'aabb'});
    });

    testWidgets('should not ask anything without candidates', (tester) async {
      final result = await _run(
        tester,
        (context) => resolveSharedPackApprovals(
          context: context,
          sharedPackCandidates: const [],
        ),
      );

      expect(find.byType(AlertDialog), findsNothing);
      expect(await result, isEmpty);
    });
  });

  group('what Keep seeding keeps', () {
    testWidgets('should not ask about a cross-seed it will keep anyway', (
      tester,
    ) async {
      // Given a copy that seeded for 10 minutes and a 1 hour minimum
      final result = await _run(
        tester,
        (context) => resolveCrossSeedApprovals(
          context: context,
          crossSeedCandidates: [
            _torrent(hash: 'YOUNG', name: 'Arrival.2016', seedingTime: 600),
          ],
          action: SeedingAction.keepBelowThreshold,
          minimumSeedingSeconds: 3600,
        ),
      );

      // Then there is nothing to approve, so no dialog opens
      expect(find.byType(AlertDialog), findsNothing);
      expect(await result, isEmpty);
    });

    testWidgets('should still ask about the copies that seeded long enough', (
      tester,
    ) async {
      final result = await _run(
        tester,
        (context) => resolveCrossSeedApprovals(
          context: context,
          crossSeedCandidates: [
            _torrent(hash: 'YOUNG', name: 'Young.Copy', seedingTime: 600),
            _torrent(hash: 'OLD', name: 'Old.Copy', seedingTime: 7200),
          ],
          action: SeedingAction.keepBelowThreshold,
          minimumSeedingSeconds: 3600,
        ),
      );

      expect(find.text('Old.Copy'), findsOneWidget);
      expect(find.text('Young.Copy'), findsNothing);
      await tester.tap(find.text('Delete torrent'));
      await tester.pumpAndSettle();

      expect(await result, {'old'});
    });

    testWidgets('should ask about everything under Delete all', (tester) async {
      final result = await _run(
        tester,
        (context) => resolveCrossSeedApprovals(
          context: context,
          crossSeedCandidates: [
            _torrent(hash: 'YOUNG', name: 'Young.Copy', seedingTime: 600),
          ],
          minimumSeedingSeconds: 3600,
        ),
      );

      expect(find.text('Young.Copy'), findsOneWidget);
      await tester.tap(find.text('Delete torrent'));
      await tester.pumpAndSettle();

      expect(await result, {'young'});
    });

    testWidgets('should not ask about a multi-season pack it will keep', (
      tester,
    ) async {
      final result = await _run(
        tester,
        (context) => resolveSharedPackApprovals(
          context: context,
          sharedPackCandidates: [
            _torrent(hash: 'PACK', name: 'Show.Complete', seedingTime: 600),
          ],
          action: SeedingAction.keepBelowThreshold,
          minimumSeedingSeconds: 3600,
        ),
      );

      expect(find.byType(AlertDialog), findsNothing);
      expect(await result, isEmpty);
    });
  });

  group('resolveCrossSeedApprovals', () {
    testWidgets('should keep asking with the cross-seed wording', (
      tester,
    ) async {
      final result = await _run(
        tester,
        (context) => resolveCrossSeedApprovals(
          context: context,
          crossSeedCandidates: [
            _torrent(hash: 'EEFF', name: 'Arrival.2016.1080p'),
          ],
        ),
      );

      expect(find.text('Cross-seed torrent found'), findsOneWidget);
      await tester.tap(find.text('Delete torrent'));
      await tester.pumpAndSettle();

      expect(await result, {'eeff'});
    });
  });
}

/// Pumps an app, starts [resolve] from inside it and lets the first dialog
/// open. The returned future completes once every dialog is answered.
Future<Future<Set<String>>> _run(
  WidgetTester tester,
  Future<Set<String>> Function(BuildContext context) resolve,
) async {
  late BuildContext appContext;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      locale: testLocale,
      home: Builder(
        builder: (context) {
          appContext = context;
          return const SizedBox();
        },
      ),
    ),
  );
  final result = resolve(appContext);
  await tester.pumpAndSettle();
  return result;
}

Torrent _torrent({
  required String hash,
  required String name,
  int seedingTime = 0,
}) {
  return Torrent(
    hash: hash,
    name: name,
    size: 1000,
    progress: 1.0,
    dlspeed: 0,
    upspeed: 0,
    eta: 0,
    ratio: 1,
    status: TorrentStatus.uploading,
    state: 'uploading',
    tags: const [],
    savePath: '/downloads',
    numSeeds: 1,
    numLeechs: 0,
    downloaded: 1000,
    uploaded: 1000,
    amountLeft: 0,
    addedOn: 1700000000,
    priority: 0,
    seedingTime: seedingTime,
  );
}
