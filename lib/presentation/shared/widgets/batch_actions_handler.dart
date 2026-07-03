import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/purge_service.dart';
import '../../../domain/models/models.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_provider.dart';
import '../../screens/movies/providers/movies_provider.dart';
import '../../screens/series/providers/series_provider.dart';
import 'seeding_warning_dialog.dart';

/// Result of a batch action, carrying a user-facing summary message and
/// whether the catalog list should be refreshed.
class BatchActionResult {
  final String message;
  final bool refreshCatalog;

  const BatchActionResult({required this.message, this.refreshCatalog = false});
}

/// Orchestrates the three batch operations (Delete, Delete files, Purge) for
/// the movies and series home screens.
///
/// Each method shows the appropriate confirmation dialog (and the seeding
/// warning dialog for Purge), runs the operation with a loading overlay, and
/// returns a [BatchActionResult] for the caller to show in a snackbar. Returns
/// `null` when the user cancels.
class BatchActionsHandler {
  final WidgetRef _ref;

  BatchActionsHandler(this._ref);

  /// Batch-deletes movies from Radarr.
  ///
  /// When [deleteFiles] is true the on-disk files are removed too. The
  /// catalog list is refreshed on success.
  Future<BatchActionResult?> deleteMovies(
    BuildContext context,
    List<int> movieIds, {
    required bool deleteFiles,
  }) async {
    final repository = _ref.read(movieRepositoryProvider);
    if (repository == null) {
      return const BatchActionResult(message: 'No Radarr instance configured');
    }

    final navigator = Navigator.of(context);
    final confirmed = await _confirm(
      context,
      title: 'Delete ${movieIds.length} movie${_plural(movieIds.length)}',
      content: deleteFiles
          ? 'This removes the selected movies from Radarr and deletes their '
                'files from disk.'
          : 'This removes the selected movies from Radarr. Files stay on disk.',
    );
    if (confirmed != true) return null;

    _showLoading(navigator);

    var deleted = 0;
    try {
      for (final id in movieIds) {
        await repository.deleteMovie(
          id,
          deleteFiles: deleteFiles,
          addExclusion: false,
        );
        deleted++;
      }
      _hideLoading(navigator);
      _ref.invalidate(filteredMoviesProvider);
      return BatchActionResult(
        message:
            'Deleted $deleted movie${_plural(deleted)}'
            '${deleteFiles ? ' and files' : ''}',
        refreshCatalog: true,
      );
    } catch (e) {
      _hideLoading(navigator);
      return BatchActionResult(
        message:
            'Deleted $deleted of ${movieIds.length} '
            'movie${_plural(movieIds.length)} before error: $e',
        refreshCatalog: deleted > 0,
      );
    }
  }

  /// Batch-deletes only the media files of the selected movies, keeping them in
  /// the catalog.
  Future<BatchActionResult?> deleteMovieFiles(
    BuildContext context,
    List<int> movieIds,
  ) async {
    final repository = _ref.read(movieRepositoryProvider);
    if (repository == null) {
      return const BatchActionResult(message: 'No Radarr instance configured');
    }

    final navigator = Navigator.of(context);
    final confirmed = await _confirm(
      context,
      title:
          'Delete files for ${movieIds.length} movie${_plural(movieIds.length)}',
      content:
          'This deletes the media files of the selected movies from disk. '
          'They stay in Radarr.',
    );
    if (confirmed != true) return null;

    _showLoading(navigator);

    var filesDeleted = 0;
    try {
      for (final id in movieIds) {
        filesDeleted += await repository.deleteMovieFiles(id);
      }
      _hideLoading(navigator);
      return BatchActionResult(
        message: 'Deleted $filesDeleted file${_plural(filesDeleted)}',
        refreshCatalog: true,
      );
    } catch (e) {
      _hideLoading(navigator);
      return BatchActionResult(message: 'Failed to delete files: $e');
    }
  }

  /// Batch-purges movies: catalog + files + source torrents, with seeding-time
  /// warning when applicable.
  Future<BatchActionResult?> purgeMovies(
    BuildContext context,
    List<int> movieIds,
  ) async {
    final purgeService = _ref.read(purgeServiceProvider);
    final minimumSeedingDays = _ref.read(settingsProvider).minimumSeedingDays;
    final navigator = Navigator.of(context);

    final confirmed = await _confirm(
      context,
      title: 'Purge ${movieIds.length} movie${_plural(movieIds.length)}',
      content:
          'This permanently removes the selected movies from Radarr, '
          'deletes their files, and deletes all source torrents from '
          'qBittorrent.',
    );
    if (confirmed != true) return null;

    if (!context.mounted) return null;
    SeedingAction? action;
    try {
      action = await resolveSeedingAction(
        context: context,
        minimumSeedingDays: minimumSeedingDays,
        preview: (seconds) async {
          final previews = await Future.wait(
            movieIds.map(
              (id) =>
                  purgeService.previewMovie(id, minimumSeedingSeconds: seconds),
            ),
          );
          final all = <Torrent>[];
          final below = <Torrent>[];
          for (final p in previews) {
            all.addAll(p.torrentsToDelete);
            below.addAll(p.belowThreshold);
          }
          return PurgePreview(
            torrentsToDelete: all,
            belowThreshold: below,
            qbittorrentSkipped: previews.any((p) => p.qbittorrentSkipped),
          );
        },
      );
    } catch (e) {
      return BatchActionResult(message: 'Failed to preview: $e');
    }

    if (action == null || action == SeedingAction.cancel) return null;
    _showLoading(navigator);

    try {
      final result = await purgeService.purgeMovies(movieIds);
      _hideLoading(navigator);
      _ref.invalidate(filteredMoviesProvider);
      return BatchActionResult(
        message: result.formatSummary(
          label:
              'Purged ${movieIds.length} '
              'movie${_plural(movieIds.length)}.',
        ),
        refreshCatalog: true,
      );
    } catch (e) {
      _hideLoading(navigator);
      return BatchActionResult(message: 'Failed to purge: $e');
    }
  }

