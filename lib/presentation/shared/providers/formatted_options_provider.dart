import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../domain/models/models.dart';
import '../../providers/data_providers.dart';

part 'formatted_options_provider.g.dart';

/// Fetches available quality profiles for movies (Radarr).
@riverpod
Future<List<QualityProfile>> movieQualityProfiles(
  MovieQualityProfilesRef ref,
) async {
  final api = ref.watch(radarrApiProvider);
  if (api == null) return [];
  return api.getQualityProfiles();
}

/// Fetches configured root folders for movies (Radarr).
@riverpod
Future<List<RootFolder>> movieRootFolders(MovieRootFoldersRef ref) async {
  final api = ref.watch(radarrApiProvider);
  if (api == null) return [];
  return api.getRootFolders();
}

/// Fetches available quality profiles for series (Sonarr).
@riverpod
Future<List<QualityProfile>> seriesQualityProfiles(
  SeriesQualityProfilesRef ref,
) async {
  final api = ref.watch(sonarrApiProvider);
  if (api == null) return [];
  return api.getQualityProfiles();
}

/// Fetches configured root folders for series (Sonarr).
@riverpod
Future<List<RootFolder>> seriesRootFolders(SeriesRootFoldersRef ref) async {
  final api = ref.watch(sonarrApiProvider);
  if (api == null) return [];
  return api.getRootFolders();
}
