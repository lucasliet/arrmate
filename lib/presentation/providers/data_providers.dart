import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/repositories.dart';
import '../../data/repositories/repositories.dart';
import '../../data/api/api.dart';
import 'instances_provider.dart';

// APIs Providers
final radarrApiProvider = Provider<RadarrApi?>((ref) {
  final instance = ref.watch(currentRadarrInstanceProvider);
  if (instance == null) return null;
  return RadarrApi(instance);
});

final sonarrApiProvider = Provider<SonarrApi?>((ref) {
  final instance = ref.watch(currentSonarrInstanceProvider);
  if (instance == null) return null;
  return SonarrApi(instance);
});

// Repositories Providers
final movieRepositoryProvider = Provider<MovieRepository?>((ref) {
  final api = ref.watch(radarrApiProvider);
  if (api == null) return null;
  return MovieRepositoryImpl(api);
});

final seriesRepositoryProvider = Provider<SeriesRepository?>((ref) {
  final api = ref.watch(sonarrApiProvider);
  if (api == null) return null;
  return SeriesRepositoryImpl(api);
});

final instanceRepositoryProvider = Provider<InstanceRepository>((ref) {
  return InstanceRepositoryImpl();
});
