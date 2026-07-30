import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/instances_provider.dart';
import 'activity_provider.dart';

/// Provider that fetches potentially importable files for a queue item.
final manualImportFilesProvider = FutureProvider.autoDispose
    .family<List<ImportableFile>, QueueItem>((ref, queueItem) async {
      final instanceType = _requireInstanceType(queueItem);
      final instance = _findOriginatingInstance(
        ref.watch(instancesByTypeProvider(instanceType)),
        queueItem,
      );
      final downloadId = _requireDownloadId(queueItem);

      if (queueItem.movieId != null && instanceType == InstanceType.radarr) {
        final repository = ref.watch(
          movieRepositoryForInstanceProvider(instance),
        );
        return repository.getImportableFiles(downloadId);
      }
      if (queueItem.seriesId != null && instanceType == InstanceType.sonarr) {
        final repository = ref.watch(
          seriesRepositoryForInstanceProvider(instance),
        );
        return repository.getImportableFiles(downloadId);
      }

      throw StateError('Queue item media type does not match its instance');
    });

/// Provider for the controller managing manual file imports.
final manualImportControllerProvider = Provider.autoDispose
    .family<ManualImportController, QueueItem>((ref, queueItem) {
      return ManualImportController(ref, queueItem);
    });

/// Controller to handle manual import logic.
class ManualImportController {
  final Ref ref;
  final QueueItem queueItem;

  ManualImportController(this.ref, this.queueItem);

  /// Imports selected files for the associated download.
  Future<void> importFiles(List<ImportableFile> files) async {
    final instanceType = _requireInstanceType(queueItem);
    final instance = _findOriginatingInstance(
      ref.read(instancesByTypeProvider(instanceType)),
      queueItem,
    );
    _requireDownloadId(queueItem);

    if (queueItem.movieId != null && instanceType == InstanceType.radarr) {
      final repository = ref.read(movieRepositoryForInstanceProvider(instance));
      await repository.manualImport(files);
    } else if (queueItem.seriesId != null &&
        instanceType == InstanceType.sonarr) {
      final repository = ref.read(
        seriesRepositoryForInstanceProvider(instance),
      );
      await repository.manualImport(files);
    } else {
      throw StateError('Queue item media type does not match its instance');
    }

    ref.invalidate(queueProvider);
    ref.invalidate(manualImportFilesProvider(queueItem));
  }

  /// Manually refreshes the list of importable files.
  void refreshFiles() {
    ref.invalidate(manualImportFilesProvider(queueItem));
  }
}

Instance _findOriginatingInstance(
  List<Instance> instances,
  QueueItem queueItem,
) {
  final instanceId = queueItem.instanceId;
  if (instanceId == null) {
    throw StateError('Queue item origin is missing');
  }

  final instance = instances
      .where((instance) => instance.id == instanceId)
      .firstOrNull;
  if (instance == null) {
    throw StateError('Queue item instance is no longer configured');
  }
  return instance;
}

InstanceType _requireInstanceType(QueueItem queueItem) {
  final instanceType = queueItem.instanceType;
  if (instanceType == null) {
    throw StateError('Queue item origin is missing');
  }
  return instanceType;
}

String _requireDownloadId(QueueItem queueItem) {
  final downloadId = queueItem.downloadId;
  if (downloadId == null || downloadId.isEmpty) {
    throw StateError('Queue item download ID is missing');
  }
  return downloadId;
}
