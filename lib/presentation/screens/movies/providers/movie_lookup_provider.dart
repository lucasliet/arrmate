import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/media_lookup_query.dart';
import '../../../../domain/models/models.dart';
import '../../../../presentation/providers/data_providers.dart';

part 'movie_lookup_provider.g.dart';

/// Notifier for looking up movies from an external provider (TMDB via Radarr).
@riverpod
class MovieLookup extends _$MovieLookup {
  Timer? _debounce;
  int _requestId = 0;

  @override
  FutureOr<List<Movie>> build() {
    ref.onDispose(() => _debounce?.cancel());
    return [];
  }

  /// Immediately searches Radarr using a normalized lookup query.
  Future<void> search(String query) async {
    _debounce?.cancel();
    await _search(query);
  }

  /// Searches Radarr after a short debounce interval.
  void searchDebounced(String query) {
    _debounce?.cancel();
    final normalized = normalizeMediaLookupQuery(query, MediaLookupType.movie);
    if (normalized.isEmpty) {
      reset();
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _search(normalized),
    );
  }

  Future<void> _search(String query) async {
    final normalized = normalizeMediaLookupQuery(query, MediaLookupType.movie);
    final requestId = ++_requestId;
    if (normalized.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final api = ref.read(radarrApiProvider);
      if (api == null) throw Exception('API not available');

      final movies = await api.lookupMovie(normalized);
      if (requestId == _requestId) {
        state = AsyncValue.data(movies);
      }
    } catch (e, st) {
      if (requestId == _requestId) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Clears results and cancels any pending search.
  void reset() {
    _debounce?.cancel();
    _requestId++;
    state = const AsyncValue.data([]);
  }
}
