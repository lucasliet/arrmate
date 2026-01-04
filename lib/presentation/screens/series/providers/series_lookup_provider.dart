import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/models/models.dart';
import '../../../providers/instances_provider.dart';

part 'series_lookup_provider.g.dart';

@riverpod
class SeriesLookup extends _$SeriesLookup {
  @override
  FutureOr<List<Series>> build() {
    return [];
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final api = ref.read(sonarrApiProvider);
      if (api == null) throw Exception('API not available');

      final series = await api.lookupSeries(query);
      state = AsyncValue.data(series);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data([]);
  }
}
