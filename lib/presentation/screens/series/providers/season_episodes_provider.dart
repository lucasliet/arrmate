import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';

part 'season_episodes_provider.g.dart';

@riverpod
Future<List<Episode>> seasonEpisodes(
  SeasonEpisodesRef ref,
  int seriesId,
  int seasonNumber,
) async {
  final api = ref.watch(sonarrApiProvider);
  if (api == null) throw Exception('API not available');

  final episodes = await api.getEpisodes(seriesId);
  // Filter by season
  return episodes.where((e) => e.seasonNumber == seasonNumber).toList();
}
