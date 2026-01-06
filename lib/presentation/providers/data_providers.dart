import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/repositories.dart';
import '../../data/repositories/repositories.dart';
import '../../data/api/api.dart';
import 'instances_provider.dart';

/// Provider for the [RadarrApi] of the currently selected Radarr instance.
final radarrApiProvider = Provider<RadarrApi?>((ref) {
  final instance = ref.watch(currentRadarrInstanceProvider);
  if (instance == null) return null;
  return RadarrApi(instance);
});

/// Provider for the [SonarrApi] of the currently selected Sonarr instance.
final sonarrApiProvider = Provider<SonarrApi?>((ref) {
  final instance = ref.watch(currentSonarrInstanceProvider);
  if (instance == null) return null;
  return SonarrApi(instance);
});

/// Provider for the [MovieRepository], utilizing the active [RadarrApi].
final movieRepositoryProvider = Provider<MovieRepository?>((ref) {
  final api = ref.watch(radarrApiProvider);
  if (api == null) return null;
  return MovieRepositoryImpl(api);
});

/// Provider for the [SeriesRepository], utilizing the active [SonarrApi].
final seriesRepositoryProvider = Provider<SeriesRepository?>((ref) {
  final api = ref.watch(sonarrApiProvider);
  if (api == null) return null;
  return SeriesRepositoryImpl(api);
});

/// Provider for the [InstanceRepository], used for testing connections and validating instances.
final instanceRepositoryProvider = Provider<InstanceRepository>((ref) {
  return InstanceRepositoryImpl();
});
