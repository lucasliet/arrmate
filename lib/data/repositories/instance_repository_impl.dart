import '../../domain/models/models.dart';
import '../../domain/repositories/instance_repository.dart';
import '../api/radarr_api.dart';
import '../api/sonarr_api.dart';

class InstanceRepositoryImpl implements InstanceRepository {
  @override
  Future<InstanceStatus> getSystemStatus(Instance instance) async {
    return switch (instance.type) {
      InstanceType.radarr => RadarrApi(instance).getSystemStatus(),
      InstanceType.sonarr => SonarrApi(instance).getSystemStatus(),
    };
  }

  @override
  Future<List<Tag>> getTags(Instance instance) async {
    return switch (instance.type) {
      InstanceType.radarr => RadarrApi(instance).getTags(),
      InstanceType.sonarr => SonarrApi(instance).getTags(),
    };
  }
}
