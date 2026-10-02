import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instance_tags_provider.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/movies/movie_edit_screen.dart';
import 'package:arrmate/presentation/tour/tour_mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMovieRepository extends Mock implements MovieRepository {}

void main() {
  testWidgets('offers tags fetched from the server, not only the snapshot', (
    tester,
  ) async {
    final repository = _MockMovieRepository();
    when(
      () => repository.getQualityProfiles(),
    ).thenAnswer((_) async => const [QualityProfile(id: 1, name: 'HD-1080p')]);
    when(
      () => repository.getRootFolders(),
    ).thenAnswer((_) async => const [RootFolder(id: 1, path: '/movies')]);
    final instance = Instance(
      id: 'radarr-lab',
      tags: const [Tag(id: 1, label: 'lab')],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentRadarrInstanceProvider.overrideWithValue(instance),
          movieRepositoryProvider.overrideWithValue(repository),
          instanceTagsProvider.overrideWith(
            (ref, _) async => const [
              Tag(id: 1, label: 'lab'),
              Tag(id: 2, label: '4k'),
            ],
          ),
        ],
        child: MaterialApp(
          home: MovieEditScreen(
            movie: TourMockData.movies().first.copyWith(
              rootFolderPath: '/movies',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('lab'), findsOneWidget);
    expect(find.text('4k'), findsOneWidget);
  });
}
