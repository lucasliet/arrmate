import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/activity/providers/manual_import_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'should load and import files only through the queue item origin',
    () async {
      final home = _instance('radarr-home');
      final remote = _instance('radarr-remote');
      final homeRepository = MockMovieRepository();
      final remoteRepository = MockMovieRepository();
      const file = ImportableFile(id: 7, size: 1024);
      final item = _queueItem(remote);
      when(
        () => remoteRepository.getImportableFiles('shared-download'),
      ).thenAnswer((_) async => [file]);
      when(
        () => remoteRepository.manualImport([file]),
      ).thenAnswer((_) async {});
      _stubEmptyQueue(homeRepository);
      _stubEmptyQueue(remoteRepository);
      final container = ProviderContainer(
        overrides: [
          instancesByTypeProvider(
            InstanceType.radarr,
          ).overrideWithValue([home, remote]),
          instancesByTypeProvider(
            InstanceType.sonarr,
          ).overrideWithValue(const []),
          movieRepositoryForInstanceProvider(
            home,
          ).overrideWithValue(homeRepository),
          movieRepositoryForInstanceProvider(
            remote,
          ).overrideWithValue(remoteRepository),
        ],
      );
      addTearDown(container.dispose);

      final files = await container.read(
        manualImportFilesProvider(item).future,
      );
      await container
          .read(manualImportControllerProvider(item))
          .importFiles(files);

      expect(files, [file]);
      verify(
        () => remoteRepository.getImportableFiles('shared-download'),
      ).called(1);
      verify(() => remoteRepository.manualImport([file])).called(1);
      verifyNever(() => homeRepository.getImportableFiles(any()));
      verifyNever(() => homeRepository.manualImport(any()));
    },
  );
}

void _stubEmptyQueue(MockMovieRepository repository) {
  when(() => repository.getQueue(page: 1, pageSize: 100)).thenAnswer(
    (_) async => const QueueItems(
      page: 1,
      pageSize: 100,
      sortKey: '',
      sortDirection: '',
      totalRecords: 0,
      records: [],
    ),
  );
}

Instance _instance(String id) {
  return Instance(
    id: id,
    type: InstanceType.radarr,
    label: id,
    url: 'https://$id.example.com',
    apiKey: 'key',
  );
}

QueueItem _queueItem(Instance instance) {
  return QueueItem(
    id: 42,
    instanceId: instance.id,
    instanceType: instance.type,
    movieId: 7,
    title: 'Movie',
    status: QueueStatus.warning,
    downloadId: 'shared-download',
    protocol: 'torrent',
    sizeleft: 0,
  );
}
