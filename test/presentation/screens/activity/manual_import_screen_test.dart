import 'package:arrmate/core/network/api_error.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/activity/manual_import_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMovieRepository repository;

  setUpAll(() {
    registerFallbackValue(const <ImportableFile>[]);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockMovieRepository();
    when(
      () => repository.getImportableFiles('shared-download'),
    ).thenAnswer((_) async => const [_file]);
  });

  Future<void> openAndSelect(WidgetTester tester) async {
    await tester.pumpWidget(_host(repository));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
  }

  group('Manual import screen', () {
    testWidgets('should stay open when the import is refused', (tester) async {
      // Given
      // Closing the sheet would throw away the selection the user built, and
      // a refused import is exactly the case they have to go back and fix.
      when(
        () => repository.manualImport(any()),
      ).thenThrow(const MissingDataError('No movie is linked to Movie.mkv'));

      // When
      await openAndSelect(tester);

      // Then
      expect(find.text('Manual Import'), findsOneWidget);
      expect(find.text('1 file(s) selected'), findsOneWidget);
    });

    testWidgets('should report the refusal without leaking the error type', (
      tester,
    ) async {
      // Given
      when(
        () => repository.manualImport(any()),
      ).thenThrow(const MissingDataError('No movie is linked to Movie.mkv'));

      // When
      await openAndSelect(tester);

      // Then
      expect(
        find.text('Failed to import: No movie is linked to Movie.mkv'),
        findsOneWidget,
      );
    });

    testWidgets('should close the sheet once the import goes through', (
      tester,
    ) async {
      // Given
      when(() => repository.manualImport(any())).thenAnswer((_) async {});

      // When
      await openAndSelect(tester);

      // Then
      expect(find.text('Manual Import'), findsNothing);
      expect(find.text('1 file(s) imported successfully'), findsOneWidget);
    });
  });
}

const _file = ImportableFile(id: 7, name: 'Movie.mkv', size: 1024);

final _instance = Instance(
  id: 'radarr',
  type: InstanceType.radarr,
  label: 'Radarr',
  url: 'https://radarr.example.com',
  apiKey: 'key',
);

final _queueItem = QueueItem(
  id: 42,
  instanceId: _instance.id,
  instanceType: _instance.type,
  movieId: 7,
  title: 'Movie',
  status: QueueStatus.warning,
  downloadId: 'shared-download',
  protocol: 'torrent',
  sizeleft: 0,
);

Widget _host(MovieRepository repository) {
  return ProviderScope(
    overrides: [
      instancesByTypeProvider(
        InstanceType.radarr,
      ).overrideWithValue([_instance]),
      instancesByTypeProvider(InstanceType.sonarr).overrideWithValue(const []),
      movieRepositoryForInstanceProvider(
        _instance,
      ).overrideWithValue(repository),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ManualImportScreen(item: _queueItem),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}
