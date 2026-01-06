import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';

part 'episode_providers.g.dart';

@riverpod
Future<List<HistoryEvent>> episodeHistory(Ref ref, int episodeId) async {
  final api = ref.watch(sonarrApiProvider);
  if (api == null) throw Exception('API not available');

  final page = await api.getHistory(episodeId: episodeId, pageSize: 50);
  return page.records;
}

@riverpod
Future<MediaFile> episodeFile(Ref ref, int fileId) async {
  final api = ref.watch(sonarrApiProvider);
  if (api == null) throw Exception('API not available');
  return api.getEpisodeFile(fileId);
}
