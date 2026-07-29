import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/media_lookup_query.dart';
import '../../../../domain/models/models.dart';
import '../../../../presentation/providers/data_providers.dart';

part 'series_lookup_provider.g.dart';

/// Notifier for looking up series from an external provider (TVDB via Sonarr).
@riverpod
class SeriesLookup extends _$SeriesLookup {
  Timer? _debounce;
  int _requestId = 0;

  @override
  FutureOr<List<Series>> build() {
    ref.onDispose(() => _debounce?.cancel());
    return [];
  }

  /// Immediately searches Sonarr using a normalized lookup query.
  Future<void> search(String query) async {
    _debounce?.cancel();
    await _search(query);
  }

  /// Searches Sonarr after a short debounce interval.
  void searchDebounced(String query) {
    _debounce?.cancel();
    final normalized = normalizeMediaLookupQuery(query, MediaLookupType.series);
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
    final normalized = normalizeMediaLookupQuery(query, MediaLookupType.series);
    final requestId = ++_requestId;
    if (normalized.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final api = ref.read(sonarrApiProvider);
      if (api == null) throw Exception('API not available');

      final series = await api.lookupSeries(normalized);
      if (requestId == _requestId) {
        state = AsyncValue.data(series);
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
