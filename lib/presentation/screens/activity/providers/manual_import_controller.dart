import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';
import 'activity_provider.dart';

part 'manual_import_controller.g.dart';

class ManualImportState {
  final List<ImportableFile> files;
  final bool isLoading;
  final String? error;

  const ManualImportState({
    required this.files,
    this.isLoading = false,
    this.error,
  });

  ManualImportState copyWith({
    List<ImportableFile>? files,
    bool? isLoading,
    String? error,
  }) {
    return ManualImportState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

@riverpod
class ManualImportControllerNotifier extends _$ManualImportControllerNotifier {
  @override
  FutureOr<ManualImportState> build(String downloadId) async {
    final queueItems = await ref.watch(queueProvider.future);
    final queueItem = queueItems.firstWhere(
      (item) => item.downloadId == downloadId,
      orElse: () => throw Exception('Queue item not found'),
    );

    List<ImportableFile> files;
    if (queueItem.movieId != null) {
      final repository = ref.watch(movieRepositoryProvider);
      if (repository == null) throw Exception('Movie repository not available');
      files = await repository.getImportableFiles(downloadId);
    } else if (queueItem.seriesId != null) {
      final repository = ref.watch(seriesRepositoryProvider);
      if (repository == null) {
        throw Exception('Series repository not available');
      }
      files = await repository.getImportableFiles(downloadId);
    } else {
      throw Exception('Unknown media type');
    }

    return ManualImportState(files: files);
  }

  void updateFile(int fileId, ImportableFile updatedFile) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedFiles = currentState.files.map((f) {
      if (f.id == fileId) return updatedFile;
      return f;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(files: updatedFiles));
  }

  void assignSeries(int fileId, Series series) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedFiles = currentState.files.map((f) {
      if (f.id == fileId) {
        return f.copyWith(series: series, episodes: []);
      }
      return f;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(files: updatedFiles));
  }

  void assignEpisodes(int fileId, List<Episode> episodes) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedFiles = currentState.files.map((f) {
      if (f.id == fileId) {
        return f.copyWith(episodes: episodes);
      }
      return f;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(files: updatedFiles));
  }

  void applyMappingToSimilar(int sourceFileId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final sourceFile = currentState.files.firstWhere(
      (f) => f.id == sourceFileId,
      orElse: () => throw Exception('Source file not found'),
    );

    if (sourceFile.series == null) return;

    final sourceNameBase = _extractSeriesNameBase(sourceFile.name ?? '');
    if (sourceNameBase.isEmpty) return;

    final updatedFiles = currentState.files.map((f) {
      if (f.id == sourceFileId) return f;
      if (f.series != null) return f;

      final targetNameBase = _extractSeriesNameBase(f.name ?? '');
      if (targetNameBase.isNotEmpty &&
          targetNameBase.toLowerCase() == sourceNameBase.toLowerCase()) {
        return f.copyWith(series: sourceFile.series);
      }
      return f;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(files: updatedFiles));
  }

  String _extractSeriesNameBase(String filename) {
    final cleanName = filename.replaceAll(RegExp(r'[\._]'), ' ');
    final seasonMatch = RegExp(r'[Ss]\d{1,2}[Ee]\d{1,2}').firstMatch(cleanName);
    if (seasonMatch != null) {
      return cleanName.substring(0, seasonMatch.start).trim();
    }
    final altMatch = RegExp(r'\d{1,2}x\d{2}').firstMatch(cleanName);
    if (altMatch != null) {
      return cleanName.substring(0, altMatch.start).trim();
    }
    return '';
  }

  List<String> validateBeforeImport(List<int> selectedFileIds) {
    final currentState = state.valueOrNull;
    if (currentState == null) return ['State not available'];

    final warnings = <String>[];
    final selectedFiles = currentState.files.where(
      (f) => selectedFileIds.contains(f.id),
    );

    for (final file in selectedFiles) {
      if (file.series != null &&
          (file.episodes == null || file.episodes!.isEmpty)) {
        warnings.add(
          '${file.name ?? file.relativePath}: Series assigned but no episodes selected',
        );
      }
    }

    return warnings;
  }

  Future<void> commitImport(
    List<int> selectedFileIds, {
    String importMode = 'auto',
  }) async {
    final currentState = state.valueOrNull;
    if (currentState == null) throw Exception('State not available');

    final selectedFiles = currentState.files
        .where((f) => selectedFileIds.contains(f.id))
        .toList();

    if (selectedFiles.isEmpty) throw Exception('No files selected');

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final queueItems = await ref.read(queueProvider.future);
      final queueItem = queueItems.firstWhere(
        (item) => item.downloadId == downloadId,
        orElse: () => throw Exception('Queue item not found'),
      );

      if (queueItem.movieId != null) {
        final repository = ref.read(movieRepositoryProvider);
        if (repository == null) {
          throw Exception('Movie repository not available');
        }
        await repository.manualImport(selectedFiles);
      } else if (queueItem.seriesId != null) {
        final repository = ref.read(seriesRepositoryProvider);
        if (repository == null) {
          throw Exception('Series repository not available');
        }
        await repository.manualImport(selectedFiles);
      } else {
        throw Exception('Unknown media type');
      }

      ref.invalidate(queueProvider);
    } finally {
      final afterState = state.valueOrNull;
      if (afterState != null) {
        state = AsyncValue.data(afterState.copyWith(isLoading: false));
      }
    }
  }
}
