import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/purge_service.dart';
import '../../../domain/models/models.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../l10n/error_messages.dart';
import '../../l10n/shared_labels.dart';
import '../../providers/data_providers.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/activity/providers/qbittorrent_provider.dart';
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
/// the movies and series home screens, plus the bulk delete of the torrent
/// list.
///
/// Each method shows the appropriate confirmation dialog (and the seeding
/// warning dialog for Purge), runs the operation with a loading overlay, and
/// returns a [BatchActionResult] for the caller to show in a snackbar. Returns
/// `null` when the user cancels.
class BatchActionsHandler {
  final WidgetRef _ref;
  bool _isLoadingVisible = false;

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
    final l10n = context.l10n;
    final repository = _ref.read(movieRepositoryProvider);
    if (repository == null) {
      return BatchActionResult(message: l10n.sharedNoRadarrInstance);
    }

    final navigator = Navigator.of(context);
    final options = await _confirmDeletion(
      context,
      title: l10n.sharedBatchDeleteMoviesTitle(movieIds.length),
      content: deleteFiles
          ? l10n.sharedBatchDeleteMoviesWithFiles
          : l10n.sharedBatchDeleteMoviesKeepFiles,
    );
    if (options == null) return null;
    if (!context.mounted) return null;

    _showLoading(navigator);

    var deleted = 0;
    try {
      for (final id in movieIds) {
        if (!context.mounted) return null;
        await repository.deleteMovie(
          id,
          deleteFiles: deleteFiles,
          addExclusion: options.addExclusion,
        );
        deleted++;
      }
      if (!context.mounted) return null;
      _hideLoading(navigator);
      _ref.invalidate(moviesProvider);
      return BatchActionResult(
        message: deleteFiles
            ? l10n.sharedBatchDeletedMoviesAndFiles(deleted)
            : l10n.sharedBatchDeletedMovies(deleted),
        refreshCatalog: true,
      );
    } catch (e) {
      if (!context.mounted) return null;
      _hideLoading(navigator);
      return BatchActionResult(
        message: l10n.sharedBatchDeleteMoviesPartial(
          deleted,
          movieIds.length,
          describeError(e, l10n),
        ),
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
    final l10n = context.l10n;
    final repository = _ref.read(movieRepositoryProvider);
    if (repository == null) {
      return BatchActionResult(message: l10n.sharedNoRadarrInstance);
    }

    final navigator = Navigator.of(context);
    final confirmed = await _confirm(
      context,
      title: l10n.sharedBatchDeleteMovieFilesTitle(movieIds.length),
      content: l10n.sharedBatchDeleteMovieFilesContent,
    );
    if (confirmed != true) return null;
    if (!context.mounted) return null;

    _showLoading(navigator);

    var filesDeleted = 0;
    try {
      for (final id in movieIds) {
        if (!context.mounted) return null;
        filesDeleted += await repository.deleteMovieFiles(id);
      }
      if (!context.mounted) return null;
      _hideLoading(navigator);
      return BatchActionResult(
        message: l10n.sharedBatchDeletedFiles(filesDeleted),
        refreshCatalog: true,
      );
    } catch (e) {
      if (!context.mounted) return null;
      _hideLoading(navigator);
      return BatchActionResult(
        message: l10n.sharedBatchDeleteFilesFailed(describeError(e, l10n)),
      );
    }
  }

  /// Batch-purges movies: catalog + files + source torrents, with seeding-time
  /// warning when applicable.
  Future<BatchActionResult?> purgeMovies(
    BuildContext context,
    List<int> movieIds,
  ) async {
    final l10n = context.l10n;
    final purgeService = _ref.read(purgeServiceProvider);
    final minimumSeedingDays = _ref.read(settingsProvider).minimumSeedingDays;
    final navigator = Navigator.of(context);

    final confirmed = await _confirm(
      context,
      title: l10n.sharedBatchPurgeMoviesTitle(movieIds.length),
      content: l10n.sharedBatchPurgeMoviesContent,
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
          final crossSeedCandidates = <Torrent>[];
          final below = <Torrent>[];
          for (final p in previews) {
            all.addAll(p.torrentsToDelete);
            crossSeedCandidates.addAll(p.crossSeedCandidates);
            below.addAll(p.belowThreshold);
          }
          return PurgePreview(
            torrentsToDelete: all,
            crossSeedCandidates: crossSeedCandidates,
            belowThreshold: below,
            qbittorrentSkipped: previews.any((p) => p.qbittorrentSkipped),
          );
        },
      );
    } catch (e) {
      return BatchActionResult(
        message: l10n.sharedBatchPreviewFailed(describeError(e, l10n)),
      );
    }

