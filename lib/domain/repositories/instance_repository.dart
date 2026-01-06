import '../models/models.dart';

abstract class InstanceRepository {
  Future<InstanceStatus> getSystemStatus(Instance instance);
  Future<List<Tag>> getTags(Instance instance);
}