  // ---- Series equivalents ------------------------------------------------

  Future<BatchActionResult?> deleteSeriesList(
    BuildContext context,
    List<int> seriesIds, {
    required bool deleteFiles,
  }) async {
    final repository = _ref.read(seriesRepositoryProvider);
    if (repository == null) {
      return const BatchActionResult(message: 'No Sonarr instance configured');
    }

    final navigator = Navigator.of(context);
    final confirmed = await _confirm(
      context,
      title: 'Delete ${seriesIds.length} series${_plural(seriesIds.length)}',
      content: deleteFiles
          ? 'This removes the selected series from Sonarr and deletes their '
                'files from disk.'
          : 'This removes the selected series from Sonarr. Files stay on disk.',
    );
    if (confirmed != true) return null;

    _showLoading(navigator);

    var deleted = 0;
    try {
      for (final id in seriesIds) {
        await repository.deleteSeries(
          id,
          deleteFiles: deleteFiles,
          addExclusion: false,
        );
        deleted++;
      }
      _hideLoading(navigator);
      _ref.invalidate(filteredSeriesProvider);
      return BatchActionResult(
        message:
            'Deleted $deleted series${_plural(deleted)}'
            '${deleteFiles ? ' and files' : ''}',
        refreshCatalog: true,
      );
    } catch (e) {
      _hideLoading(navigator);
      return BatchActionResult(
        message:
            'Deleted $deleted of ${seriesIds.length} '
            'series${_plural(seriesIds.length)} before error: $e',
        refreshCatalog: deleted > 0,
      );
    }
  }

  Future<BatchActionResult?> deleteSeriesFiles(
    BuildContext context,
    List<int> seriesIds,
  ) async {
    final repository = _ref.read(seriesRepositoryProvider);
    if (repository == null) {
      return const BatchActionResult(message: 'No Sonarr instance configured');
    }

    final navigator = Navigator.of(context);
    final confirmed = await _confirm(
      context,
      title:
          'Delete files for ${seriesIds.length} series${_plural(seriesIds.length)}',
      content:
          'This deletes the media files of the selected series from disk. '
          'They stay in Sonarr.',
    );
    if (confirmed != true) return null;

    _showLoading(navigator);

    var filesDeleted = 0;
    try {
      for (final id in seriesIds) {
        filesDeleted += await repository.deleteSeriesFiles(id);
      }
      _hideLoading(navigator);
      return BatchActionResult(
        message: 'Deleted $filesDeleted file${_plural(filesDeleted)}',
        refreshCatalog: true,
      );
    } catch (e) {
      _hideLoading(navigator);
      return BatchActionResult(message: 'Failed to delete files: $e');
    }
  }

  Future<BatchActionResult?> purgeSeriesList(
    BuildContext context,
    List<int> seriesIds,
  ) async {
    final purgeService = _ref.read(purgeServiceProvider);
    final minimumSeedingDays = _ref.read(settingsProvider).minimumSeedingDays;
    final navigator = Navigator.of(context);

    final confirmed = await _confirm(
      context,
      title: 'Purge ${seriesIds.length} series${_plural(seriesIds.length)}',
      content:
          'This permanently removes the selected series from Sonarr, '
          'deletes their files, and deletes all source torrents from '
          'qBittorrent.',
    );
    if (confirmed != true) return null;

    if (!context.mounted) return null;
    SeedingAction? action;
    try {
      action = await resolveSeedingAction(
        context: context,
        minimumSeedingDays: minimumSeedingDays,
        preview: (seconds) async {
          final previews = await Future.wait(
            seriesIds.map(
              (id) => purgeService.previewSeries(
                id,
                minimumSeedingSeconds: seconds,
              ),
            ),
          );
          final all = <Torrent>[];
          final below = <Torrent>[];
          for (final p in previews) {
            all.addAll(p.torrentsToDelete);
            below.addAll(p.belowThreshold);
          }
          return PurgePreview(
            torrentsToDelete: all,
            belowThreshold: below,
            qbittorrentSkipped: previews.any((p) => p.qbittorrentSkipped),
          );
        },
      );
    } catch (e) {
      return BatchActionResult(message: 'Failed to preview: $e');
    }

    if (action == null || action == SeedingAction.cancel) return null;
    _showLoading(navigator);

    try {
      final result = await purgeService.purgeSeriesList(seriesIds);
      _hideLoading(navigator);
      _ref.invalidate(filteredSeriesProvider);
      return BatchActionResult(
        message: result.formatSummary(
          label:
              'Purged ${seriesIds.length} '
              'series${_plural(seriesIds.length)}.',
        ),
        refreshCatalog: true,
      );
    } catch (e) {
      _hideLoading(navigator);
      return BatchActionResult(message: 'Failed to purge: $e');
    }
  }

  // ---- helpers -----------------------------------------------------------

  String _plural(int count) => count == 1 ? '' : 's';

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showLoading(NavigatorState navigator) {
    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _hideLoading(NavigatorState navigator) {
    navigator.pop();
  }
}
