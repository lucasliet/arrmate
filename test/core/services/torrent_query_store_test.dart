import 'dart:async';
import 'dart:convert';

import 'package:arrmate/core/services/torrent_query_store.dart';
import 'package:arrmate/domain/models/qbittorrent/torrent_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('should persist the torrent query', () async {
    // Given
    final store = TorrentQueryStore();
    const query = TorrentQuery(
      search: 'ubuntu',
      status: TorrentStatusFilter.paused,
      sortOption: TorrentSortOption.size,
    );

    // When
    await store.save(query: query, remember: true);
    final saved = await store.load();

    // Then
    expect(saved.query, query);
    expect(saved.remember, isTrue);
  });

  test('should clear the stored query when remembering is disabled', () async {
    // Given
    final store = TorrentQueryStore();
    const query = TorrentQuery(search: 'temporary');
    await store.save(query: query, remember: true);

    // When
    await store.save(query: query, remember: false);
    final saved = await store.load();

    // Then
    expect(saved.query, const TorrentQuery());
    expect(saved.remember, isFalse);
  });

  test('should absorb persistence failures when saving', () async {
    // Given
    final store = TorrentQueryStore(
      preferencesLoader: () => Future<SharedPreferences>.error(
        StateError('Preferences unavailable'),
      ),
    );

    // When
    final save = store.save(
      query: const TorrentQuery(search: 'x'),
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
    final store = TorrentQueryStore(preferencesLoader: () async => preferences);

    // When
    final firstSave = store.save(
      query: const TorrentQuery(search: 'old'),
      remember: true,
    );
    await firstWriteStarted.future;
    final secondSave = store.save(
      query: const TorrentQuery(search: 'new'),
      remember: false,
    );
    await Future<void>.delayed(Duration.zero);

    // Then
    verifyNever(() => preferences.remove(any()));
    firstWriteGate.complete(true);
    await Future.wait([firstSave, secondSave]);
    verifyInOrder([
      () => preferences.setBool('remember_torrent_query', true),
      () => preferences.setString('torrent_query', any()),
      () => preferences.setBool('remember_torrent_query', false),
      () => preferences.remove('torrent_query'),
    ]);
  });

  test('should ignore a remember preference with an unexpected type', () async {
    // Given
    SharedPreferences.setMockInitialValues({
      'remember_torrent_query': 'true',
      'torrent_query': jsonEncode(const TorrentQuery(search: 'stale').toJson()),
    });
    final store = TorrentQueryStore();

    // When
    final saved = await store.load();

    // Then
    expect(saved.query, const TorrentQuery());
    expect(saved.remember, isFalse);
  });

  test('should ignore a stored query with an unexpected type', () async {
    // Given
    SharedPreferences.setMockInitialValues({
      'remember_torrent_query': true,
      'torrent_query': 42,
    });
    final store = TorrentQueryStore();

    // When
    final saved = await store.load();

    // Then
    expect(saved.query, const TorrentQuery());
    expect(saved.remember, isTrue);
  });

  test('should restore defaults for malformed query field types', () async {
    // Given
    SharedPreferences.setMockInitialValues({
      'remember_torrent_query': true,
      'torrent_query': jsonEncode({'search': 42, 'sortAscending': 'true'}),
    });
    final store = TorrentQueryStore();

    // When
    final saved = await store.load();

    // Then
    expect(saved.query, const TorrentQuery());
    expect(saved.remember, isTrue);
  });
}
