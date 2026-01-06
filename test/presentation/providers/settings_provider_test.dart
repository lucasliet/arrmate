import 'dart:convert';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/settings_provider.dart';
import 'package:arrmate/presentation/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('SettingsNotifier', () {
    test('should initialize with default values', () {
      final state = container.read(settingsProvider);

      expect(state.homeTab, AppTab.movies);
      expect(state.movieSort, const MovieSort());
      expect(state.seriesSort, const SeriesSort());
    });

    test('should persist Home Tab selection', () async {
      final notifier = container.read(settingsProvider.notifier);

      await notifier.setHomeTab(AppTab.series);

      final state = container.read(settingsProvider);
      expect(state.homeTab, AppTab.series);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('home_tab'), AppTab.series.name);
    });

    test('should persist Movie Sort selection', () async {
      final notifier = container.read(settingsProvider.notifier);
      final newSort = const MovieSort(
        option: MovieSortOption.byAdded,
        isAscending: true,
      );

      await notifier.setMovieSort(newSort);

      final state = container.read(settingsProvider);
      expect(state.movieSort, newSort);

      final prefs = await SharedPreferences.getInstance();
      final savedSortJson = prefs.getString('movie_sort');
      expect(savedSortJson, isNotNull);
      final savedSort = MovieSort.fromJson(jsonDecode(savedSortJson!));
      expect(savedSort, newSort);
    });

    test('should persist Series Sort selection', () async {
      final notifier = container.read(settingsProvider.notifier);
      final newSort = const SeriesSort(
        option: SeriesSortOption.byAdded,
        isAscending: true,
      );

      await notifier.setSeriesSort(newSort);

      final state = container.read(settingsProvider);
      expect(state.seriesSort, newSort);

      final prefs = await SharedPreferences.getInstance();
      final savedSortJson = prefs.getString('series_sort');
      expect(savedSortJson, isNotNull);
      final savedSort = SeriesSort.fromJson(jsonDecode(savedSortJson!));
      expect(savedSort, newSort);
    });

    test('should load persisted values on initialization', () async {
      final customMovieSort = const MovieSort(
        option: MovieSortOption.byRating,
        isAscending: false,
      );
      final customSeriesSort = const SeriesSort(
        option: SeriesSortOption.byTitle,
        isAscending: true,
      );

      SharedPreferences.setMockInitialValues({
        'home_tab': AppTab.activity.name,
        'movie_sort': jsonEncode(customMovieSort.toJson()),
        'series_sort': jsonEncode(customSeriesSort.toJson()),
      });

      // Recreate container to simulate app restart
      container = ProviderContainer();
      // Need to read the provider to trigger initialization
      // Since initialization is async inside build(), we might need to wait a bit or structured better
      // But SettingsNotifier.build() calls _loadSettings() which is async but not awaited in build
      // so the state update happens after a microtask.

      // Let's force a read and then wait
      container.read(settingsProvider);
      await Future.delayed(Duration.zero);

      final state = container.read(settingsProvider);

      expect(state.homeTab, AppTab.activity);
      expect(state.movieSort, customMovieSort);
      expect(state.seriesSort, customSeriesSort);
    });
  });
}
