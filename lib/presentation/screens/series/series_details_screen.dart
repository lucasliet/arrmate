import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/purge_service.dart';
import '../../../../core/utils/media_external_links.dart';
import '../../../../domain/models/models.dart';
import '../../adaptive/content_layout.dart';
import '../../providers/data_providers.dart';
import '../../providers/instances_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared/providers/formatted_options_provider.dart';
import '../../shared/providers/media_torrents_provider.dart';
import '../../shared/widgets/batch_action_bar.dart';
import '../../shared/widgets/media_torrents_section.dart';
import '../../shared/widgets/releases_sheet.dart';
import '../../shared/widgets/seeding_warning_dialog.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/media/poster_viewer.dart';
import 'providers/series_metadata_provider.dart';
import 'providers/series_provider.dart';
import 'season_details_screen.dart';
import 'series_edit_screen.dart';
import 'widgets/series_poster.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../l10n/labels.dart';

/// Displays detailed information about a specific series, including seasons and options.
class SeriesDetailsScreen extends ConsumerWidget {
  final int seriesId;

  const SeriesDetailsScreen({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesState = ref.watch(seriesDetailsProvider(seriesId));

    return AdaptiveLayout(
      builder: (context) {
        return Scaffold(
          body: seriesState.when(
            data: (series) => _buildContent(context, ref, series),
            error: (error, stack) => Scaffold(
              appBar: AppBar(title: Text(context.l10n.labelError)),
              body: ErrorDisplay(
                message: describeError(error, context.l10n),
                onRetry: () => ref.refresh(seriesDetailsProvider(seriesId)),
              ),
            ),
            loading: () => Scaffold(
              body: LoadingIndicator(
                message: context.l10n.seriesLoadingDetails,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Series series) {
    final isWide = ContentLayout.of(context).hasWideToolbar;
    final instance = ref.watch(currentSonarrInstanceProvider);
    final fanartImage = series.images
        .where((i) => i.coverType == 'fanart')
        .firstOrNull;
    final fanartRemoteUrl = fanartImage?.remoteUrl;
    final fanartLocalUrl = fanartImage?.url;
    final theme = Theme.of(context);

    String? backgroundImageUrl;
    Map<String, String>? backgroundHeaders;

    if (fanartRemoteUrl != null) {
      backgroundImageUrl = fanartRemoteUrl;
    } else if (fanartLocalUrl != null && instance != null) {
      final instanceUrl = instance.effectiveUrl;
      backgroundImageUrl =
          '${instanceUrl.endsWith('/') ? instanceUrl.substring(0, instanceUrl.length - 1) : instanceUrl}$fanartLocalUrl';
      backgroundHeaders = instance.authHeaders;
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: isWide ? 360 : 300,
          pinned: true,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (backgroundImageUrl != null)
                  CachedNetworkImage(
                    imageUrl: backgroundImageUrl,
                    httpHeaders: backgroundHeaders,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  )
                else
                  Container(color: theme.colorScheme.surfaceContainerHighest),
                // Top Vignette for AppBar icons
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3],
                    ),
                  ),
                ),
                // Bottom Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        theme.colorScheme.surface.withValues(alpha: 0.5),
                        theme.colorScheme.surface,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.manage_search),
              tooltip: context.l10n.seriesRefreshAndScan,
              onPressed: () async {
                try {
                  await ref.read(seriesControllerProvider(seriesId)).rescan();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.seriesRefreshScanTriggered),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.commonErrorWithDetails(
                            describeError(e, context.l10n),
                          ),
                        ),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.travel_explore),
              tooltip: context.l10n.commonAutomaticSearch,
              onPressed: () async {
                try {
                  await ref
                      .read(seriesControllerProvider(seriesId))
                      .automaticSearch();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.commonSearchStarted)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.commonErrorWithDetails(
                            describeError(e, context.l10n),
                          ),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
            IconButton(
              key: const Key('seriesMonitorToggle'),
              icon: Icon(
                series.monitored ? Icons.bookmark : Icons.bookmark_border,
              ),
              tooltip: series.monitored
                  ? context.l10n.commonUnmonitor
                  : context.l10n.commonMonitor,
              onPressed: () async {
                try {
                  await ref
                      .read(seriesControllerProvider(seriesId))
                      .toggleMonitor(series);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          series.monitored
                              ? context.l10n.commonUnmonitored
                              : context.l10n.commonMonitored,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.commonErrorWithDetails(
                            describeError(e, context.l10n),
                          ),
                        ),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SeriesEditScreen(series: series),
                      fullscreenDialog: true,
                    ),
                  );
                } else if (value == 'delete') {
                  await _handleDeleteSeries(context, ref, series);
                } else if (value == 'deleteFiles') {
                  await _handleDeleteSeriesFiles(context, ref, series);
                } else if (value == 'purge') {
                  await _handlePurgeSeries(context, ref, series);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 8),
                      Text(context.l10n.commonEdit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'deleteFiles',
                  enabled: series.episodeFileCount > 0,
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep),
                      const SizedBox(width: 8),
                      Text(context.l10n.commonDeleteFiles),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.commonDelete,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'purge',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_forever, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.commonPurge,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: isWide ? 180 : 100,
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: Semantics(
                          button: true,
                          label: context.l10n.seriesViewPoster(series.title),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(radiusMd),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: const Key('viewSeriesPoster'),
                                onTap: () => showPosterViewer(
                                  context: context,
                                  title: series.title,
                                  poster: SeriesPoster(
                                    series: series,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                child: SeriesPoster(series: series),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isWide ? 28 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            series.title,
                            style:
                                (isWide
                                        ? theme.textTheme.headlineMedium
                                        : theme.textTheme.headlineSmall)
                                    ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (series.year > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${series.year} • '
                              '${context.l10n.seriesSeasonCount(series.seasonCount)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          _buildStatusChip(context, series),
                          const SizedBox(height: 8),
                          _buildRatings(context, series),
                          const SizedBox(height: 12),
                          _buildExternalActions(context, series),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (series.overview != null) ...[
                  Text(
                    context.l10n.seriesOverview,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(series.overview!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                ],
                _buildInfoGrid(context, ref, series),
                const SizedBox(height: 24),

                const SizedBox(height: 32),
                OverflowBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  overflowAlignment: OverflowBarAlignment.start,
                  overflowSpacing: 8,
                  children: [
                    Text(
                      context.l10n.seriesSeasons,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          key: const Key('monitorAllSeasonsBtn'),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(seriesControllerProvider(seriesId))
                                  .monitorAllSeasons(series, true);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.seriesAllSeasonsMonitored,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.commonErrorWithDetails(
                                        describeError(e, context.l10n),
                                      ),
                                    ),
                                    backgroundColor: theme.colorScheme.error,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.bookmark, size: 18),
                          label: Text(context.l10n.labelAll),
                        ),
                        TextButton.icon(
                          key: const Key('unmonitorAllSeasonsBtn'),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(seriesControllerProvider(seriesId))
                                  .monitorAllSeasons(series, false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.seriesAllSeasonsUnmonitored,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.commonErrorWithDetails(
                                        describeError(e, context.l10n),
                                      ),
                                    ),
                                    backgroundColor: theme.colorScheme.error,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.bookmark_border, size: 18),
                          label: Text(context.l10n.labelNone),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SeasonsSection(series: series),
                const SizedBox(height: 24),
                MediaTorrentsSection(
                  provider: seriesTorrentsProvider(seriesId),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, Series series) {
    Color color;
    final label = series.status.localizedLabel(context.l10n);

    if (series.status == SeriesStatus.ended) {
      color = Colors.red;
    } else if (series.status == SeriesStatus.continuing) {
      color = Colors.blue;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRatings(BuildContext context, Series series) {
    // Series model might not have ratings obj structure same as Movie yet?
    // Let's check Series model. It has `ratings` field.
    if (series.ratings == null) return const SizedBox();

    return Row(
      children: [
        if (series.ratings!.value > 0) ...[
          const Icon(Icons.star, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            series.ratings!.value.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildExternalActions(BuildContext context, Series series) {
    final links = MediaExternalLinks.series(
      title: series.title,
      tvdbId: series.tvdbId,
      imdbId: series.imdbId,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final link in links)
          ActionChip(
            avatar: const Icon(Icons.open_in_new, size: 18),
            label: Text(link.label),
            onPressed: () => _openExternalUri(context, link.uri),
          ),
      ],
    );
  }

  Future<void> _openExternalUri(BuildContext context, Uri uri) async {
    final l10n = context.l10n;
    try {
      if (uri.scheme != 'https') {
        throw const FormatException('Only HTTPS links are supported');
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('Unable to open link');
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.seriesUnableToOpenLink(describeError(error, l10n)),
          ),
        ),
      );
    }
  }

  Widget _buildInfoGrid(BuildContext context, WidgetRef ref, Series series) {
    final qualityProfilesAsync = ref.watch(seriesQualityProfilesProvider);
    final qualityProfileLabel = qualityProfilesAsync.maybeWhen(
      data: (profiles) =>
          profiles
              .where((p) => p.id == series.qualityProfileId)
              .firstOrNull
              ?.name ??
          series.qualityProfileId.toString(),
      orElse: () => series.qualityProfileId.toString(),
    );

    final items = [
      if (series.network != null)
        _InfoItem(context.l10n.seriesNetwork, series.network!),
      _InfoItem(
        context.l10n.commonStatus,
        series.status.localizedLabel(context.l10n),
      ),
      _InfoItem(context.l10n.commonQualityProfile, qualityProfileLabel),
      if (series.path != null) _InfoItem(context.l10n.seriesPath, series.path!),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ContentLayout(constraints.maxWidth).infoColumnCount;
        final itemWidth = (constraints.maxWidth - 16 * (columns - 1)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _handleDeleteSeries(
    BuildContext context,
    WidgetRef ref,
    Series series,
  ) async {
    final l10n = context.l10n;
    bool deleteFiles = false;
    bool addExclusion = false;
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.seriesDeleteSeries),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.seriesDeleteSeriesConfirm(series.title)),
                const SizedBox(height: 12),
                CheckboxListTile(
                  key: const Key('deleteSeriesAlsoDeleteFiles'),
                  title: Text(l10n.seriesAlsoDeleteFiles),
                  contentPadding: EdgeInsets.zero,
                  value: deleteFiles,
                  onChanged: (val) =>
                      setState(() => deleteFiles = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  key: const Key('deleteSeriesAddImportListExclusion'),
                  title: Text(l10n.seriesPreventReAdd),
                  contentPadding: EdgeInsets.zero,
                  value: addExclusion,
                  onChanged: (val) =>
                      setState(() => addExclusion = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                child: Text(l10n.commonDelete),
              ),
            ],
          );
        },
      ),
    );

    if (confirm != true) return;

    try {
      await ref
          .read(seriesControllerProvider(seriesId))
          .deleteSeries(deleteFiles: deleteFiles, addExclusion: addExclusion);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleteFiles ? l10n.seriesAndFilesDeleted : l10n.seriesDeleted,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.seriesDeleteFailed(describeError(e, l10n))),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteSeriesFiles(
    BuildContext context,
    WidgetRef ref,
    Series series,
  ) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commonDeleteFiles),
        content: Text(l10n.seriesDeleteFilesConfirm(series.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final count = await ref
          .read(seriesMetadataControllerProvider(seriesId))
          .deleteAllFiles();
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? l10n.seriesNoFilesToDelete
                : l10n.seriesDeletedFilesCount(count),
          ),
        ),
      );
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.seriesDeleteFilesFailed(describeError(e, l10n))),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  /// Purge removes the series from Sonarr (catalog + files), removes any
  /// active queue items for all episodes, and deletes the source torrents
  /// (plus cross-seed duplicates) from qBittorrent with their files.
  Future<void> _handlePurgeSeries(
    BuildContext context,
    WidgetRef ref,
    Series series,
  ) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.seriesPurgeSeries),
        content: Text(l10n.seriesPurgeSeriesConfirm(series.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.commonPurge),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final purgeService = ref.read(purgeServiceProvider);
    final minimumSeedingDays = ref.read(settingsProvider).minimumSeedingDays;

    SeedingAction? action;
    var approvedCrossSeedHashes = <String>{};
    try {
      action = await resolveSeedingAction(
        context: context,
        minimumSeedingDays: minimumSeedingDays,
        preview: (seconds) => purgeService.previewSeries(
          series.id,
          minimumSeedingSeconds: seconds,
        ),
      );
      if (action != null && action != SeedingAction.cancel && context.mounted) {
        final preview = await purgeService.previewSeries(
          series.id,
          minimumSeedingSeconds: minimumSeedingDays * 86400,
        );
        if (!context.mounted) return;
        approvedCrossSeedHashes = await resolveCrossSeedApprovals(
          context: context,
          crossSeedCandidates: preview.crossSeedCandidates,
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.seriesPreviewFailed(describeError(e, l10n))),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    if (action == null || action == SeedingAction.cancel) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final result = await purgeService.purgeSeriesWithAction(
        series.id,
        action: action,
        minimumSeedingSeconds: minimumSeedingDays * 86400,
        approvedCrossSeedHashes: approvedCrossSeedHashes,
      );
      navigator.pop();
      ref.invalidate(seriesProvider);
      ref.read(notificationActionsProvider.notifier).refresh();
      if (context.mounted) {
        context.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              result.localizedSummary(l10n, label: l10n.seriesPurged),
            ),
          ),
        );
      }
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.seriesPurgeFailed(describeError(e, l10n))),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }
}

class _InfoItem {
  final String label;
  final String value;
  _InfoItem(this.label, this.value);
}

/// Seasons list with multi-select and batch actions (unmonitor / delete files
/// / purge) for the series details screen.
class _SeasonsSection extends ConsumerStatefulWidget {
  final Series series;

  const _SeasonsSection({required this.series});

  @override
  ConsumerState<_SeasonsSection> createState() => _SeasonsSectionState();
}

class _SeasonsSectionState extends ConsumerState<_SeasonsSection> {
  final Set<int> _selectedSeasons = {};
  bool _isLoadingVisible = false;

  bool get _isSelecting => _selectedSeasons.isNotEmpty;

  void _toggleSelection(int seasonNumber) {
    setState(() {
      if (_selectedSeasons.contains(seasonNumber)) {
        _selectedSeasons.remove(seasonNumber);
      } else {
        _selectedSeasons.add(seasonNumber);
      }
    });
  }

  void _clearSelection() => setState(_selectedSeasons.clear);

  void _selectAll() {
    setState(() {
      _selectedSeasons
        ..clear()
        ..addAll(
          widget.series.seasons
              .where((s) => s.seasonNumber != 0)
              .map((s) => s.seasonNumber),
        );
    });
  }

  Future<void> _handleBatchUnmonitor() async {
    final l10n = context.l10n;
    final series = widget.series;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final controller = ref.read(seriesControllerProvider(series.id));
    _showLoading(navigator);
    try {
      final selectedSeasons = _selectedSeasons.toSet();
      await controller.setSeasonsMonitored(
        series,
        selectedSeasons,
        monitored: false,
      );
      if (!mounted) return;
      _hideLoading(navigator);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.seriesUnmonitoredSeasons(_selectedSeasons.length)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _hideLoading(navigator);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.commonErrorWithDetails(describeError(e, l10n))),
        ),
      );
    }
    _clearSelection();
  }

  Future<void> _handleBatchDeleteFiles() async {
    final l10n = context.l10n;
    final series = widget.series;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final metadataController = ref.read(
      seriesMetadataControllerProvider(series.id),
    );
    final confirmed = await _confirm(
      title: l10n.seriesDeleteFilesForSeasons(_selectedSeasons.length),
      content: l10n.seriesDeleteSeasonsFilesContent,
    );
    if (confirmed != true) return;
    if (!mounted) return;

    _showLoading(navigator);
    try {
      var filesDeleted = 0;
      for (final seasonNumber in _selectedSeasons.toList()) {
        filesDeleted += await metadataController.deleteAllFiles(
          seasonNumber: seasonNumber,
        );
      }
      if (!mounted) return;
      _hideLoading(navigator);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.seriesDeletedFilesCount(filesDeleted))),
      );
    } catch (e) {
      if (!mounted) return;
      _hideLoading(navigator);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.seriesDeleteFilesFailed(describeError(e, l10n))),
        ),
      );
    }
    _clearSelection();
  }

  Future<void> _handleSeasonAutomaticSearch(
    Series series,
    Season season,
  ) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.seriesSearchingFor(
            l10n.seriesTitleWithSeason(series.title, season.seasonNumber),
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      await ref
          .read(seriesControllerProvider(series.id))
          .seasonAutomaticSearch(season.seasonNumber);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.commonSearchStarted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.seriesSearchFailed(describeError(e, l10n))),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  void _showSeasonReleases(Series series, Season season) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReleasesSheet(
        id: 0,
        isMovie: false,
        title: context.l10n.seriesTitleWithSeason(
          series.title,
          season.seasonNumber,
        ),
        episodeCode: context.l10n.formatSeason(season.seasonNumber),
        seriesId: series.id,
        seasonNumber: season.seasonNumber,
        originalLanguage: series.originalLanguage?.name,
      ),
    );
  }

  Future<void> _handleBatchSearch() async {
    final l10n = context.l10n;
    final series = widget.series;
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(seriesControllerProvider(series.id));
    final navigator = Navigator.of(context);

    _showLoading(navigator);
    try {
      await Future.wait(
        _selectedSeasons.map(
          (seasonNumber) => controller.seasonAutomaticSearch(seasonNumber),
        ),
      );
      if (!mounted) return;
      _hideLoading(navigator);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.seriesSearchStartedForSeasons(_selectedSeasons.length),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _hideLoading(navigator);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.seriesSearchFailed(describeError(e, l10n))),
        ),
      );
    }
    _clearSelection();
  }

  Future<void> _handleBatchPurge() async {
    final l10n = context.l10n;
    final series = widget.series;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final purgeService = ref.read(purgeServiceProvider);
    final minimumSeedingDays = ref.read(settingsProvider).minimumSeedingDays;
    final repository = ref.read(seriesRepositoryProvider);

    final confirmed = await _confirm(
      title: l10n.seriesPurgeSeasonsTitle(_selectedSeasons.length),
      content: l10n.seriesPurgeSeasonsContent,
    );
    if (confirmed != true) return;
    if (!mounted) return;

    if (repository == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.seriesNoSonarrInstance)),
      );
      return;
    }

    final Map<int, List<int>> episodeIdsBySeason = {};
    // Every episode of the selected seasons, with or without a file: a pack
    // covered by the selection as a whole is deleted without asking, one
    // reaching other seasons needs its own approval.
    final scopeEpisodeIds = <int>{};
    try {
      final episodes = await repository.getEpisodes(series.id);
      scopeEpisodeIds.addAll(
        episodes
            .where((e) => _selectedSeasons.contains(e.seasonNumber))
            .map((e) => e.id),
      );
      for (final seasonNumber in _selectedSeasons) {
        episodeIdsBySeason[seasonNumber] = episodes
            .where(
              (e) =>
                  e.seasonNumber == seasonNumber &&
                  e.hasFile &&
                  e.episodeFileId != null &&
                  e.episodeFileId! > 0,
            )
            .map((e) => e.id)
            .toList();
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.seriesLoadEpisodesFailed(describeError(e, l10n))),
        ),
      );
      return;
    }

    if (!mounted) return;
    SeedingAction? action;
    try {
      action = await resolveSeedingAction(
        context: context,
        minimumSeedingDays: minimumSeedingDays,
        preview: (seconds) async {
          final previews = await Future.wait(
            _selectedSeasons.map(
              (sn) => purgeService.previewSeason(
                series.id,
                episodeIdsBySeason[sn] ?? const [],
                minimumSeedingSeconds: seconds,
                scopeEpisodeIds: scopeEpisodeIds,
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
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.seriesPreviewFailed(describeError(e, l10n))),
        ),
      );
      return;
    }

    if (action == null || action == SeedingAction.cancel) return;
    if (!mounted) return;

    final Set<String> approvedCrossSeedHashes;
    final Set<String> approvedSharedPackHashes;
    try {
      final previews = await Future.wait(
        _selectedSeasons.map(
          (sn) => purgeService.previewSeason(
            series.id,
            episodeIdsBySeason[sn] ?? const [],
            minimumSeedingSeconds: minimumSeedingDays * 86400,
            scopeEpisodeIds: scopeEpisodeIds,
          ),
        ),
      );
      if (!mounted) return;
      approvedCrossSeedHashes = await resolveCrossSeedApprovals(
        context: context,
        crossSeedCandidates: [
          for (final preview in previews) ...preview.crossSeedCandidates,
        ],
      );
      if (!mounted) return;
      approvedSharedPackHashes = await resolveSharedPackApprovals(
        context: context,
        sharedPackCandidates: [
          for (final preview in previews) ...preview.sharedPackCandidates,
        ],
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.seriesPreviewCrossSeedsFailed(describeError(e, l10n)),
          ),
        ),
      );
      return;
    }
    if (!mounted) return;

    _showLoading(navigator);
    try {
      var filesDeleted = 0;
      final hashesDeleted = <String>{};
      for (final seasonNumber in _selectedSeasons.toList()) {
        final result = await purgeService.purgeSeason(
          series.id,
          seasonNumber,
          episodeIdsBySeason[seasonNumber] ?? const [],
          action: action,
          minimumSeedingSeconds: minimumSeedingDays * 86400,
          approvedCrossSeedHashes: approvedCrossSeedHashes,
          scopeEpisodeIds: scopeEpisodeIds,
          approvedSharedPackHashes: approvedSharedPackHashes,
        );
        filesDeleted += result.mediaFilesDeleted;
        hashesDeleted.addAll(result.torrentHashesDeleted);
      }
      if (!mounted) return;
      _hideLoading(navigator);
      ref.read(notificationActionsProvider.notifier).refresh();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.seriesPurgedSeasonsSummary(
              _selectedSeasons.length,
              filesDeleted,
              hashesDeleted.length,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _hideLoading(navigator);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.seriesPurgeFailed(describeError(e, l10n)))),
      );
    }
    _clearSelection();
  }

  Future<bool?> _confirm({required String title, required String content}) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.commonConfirm),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final series = widget.series;
    return Column(
      children: [
        if (_isSelecting)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  context.l10n.seriesSelectedCount(_selectedSeasons.length),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectAll,
                  child: Text(context.l10n.labelAll),
                ),
                TextButton(
                  onPressed: _clearSelection,
                  child: Text(context.l10n.labelNone),
                ),
              ],
            ),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: series.seasons.length,
          itemBuilder: (context, index) {
            final season = series.seasons[index];
            if (season.seasonNumber == 0) {
              return const SizedBox.shrink();
            }

            final isSelected = _selectedSeasons.contains(season.seasonNumber);
            final theme = Theme.of(context);
            return Card(
              elevation: 0,
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : theme.colorScheme.surfaceContainer,
              shape: isSelected
                  ? RoundedRectangleBorder(
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(context.l10n.formatSeason(season.seasonNumber)),
                subtitle: Text(
                  context.l10n.seriesEpisodeCount(
                    season.statistics?.episodeCount ?? 0,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value:
                            (season.statistics?.percentOfEpisodes ?? 0) / 100,
                        backgroundColor: theme.colorScheme.surfaceDim,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      key: Key('seasonBookmark_${season.seasonNumber}'),
                      icon: Icon(
                        season.monitored
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: season.monitored
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      tooltip: season.monitored
                          ? context.l10n.commonUnmonitor
                          : context.l10n.commonMonitor,
                      onPressed: () async {
                        try {
                          await ref
                              .read(seriesControllerProvider(series.id))
                              .toggleSeasonMonitor(series, season.seasonNumber);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  season.monitored
                                      ? context.l10n.commonUnmonitored
                                      : context.l10n.commonMonitored,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.l10n.commonErrorWithDetails(
                                    describeError(e, context.l10n),
                                  ),
                                ),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    PopupMenuButton<String>(
                      key: Key('seasonSearchMenu_${season.seasonNumber}'),
                      icon: const Icon(Icons.more_vert),
                      tooltip: context.l10n.seriesSeasonActions,
                      onSelected: (value) {
                        if (value == 'automatic') {
                          _handleSeasonAutomaticSearch(series, season);
                        } else if (value == 'interactive') {
                          _showSeasonReleases(series, season);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'automatic',
                          child: ListTile(
                            leading: const Icon(Icons.travel_explore),
                            title: Text(context.l10n.commonAutomaticSearch),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'interactive',
                          child: ListTile(
                            leading: const Icon(Icons.troubleshoot),
                            title: Text(context.l10n.commonInteractiveSearch),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: _isSelecting
                    ? () => _toggleSelection(season.seasonNumber)
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SeasonDetailsScreen(
                              series: series,
                              season: season,
                            ),
                          ),
                        );
                      },
                onLongPress: () => _toggleSelection(season.seasonNumber),
              ),
            );
          },
        ),
        if (_isSelecting)
          BatchActionBar(
            selectedCount: _selectedSeasons.length,
            actions: [
              BatchAction(
                icon: Icons.travel_explore,
                label: context.l10n.commonSearch,
                onPressed: _handleBatchSearch,
              ),
              BatchAction(
                icon: Icons.bookmark_border,
                label: context.l10n.commonUnmonitor,
                onPressed: _handleBatchUnmonitor,
              ),
              BatchAction(
                icon: Icons.delete_outline,
                label: context.l10n.commonDelete,
                isDestructive: true,
                submenu: [
                  BatchAction(
                    icon: Icons.delete_sweep,
                    label: context.l10n.commonDeleteFiles,
                    isDestructive: true,
                    onPressed: _handleBatchDeleteFiles,
                  ),
                  BatchAction(
                    icon: Icons.delete_forever,
                    label: context.l10n.commonPurge,
                    isDestructive: true,
                    onPressed: _handleBatchPurge,
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
