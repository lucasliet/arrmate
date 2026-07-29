import 'package:arrmate/core/services/media_add_defaults_store.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('should persist movie defaults independently per instance', () async {
    // Given
    final store = MediaAddDefaultsStore();
    const first = MovieAddDefaults(
      monitor: MovieMonitorType.movieAndCollection,
      minimumAvailability: MovieStatus.released,
      qualityProfileId: 4,
      rootFolderPath: '/movies',
      tags: [1, 2],
    );

    // When
    await store.saveMovie('radarr-a', first);
    final loadedFirst = await store.loadMovie('radarr-a');
    final loadedSecond = await store.loadMovie('radarr-b');

    // Then
    expect(loadedFirst.monitor, MovieMonitorType.movieAndCollection);
    expect(loadedFirst.minimumAvailability, MovieStatus.released);
    expect(loadedFirst.qualityProfileId, 4);
    expect(loadedFirst.rootFolderPath, '/movies');
    expect(loadedFirst.tags, [1, 2]);
    expect(loadedSecond.monitor, MovieMonitorType.movieOnly);
    expect(loadedSecond.qualityProfileId, isNull);
  });

  test('should persist every series addition option', () async {
    // Given
    final store = MediaAddDefaultsStore();
    const defaults = SeriesAddDefaults(
      monitor: SeriesMonitorType.future,
      monitorNewItems: SeriesMonitorNewItems.all,
      seriesType: SeriesType.anime,
      seasonFolder: false,
      qualityProfileId: 7,
      rootFolderPath: '/anime',
      tags: [8],
    );

    // When
    await store.saveSeries('sonarr-a', defaults);
    final loaded = await store.loadSeries('sonarr-a');

    // Then
    expect(loaded.monitor, SeriesMonitorType.future);
    expect(loaded.monitorNewItems, SeriesMonitorNewItems.all);
    expect(loaded.seriesType, SeriesType.anime);
    expect(loaded.seasonFolder, isFalse);
    expect(loaded.qualityProfileId, 7);
    expect(loaded.rootFolderPath, '/anime');
    expect(loaded.tags, [8]);
  });
}
