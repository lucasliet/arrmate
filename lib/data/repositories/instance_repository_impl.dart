import '../../core/services/logger_service.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/instance_repository.dart';
import '../api/jellyfin_service.dart';
import '../api/qbittorrent_service.dart';
import '../api/radarr_api.dart';
import '../api/sonarr_api.dart';

/// Implementation of [InstanceRepository] that delegates to the appropriate API.
class InstanceRepositoryImpl implements InstanceRepository {
  @override
  Future<InstanceStatus> getSystemStatus(Instance instance) async {
    logger.debug(
      '[InstanceRepository] Getting status for instance ${instance.id} (${instance.type.name})',
    );
    return switch (instance.type) {
      InstanceType.radarr => RadarrApi(instance).getSystemStatus(),
      InstanceType.sonarr => SonarrApi(instance).getSystemStatus(),
      InstanceType.qbittorrent => QBittorrentService(
        instance,
      ).getSystemStatus(),
      InstanceType.jellyfin => JellyfinService(instance).getSystemStatus(),
    };
  }

  @override
  Future<List<InstanceDiskSpace>> getDiskSpace(Instance instance) async {
    logger.debug(
      '[InstanceRepository] Getting disk space for instance ${instance.id} (${instance.type.name})',
    );
    return switch (instance.type) {
      InstanceType.radarr => RadarrApi(instance).getDiskSpace(),
      InstanceType.sonarr => SonarrApi(instance).getDiskSpace(),
      InstanceType.qbittorrent => throw UnsupportedError(
        'Disk space is not available for qBittorrent instances',
      ),
      InstanceType.jellyfin => throw UnsupportedError(
        'Disk space is not available for Jellyfin instances',
      ),
    };
  }

  @override
  Future<List<Tag>> getTags(Instance instance) async {
    logger.debug(
      '[InstanceRepository] Getting tags for instance ${instance.id} (${instance.type.name})',
    );
    return switch (instance.type) {
      InstanceType.radarr => RadarrApi(instance).getTags(),
      InstanceType.sonarr => SonarrApi(instance).getTags(),
      InstanceType.qbittorrent ||
      InstanceType.jellyfin => _getUnsupportedTypeTags(instance),
    };
  }

  Future<List<Tag>> _getUnsupportedTypeTags(Instance instance) async {
    // Design decision: Return empty list instead of throwing UnimplementedError
    // to allow the UI to function without tag support for these instance types.
    logger.warning(
      '[InstanceRepository] getTags not implemented for ${instance.type.name}',
    );
    return [];
  }
}
