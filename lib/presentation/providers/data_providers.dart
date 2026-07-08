import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/purge_service.dart';
import '../../domain/repositories/repositories.dart';
import '../../data/repositories/repositories.dart';
import '../../data/api/api.dart';
import 'instances_provider.dart';
import 'notifications_provider.dart';

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

/// Provider for the [QBittorrentService] of the currently selected qBittorrent instance.
final qbittorrentServiceProvider = Provider<QBittorrentService?>((ref) {
  final instance = ref.watch(currentQBittorrentInstanceProvider);
  if (instance == null) return null;
  return QBittorrentService(instance);
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

/// Provider for the [PurgeService]. Reads repositories/services fresh from
/// their providers at call time so the currently selected instances are used.
final purgeServiceProvider = Provider<PurgeService>((ref) {
  return PurgeService(
    movieRepositoryFactory: () => ref.read(movieRepositoryProvider),
    seriesRepositoryFactory: () => ref.read(seriesRepositoryProvider),
    qbittorrentServiceFactory: () => ref.read(qbittorrentServiceProvider),
    inAppNotificationServiceFactory: () =>
        ref.read(inAppNotificationServiceProvider),
  );
});