    if (action == null || action == SeedingAction.cancel) return null;
    if (!context.mounted) return null;
    final Set<String> approvedCrossSeedHashes;
    try {
      approvedCrossSeedHashes = await _resolveCrossSeedApprovals(
        context,
        () => Future.wait(
          movieIds.map(
            (id) => purgeService.previewMovie(
              id,
              minimumSeedingSeconds: minimumSeedingDays * 86400,
            ),
          ),
        ),
        action: action,
        minimumSeedingSeconds: minimumSeedingDays * 86400,
      );
    } catch (e) {
      return BatchActionResult(
        message: l10n.sharedBatchPreviewCrossSeedsFailed(
          describeError(e, l10n),
        ),
      );
    }
    if (!context.mounted) return null;
    _showLoading(navigator);

    try {
      final result = await purgeService.purgeMovies(
        movieIds,
        action: action,
        minimumSeedingSeconds: minimumSeedingDays * 86400,
        approvedCrossSeedHashes: approvedCrossSeedHashes,
      );
      if (!context.mounted) return null;
      _hideLoading(navigator);
      _ref.invalidate(moviesProvider);
      _ref.read(notificationActionsProvider.notifier).refresh();
      return BatchActionResult(
        message: _purgeMessage(
          l10n,
          result,
          total: movieIds.length,
          purgedLabel: l10n.sharedBatchPurgedMovies(movieIds.length),
        ),
        refreshCatalog: true,
      );
    } catch (e) {
      // Catalog entries may be gone already, so the list must not keep them.
      _ref.invalidate(moviesProvider);
      if (!context.mounted) return null;
      _hideLoading(navigator);
      return BatchActionResult(
        message: l10n.sharedBatchPurgeFailed(describeError(e, l10n)),
        refreshCatalog: true,
      );
    }
  }

  /// The snackbar text of a batch purge of [total] items.
  ///
  /// Names what failed when only some items went through, and the cause alone
  /// when none did. [purgedLabel] opens the summary of a purge with no failure.
  String _purgeMessage(
    AppLocalizations l10n,
    PurgeResult result, {
    required int total,
    required String purgedLabel,
  }) {
    if (result.failures.isEmpty) {
      return result.localizedSummary(l10n, label: purgedLabel);
    }
    final error = describeError(result.failures.first.error, l10n);
    final purged = total - result.failures.length;
    if (purged <= 0) return l10n.sharedBatchPurgeFailed(error);
    return result.localizedSummary(
      l10n,
      label: l10n.sharedBatchPurgePartial(purged, total, error),
    );
  }

  /// Batch-sets the monitored flag of the selected movies. Non-destructive,
  /// so no confirmation dialog is shown.
  Future<BatchActionResult?> setMoviesMonitored(
    BuildContext context,
    List<Movie> movies, {
    required bool monitored,
  }) async {
    final l10n = context.l10n;
    final repository = _ref.read(movieRepositoryProvider);
    if (repository == null) {
      return BatchActionResult(message: l10n.sharedNoRadarrInstance);
    }

    final navigator = Navigator.of(context);
    if (!context.mounted) return null;
    _showLoading(navigator);

    var updated = 0;
    try {
      for (final movie in movies) {
        await repository.updateMovie(movie.copyWith(monitored: monitored));
        updated++;
      }
      if (!context.mounted) return null;
      _hideLoading(navigator);
      _ref.invalidate(moviesProvider);
      return BatchActionResult(
        message: monitored
            ? l10n.sharedBatchMonitoredMovies(updated)
            : l10n.sharedBatchUnmonitoredMovies(updated),
        refreshCatalog: true,
      );
    } catch (e) {
      if (!context.mounted) return null;
      _hideLoading(navigator);
      return BatchActionResult(
        message: l10n.sharedBatchUpdateMoviesPartial(
          updated,
          movies.length,
          describeError(e, l10n),
        ),
        refreshCatalog: updated > 0,
      );
    }
  }

  // ---- Series equivalents ------------------------------------------------

  Future<BatchActionResult?> deleteSeriesList(
    BuildContext context,
    List<int> seriesIds, {
    required bool deleteFiles,
  }) async {
    final l10n = context.l10n;
    final repository = _ref.read(seriesRepositoryProvider);
    if (repository == null) {
      return BatchActionResult(message: l10n.seriesNoSonarrInstance);
    }

    final navigator = Navigator.of(context);
    final options = await _confirmDeletion(
      context,
      title: l10n.sharedBatchDeleteSeriesTitle(seriesIds.length),
      content: deleteFiles
          ? l10n.sharedBatchDeleteSeriesWithFiles
          : l10n.sharedBatchDeleteSeriesKeepFiles,
    );
    if (options == null) return null;
    if (!context.mounted) return null;

    _showLoading(navigator);

    var deleted = 0;
    try {
      for (final id in seriesIds) {
        if (!context.mounted) return null;
        await repository.deleteSeries(
          id,
          deleteFiles: deleteFiles,
          addExclusion: options.addExclusion,
        );
        deleted++;
      }
      if (!context.mounted) return null;
      _hideLoading(navigator);
      _ref.invalidate(seriesProvider);
      return BatchActionResult(
        message: deleteFiles
            ? l10n.sharedBatchDeletedSeriesAndFiles(deleted)
            : l10n.sharedBatchDeletedSeries(deleted),
        refreshCatalog: true,
      );
    } catch (e) {
      if (!context.mounted) return null;
      _hideLoading(navigator);
      return BatchActionResult(
        message: l10n.sharedBatchDeleteSeriesPartial(
          deleted,
          seriesIds.length,
          describeError(e, l10n),
        ),
        refreshCatalog: deleted > 0,
      );
    }
  }

  Future<BatchActionResult?> deleteSeriesFiles(
    BuildContext context,
    List<int> seriesIds,
  ) async {
    final l10n = context.l10n;
    final repository = _ref.read(seriesRepositoryProvider);
    if (repository == null) {
      return BatchActionResult(message: l10n.seriesNoSonarrInstance);
    }

    final navigator = Navigator.of(context);
    final confirmed = await _confirm(
      context,
      title: l10n.sharedBatchDeleteSeriesFilesTitle(seriesIds.length),
      content: l10n.sharedBatchDeleteSeriesFilesContent,
    );
    if (confirmed != true) return null;
    if (!context.mounted) return null;

    _showLoading(navigator);

    var filesDeleted = 0;
    try {
      for (final id in seriesIds) {
        if (!context.mounted) return null;
        filesDeleted += await repository.deleteSeriesFiles(id);
      }
      if (!context.mounted) return null;
      _hideLoading(navigator);
      return BatchActionResult(
        message: l10n.sharedBatchDeletedFiles(filesDeleted),
        refreshCatalog: true,
      );
    } catch (e) {
      if (!context.mounted) return null;
      _hideLoading(navigator);
      return BatchActionResult(
        message: l10n.sharedBatchDeleteFilesFailed(describeError(e, l10n)),
      );
    }
  }

  Future<BatchActionResult?> purgeSeriesList(
    BuildContext context,
    List<int> seriesIds,
  ) async {
    final l10n = context.l10n;
    final purgeService = _ref.read(purgeServiceProvider);
    final minimumSeedingDays = _ref.read(settingsProvider).minimumSeedingDays;
    final navigator = Navigator.of(context);

    final confirmed = await _confirm(
      context,
      title: l10n.sharedBatchPurgeSeriesTitle(seriesIds.length),
      content: l10n.sharedBatchPurgeSeriesContent,
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
          final crossSeedCandidates = <Torrent>[];
          final below = <Torrent>[];
          for (final p in previews) {
            all.addAll(p.torrentsToDelete);
            crossSeedCandidates.addAll(p.crossSeedCandidates);
            below.addAll(p.belowThreshold);
          }
          return PurgePreview(
            torrentsToDelete: all,
            crossSeedCandidates: crossSeedCandidates,
            belowThreshold: below,
            qbittorrentSkipped: previews.any((p) => p.qbittorrentSkipped),
          );
        },
      );
    } catch (e) {
      return BatchActionResult(
        message: l10n.sharedBatchPreviewFailed(describeError(e, l10n)),
      );
    }

    if (action == null || action == SeedingAction.cancel) return null;
    if (!context.mounted) return null;
    final Set<String> approvedCrossSeedHashes;
    try {
      approvedCrossSeedHashes = await _resolveCrossSeedApprovals(
        context,
        () => Future.wait(
          seriesIds.map(
            (id) => purgeService.previewSeries(
              id,
              minimumSeedingSeconds: minimumSeedingDays * 86400,
            ),
          ),
        ),
        action: action,
        minimumSeedingSeconds: minimumSeedingDays * 86400,
      );
    } catch (e) {
      return BatchActionResult(
        message: l10n.sharedBatchPreviewCrossSeedsFailed(
          describeError(e, l10n),
        ),
      );
    }
    if (!context.mounted) return null;
    _showLoading(navigator);

    try {
      final result = await purgeService.purgeSeriesList(
        seriesIds,
        action: action,
        minimumSeedingSeconds: minimumSeedingDays * 86400,
        approvedCrossSeedHashes: approvedCrossSeedHashes,
      );
      if (!context.mounted) return null;
      _hideLoading(navigator);
      _ref.invalidate(seriesProvider);
      _ref.read(notificationActionsProvider.notifier).refresh();
      return BatchActionResult(
        message: _purgeMessage(
          l10n,
          result,
          total: seriesIds.length,
          purgedLabel: l10n.sharedBatchPurgedSeries(seriesIds.length),
        ),
        refreshCatalog: true,
      );
    } catch (e) {
      // Catalog entries may be gone already, so the list must not keep them.
      _ref.invalidate(seriesProvider);
      if (!context.mounted) return null;
      _hideLoading(navigator);
      return BatchActionResult(
        message: l10n.sharedBatchPurgeFailed(describeError(e, l10n)),
        refreshCatalog: true,
      );
    }
  }

  /// Batch-sets the monitored flag of the selected series. Season flags are
  /// left as they are, mirroring the unit toggle. Non-destructive, so no
  /// confirmation dialog is shown.
  Future<BatchActionResult?> setSeriesMonitored(
    BuildContext context,
    List<Series> seriesList, {
    required bool monitored,
  }) async {
    final l10n = context.l10n;
    final repository = _ref.read(seriesRepositoryProvider);
    if (repository == null) {
      return BatchActionResult(message: l10n.seriesNoSonarrInstance);
    }

    final navigator = Navigator.of(context);
    if (!context.mounted) return null;
    _showLoading(navigator);

    var updated = 0;
    try {
      for (final series in seriesList) {
        await repository.updateSeries(series.copyWith(monitored: monitored));
        updated++;
      }
      if (!context.mounted) return null;
      _hideLoading(navigator);
      _ref.invalidate(seriesProvider);
      return BatchActionResult(
        message: monitored
            ? l10n.sharedBatchMonitoredSeries(updated)
            : l10n.sharedBatchUnmonitoredSeries(updated),
        refreshCatalog: true,
      );
    } catch (e) {
      if (!context.mounted) return null;
      _hideLoading(navigator);
      return BatchActionResult(
        message: l10n.sharedBatchUpdateSeriesPartial(
          updated,
          seriesList.length,
          describeError(e, l10n),
        ),
        refreshCatalog: updated > 0,
      );
    }
  }

  // ---- Torrents ----------------------------------------------------------

  /// Batch-deletes [torrents] from qBittorrent together with their files on
  /// disk.
  ///
  /// Applies the same seeding-time rule as the library purge: when any torrent
  /// seeded for less than the configured minimum, [showSeedingWarningDialog]
  /// lets the user cancel, keep those torrents seeding, or delete them all.
  Future<BatchActionResult?> deleteTorrentsWithFiles(
    BuildContext context,
    List<Torrent> torrents,
  ) async {
    if (torrents.isEmpty) return null;
    final l10n = context.l10n;
    if (_ref.read(qbittorrentServiceProvider) == null) {
      return BatchActionResult(message: l10n.sharedTorrentsNoQbittorrent);
    }

    final minimumSeedingDays = _ref.read(settingsProvider).minimumSeedingDays;
    final minimumSeconds = minimumSeedingDays * 86400;
    final navigator = Navigator.of(context);

    final confirmed = await _confirm(
      context,
      title: l10n.sharedTorrentsDeleteTitle(torrents.length),
      content: l10n.sharedTorrentsDeleteContent,
    );
    if (confirmed != true) return null;
    if (!context.mounted) return null;

    final belowThreshold = torrents
        .where((t) => isBelowSeedingThreshold(t, minimumSeconds))
        .toList();
    var toDelete = torrents;
    if (belowThreshold.isNotEmpty) {
      final action = await showSeedingWarningDialog(
        context: context,
        belowThreshold: belowThreshold,
        minimumSeedingDays: minimumSeedingDays,
        footnote: belowThreshold.length == torrents.length
            ? l10n.sharedTorrentsKeepSeedingAll
            : l10n.sharedTorrentsKeepSeedingSome,
      );
      if (action == null || action == SeedingAction.cancel) return null;
      if (action == SeedingAction.keepBelowThreshold) {
        toDelete = torrents
            .where((t) => !isBelowSeedingThreshold(t, minimumSeconds))
            .toList();
      }
    }

    final kept = torrents.length - toDelete.length;
    if (toDelete.isEmpty) {
      return BatchActionResult(
        message: kept > 0
            ? l10n.sharedTorrentsNoneDeletedKept(kept)
            : l10n.sharedTorrentsNoneDeleted,
      );
    }
    if (!context.mounted) return null;

    _showLoading(navigator);

    try {
      await _ref
          .read(qbittorrentTorrentsProvider.notifier)
          .deleteTorrents(
            toDelete.map((t) => t.hash).toList(),
            deleteFiles: true,
          );
      if (!context.mounted) return null;
      _hideLoading(navigator);
      return BatchActionResult(
        message: kept > 0
            ? l10n.sharedTorrentsDeletedKept(toDelete.length, kept)
            : l10n.sharedTorrentsDeleted(toDelete.length),
      );
    } catch (e) {
      if (!context.mounted) return null;
      _hideLoading(navigator);
      return BatchActionResult(
        message: l10n.sharedTorrentsDeleteFailed(describeError(e, l10n)),
      );
    }
  }

  // ---- helpers -----------------------------------------------------------

  Future<Set<String>> _resolveCrossSeedApprovals(
    BuildContext context,
    Future<List<PurgePreview>> Function() previews, {
    required SeedingAction action,
    required int minimumSeedingSeconds,
  }) async {
    final candidates = <Torrent>[];
    for (final preview in await previews()) {
      candidates.addAll(preview.crossSeedCandidates);
    }
    if (!context.mounted) return const {};
    return resolveCrossSeedApprovals(
      context: context,
      crossSeedCandidates: candidates,
      action: action,
      minimumSeedingSeconds: minimumSeedingSeconds,
    );
  }

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
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  Future<_BatchDeleteOptions?> _confirmDeletion(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    var addExclusion = false;
    return showDialog<_BatchDeleteOptions>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(content),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: addExclusion,
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.sharedAddImportExclusion),
                subtitle: Text(context.l10n.sharedAddImportExclusionSubtitle),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) {
                  setState(() => addExclusion = value ?? false);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _BatchDeleteOptions(addExclusion: addExclusion),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: Text(context.l10n.commonConfirm),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoading(NavigatorState navigator) {
    if (_isLoadingVisible || !navigator.mounted) return;
    _isLoadingVisible = true;
    showDialog(
      context: navigator.context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ).whenComplete(() => _isLoadingVisible = false);
  }

  void _hideLoading(NavigatorState navigator) {
    if (!_isLoadingVisible || !navigator.mounted) return;
    _isLoadingVisible = false;
    navigator.pop();
  }
}

class _BatchDeleteOptions {
  final bool addExclusion;

  const _BatchDeleteOptions({required this.addExclusion});
}
