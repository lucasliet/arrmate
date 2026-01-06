import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/models.dart';
import '../../providers/data_providers.dart';

part 'formatted_options_provider.g.dart';

/// Fetches available quality profiles for movies (Radarr).
@riverpod
Future<List<QualityProfile>> movieQualityProfiles(Ref ref) async {
  final api = ref.watch(radarrApiProvider);
  if (api == null) return [];
  return api.getQualityProfiles();
}

/// Fetches configured root folders for movies (Radarr).
@riverpod
Future<List<RootFolder>> movieRootFolders(Ref ref) async {
  final api = ref.watch(radarrApiProvider);
  if (api == null) return [];
  return api.getRootFolders();
}

/// Fetches available quality profiles for series (Sonarr).
@riverpod
Future<List<QualityProfile>> seriesQualityProfiles(Ref ref) async {
  final api = ref.watch(sonarrApiProvider);
  if (api == null) return [];
  return api.getQualityProfiles();
}

/// Fetches configured root folders for series (Sonarr).
@riverpod
Future<List<RootFolder>> seriesRootFolders(Ref ref) async {
  final api = ref.watch(sonarrApiProvider);
  if (api == null) return [];
  return api.getRootFolders();
}
