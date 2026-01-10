import '../../core/services/logger_service.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/instance_repository.dart';
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
      InstanceType.qbittorrent => _getQBittorrentDefaultTags(instance),
    };
  }

  Future<List<Tag>> _getQBittorrentDefaultTags(Instance instance) async {
    // Design decision: Return empty list instead of throwing UnimplementedError
    // to allow the UI to function without tag support for qBittorrent.
    logger.warning(
      '[InstanceRepository] getTags not implemented for qBittorrent',
    );
    return [];
  }
}
