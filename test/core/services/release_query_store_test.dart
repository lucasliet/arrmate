import 'package:arrmate/core/services/release_query_store.dart';
import 'package:arrmate/domain/models/shared/release_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('should persist movie and series queries independently', () async {
    // Given
    final store = ReleaseQueryStore();
    const movieQuery = ReleaseQuery(search: 'movie');
    const seriesQuery = ReleaseQuery(search: 'series');

    // When
    await store.save(isMovie: true, query: movieQuery, remember: true);
    await store.save(isMovie: false, query: seriesQuery, remember: true);
    final savedMovie = await store.load(isMovie: true);
    final savedSeries = await store.load(isMovie: false);

    // Then
    expect(savedMovie.query, movieQuery);
    expect(savedMovie.remember, isTrue);
    expect(savedSeries.query, seriesQuery);
    expect(savedSeries.remember, isTrue);
  });

  test('should clear the stored query when remembering is disabled', () async {
    // Given
    final store = ReleaseQueryStore();
    const query = ReleaseQuery(search: 'temporary');
    await store.save(isMovie: true, query: query, remember: true);

    // When
    await store.save(isMovie: true, query: query, remember: false);
    final saved = await store.load(isMovie: true);

    // Then
    expect(saved.query, const ReleaseQuery());
    expect(saved.remember, isFalse);
  });
}
