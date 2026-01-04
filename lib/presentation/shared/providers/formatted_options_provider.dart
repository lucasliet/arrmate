import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/models/models.dart';
import '../../providers/instances_provider.dart';

part 'formatted_options_provider.g.dart';

@riverpod
Future<List<QualityProfile>> movieQualityProfiles(MovieQualityProfilesRef ref) async {
  final api = ref.watch(radarrApiProvider);
  if (api == null) return [];
  return api.getQualityProfiles();
}

@riverpod
Future<List<RootFolder>> movieRootFolders(MovieRootFoldersRef ref) async {
  final api = ref.watch(radarrApiProvider);
  if (api == null) return [];
  return api.getRootFolders();
}

@riverpod
Future<List<QualityProfile>> seriesQualityProfiles(SeriesQualityProfilesRef ref) async {
  final api = ref.watch(sonarrApiProvider);
  if (api == null) return [];
  return api.getQualityProfiles();
}

@riverpod
Future<List<RootFolder>> seriesRootFolders(SeriesRootFoldersRef ref) async {
  final api = ref.watch(sonarrApiProvider);
  if (api == null) return [];
  return api.getRootFolders();
}
