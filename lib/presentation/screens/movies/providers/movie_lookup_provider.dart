import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/models/models.dart';
import '../../../providers/instances_provider.dart';

part 'movie_lookup_provider.g.dart';

@riverpod
class MovieLookup extends _$MovieLookup {
  @override
  FutureOr<List<Movie>> build() {
    return [];
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final api = ref.read(radarrApiProvider);
      if (api == null) throw Exception('API not available');

      final movies = await api.lookupMovie(query);
      state = AsyncValue.data(movies);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data([]);
  }
}
