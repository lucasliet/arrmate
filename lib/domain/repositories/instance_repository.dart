import '../models/models.dart';

/// Repository interface for instance-related operations.
abstract class InstanceRepository {
  /// Retrieves the system status of the given [instance].
  Future<InstanceStatus> getSystemStatus(Instance instance);

  /// Retrieves available tags from the given [instance].
  Future<List<Tag>> getTags(Instance instance);
}
