import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/models/models.dart';
import '../../providers/data_providers.dart';

part 'releases_provider.g.dart';

@riverpod
Future<List<Release>> movieReleases(MovieReleasesRef ref, int movieId) async {
  final api = ref.watch(radarrApiProvider);
  if (api == null) throw Exception('API not available');
  return api.getMovieReleases(movieId);
}

@riverpod
Future<List<Release>> episodeReleases(EpisodeReleasesRef ref, int episodeId) async {
  final api = ref.watch(sonarrApiProvider);
  if (api == null) throw Exception('API not available');
  return api.getSeriesReleases(episodeId: episodeId);
}

// Logic to grab (download) a release can be a method in a Notifier or just a function call via API.
// Using a Notifier for the "Grab" action state might be overkill if it's just a fire-and-forget with loading overlay.
// I'll keep it simple in the UI or a simple controller.

@riverpod
class ReleaseActions extends _$ReleaseActions {
  @override
  void build() {}

  Future<void> downloadRelease({
    required String guid,
    required String indexerId,
    required bool isMovie, 
  }) async {
    if (isMovie) {
       final api = ref.read(radarrApiProvider);
       if (api == null) throw Exception('Radarr API not available');
       await api.downloadRelease(guid, indexerId);
    } else {
       final api = ref.read(sonarrApiProvider);
       if (api == null) throw Exception('Sonarr API not available');
       await api.downloadRelease(guid, indexerId);
    }
  }
}
