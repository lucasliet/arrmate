import 'dart:async';
import 'dart:convert';

import 'package:arrmate/core/services/release_query_store.dart';
import 'package:arrmate/domain/models/shared/release_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

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

  test('should absorb persistence failures when saving', () async {
    // Given
    final store = ReleaseQueryStore(
      preferencesLoader: () => Future<SharedPreferences>.error(
        StateError('Preferences unavailable'),
      ),
    );

    // When
    final save = store.save(
      isMovie: true,
      query: const ReleaseQuery(search: 'movie'),
      remember: true,
    );

    // Then
    await expectLater(save, completes);
  });

  test('should serialize saves in request order', () async {
    // Given
    final preferences = MockSharedPreferences();
    final firstWriteStarted = Completer<void>();
    final firstWriteGate = Completer<bool>();
    when(() => preferences.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => preferences.setString(any(), any())).thenAnswer((_) {
      firstWriteStarted.complete();
      return firstWriteGate.future;
    });
    when(() => preferences.remove(any())).thenAnswer((_) async => true);
    final store = ReleaseQueryStore(preferencesLoader: () async => preferences);

    // When
    final firstSave = store.save(
      isMovie: true,
      query: const ReleaseQuery(search: 'old'),
      remember: true,
    );
    await firstWriteStarted.future;
    final secondSave = store.save(
      isMovie: true,
      query: const ReleaseQuery(search: 'new'),
      remember: false,
    );
    await Future<void>.delayed(Duration.zero);

    // Then
    verifyNever(() => preferences.remove(any()));
    firstWriteGate.complete(true);
    await Future.wait([firstSave, secondSave]);
    verifyInOrder([
      () => preferences.setBool('remember_movie_release_query', true),
      () => preferences.setString('movie_release_query', any()),
      () => preferences.setBool('remember_movie_release_query', false),
      () => preferences.remove('movie_release_query'),
    ]);
  });

  test('should ignore a remember preference with an unexpected type', () async {
    // Given
    SharedPreferences.setMockInitialValues({
      'remember_movie_release_query': 'true',
      'movie_release_query': jsonEncode(
        const ReleaseQuery(search: 'stale').toJson(),
      ),
    });
    final store = ReleaseQueryStore();

    // When
    final saved = await store.load(isMovie: true);

    // Then
    expect(saved.query, const ReleaseQuery());
    expect(saved.remember, isFalse);
  });

  test('should ignore a stored query with an unexpected type', () async {
    // Given
    SharedPreferences.setMockInitialValues({
      'remember_movie_release_query': true,
      'movie_release_query': 42,
    });
    final store = ReleaseQueryStore();

    // When
    final saved = await store.load(isMovie: true);

    // Then
    expect(saved.query, const ReleaseQuery());
    expect(saved.remember, isTrue);
  });

  test('should restore defaults for malformed query field types', () async {
    // Given
    SharedPreferences.setMockInitialValues({
      'remember_movie_release_query': true,
      'movie_release_query': jsonEncode({
        'search': 42,
        'originalLanguageOnly': 'true',
      }),
    });
    final store = ReleaseQueryStore();

    // When
    final saved = await store.load(isMovie: true);

    // Then
    expect(saved.query, const ReleaseQuery());
    expect(saved.remember, isTrue);
  });
}
