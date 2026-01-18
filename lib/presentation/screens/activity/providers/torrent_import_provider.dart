import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';

/// Provider that fetches movies that are monitored for import selection.
final moviesForImportProvider = FutureProvider.autoDispose<List<Movie>>((
  ref,
) async {
  final repository = ref.watch(movieRepositoryProvider);
  if (repository == null) throw Exception('Movie repository not available');
  final movies = await repository.getMovies();
  return movies.where((m) => m.monitored).toList()
    ..sort((a, b) => a.title.compareTo(b.title));
});

/// Provider that fetches series that are monitored for import selection.
final seriesForImportProvider = FutureProvider.autoDispose<List<Series>>((
  ref,
) async {
  final repository = ref.watch(seriesRepositoryProvider);
  if (repository == null) throw Exception('Series repository not available');
  final series = await repository.getSeries();
  return series.where((s) => s.monitored).toList()
    ..sort((a, b) => a.title.compareTo(b.title));
});

/// Parameter for fetching importable files by folder path.
class ImportByFolderParams {
  final String folderPath;
  final bool isMovie;

  const ImportByFolderParams({required this.folderPath, required this.isMovie});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportByFolderParams &&
          folderPath == other.folderPath &&
          isMovie == other.isMovie;

  @override
  int get hashCode => folderPath.hashCode ^ isMovie.hashCode;
}

/// Provider that fetches importable files from a folder path.
final importableFilesByFolderProvider = FutureProvider.autoDispose
    .family<List<ImportableFile>, ImportByFolderParams>((ref, params) async {
      if (params.isMovie) {
        final repository = ref.watch(movieRepositoryProvider);
        if (repository == null) {
          throw Exception('Movie repository not available');
        }
        return repository.getImportableFilesByFolder(params.folderPath);
      } else {
        final repository = ref.watch(seriesRepositoryProvider);
        if (repository == null) {
          throw Exception('Series repository not available');
        }
        return repository.getImportableFilesByFolder(params.folderPath);
      }
    });

/// Controller for managing torrent import operations.
class TorrentImportController {
  final Ref ref;
  final bool isMovie;

  TorrentImportController(this.ref, {required this.isMovie});

  /// Imports selected files to the specified movie or series.
  Future<void> importFiles(List<ImportableFile> files) async {
    if (isMovie) {
      final repository = ref.read(movieRepositoryProvider);
      if (repository == null) throw Exception('Movie repository not available');
      await repository.manualImport(files);
    } else {
      final repository = ref.read(seriesRepositoryProvider);
      if (repository == null) {
        throw Exception('Series repository not available');
      }
      await repository.manualImport(files);
    }
  }
}

/// Provider for the torrent import controller.
final torrentImportControllerProvider = Provider.autoDispose
    .family<TorrentImportController, bool>((ref, isMovie) {
      return TorrentImportController(ref, isMovie: isMovie);
    });
