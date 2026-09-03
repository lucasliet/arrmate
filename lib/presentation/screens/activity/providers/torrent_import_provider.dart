import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';
import 'torrent_link_provider.dart';

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

  /// Imports the selected [files], which belong to the torrent [torrentHash].
  ///
  /// The hash travels as the download id, uppercased the way Radarr and Sonarr
  /// record it for qBittorrent and look it up — case-sensitively. It ties the
  /// import to the tracked download instead of leaving it to look like a loose
  /// folder, so the torrent keeps its relation to the library once the queue
  /// entry is gone.
  ///
  /// The files are copied rather than moved: the torrent is still seeding them,
  /// and a move would take the data out from under it.
  Future<void> importFiles(
    List<ImportableFile> files, {
    required String torrentHash,
  }) async {
    final downloadId = torrentHash.toUpperCase();
    final tracked = [
      for (final file in files) file.copyWith(downloadId: downloadId),
    ];

    if (isMovie) {
      final repository = ref.read(movieRepositoryProvider);
      if (repository == null) throw Exception('Movie repository not available');
      await repository.manualImport(tracked, copyFiles: true);
    } else {
      final repository = ref.read(seriesRepositoryProvider);
      if (repository == null) {
        throw Exception('Series repository not available');
      }
      await repository.manualImport(tracked, copyFiles: true);
    }

    // The torrent keeps the same hash, so the index the badge reads is not
    // rebuilt on its own: without this the torrent still looks unrelated to the
    // library it was just imported into.
    ref.invalidate(torrentLinkIndexProvider);
  }
}

/// Provider for the torrent import controller.
final torrentImportControllerProvider = Provider.autoDispose
    .family<TorrentImportController, bool>((ref, isMovie) {
      return TorrentImportController(ref, isMovie: isMovie);
    });
