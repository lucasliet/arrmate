import 'dart:async';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instance_tags_provider.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/series/series_edit_screen.dart';
import 'package:arrmate/presentation/tour/tour_mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSeriesRepository extends Mock implements SeriesRepository {}

void main() {
  testWidgets('keeps configuration loaded when live tags or edits rebuild', (
    tester,
  ) async {
    final repository = _MockSeriesRepository();
    when(
      () => repository.getQualityProfiles(),
    ).thenAnswer((_) async => const [QualityProfile(id: 1, name: 'HD-1080p')]);
    when(
      () => repository.getRootFolders(),
    ).thenAnswer((_) async => const [RootFolder(id: 1, path: '/tv')]);
    final liveTags = Completer<List<Tag>>();
    final instance = Instance(
      id: 'sonarr-lab',
      type: InstanceType.sonarr,
      tags: const [Tag(id: 1, label: 'lab')],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSonarrInstanceProvider.overrideWithValue(instance),
          seriesRepositoryProvider.overrideWithValue(repository),
          instanceTagsProvider.overrideWith((ref, _) => liveTags.future),
        ],
        child: MaterialApp(
          home: SeriesEditScreen(
            series: TourMockData.series().first.copyWith(
              qualityProfileId: 1,
              rootFolderPath: '/tv',
              tags: [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    liveTags.complete(const [
      Tag(id: 1, label: 'lab'),
      Tag(id: 2, label: '4k'),
    ]);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Monitored'));
    await tester.pumpAndSettle();
    final tag = find.widgetWithText(CheckboxListTile, '4k');
    await tester.scrollUntilVisible(tag, 200);
    await tester.tap(tag);
    await tester.pumpAndSettle();

    expect(tester.widget<CheckboxListTile>(tag).value, isTrue);
    expect(find.text('lab'), findsOneWidget);
    verify(() => repository.getQualityProfiles()).called(1);
    verify(() => repository.getRootFolders()).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reloads configuration when the server repository changes', (
    tester,
  ) async {
    final firstRepository = _MockSeriesRepository();
    final secondRepository = _MockSeriesRepository();
    for (final repository in [firstRepository, secondRepository]) {
      when(() => repository.getQualityProfiles()).thenAnswer(
        (_) async => [
          QualityProfile(
            id: 1,
            name: identical(repository, firstRepository)
                ? 'HD-1080p'
                : 'Ultra-HD',
          ),
        ],
      );
      when(
        () => repository.getRootFolders(),
      ).thenAnswer((_) async => const [RootFolder(id: 1, path: '/tv')]);
    }
    final container = ProviderContainer(
      overrides: [
        currentSonarrInstanceProvider.overrideWithValue(null),
        seriesRepositoryProvider.overrideWithValue(firstRepository),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: SeriesEditScreen(
            series: TourMockData.series().first.copyWith(
              qualityProfileId: 1,
              rootFolderPath: '/tv',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('HD-1080p'), findsWidgets);

    container.updateOverrides([
      currentSonarrInstanceProvider.overrideWithValue(null),
      seriesRepositoryProvider.overrideWithValue(secondRepository),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Ultra-HD'), findsWidgets);
    expect(find.text('HD-1080p'), findsNothing);
    for (final repository in [firstRepository, secondRepository]) {
      verify(() => repository.getQualityProfiles()).called(1);
      verify(() => repository.getRootFolders()).called(1);
    }
    expect(tester.takeException(), isNull);
  });
}
