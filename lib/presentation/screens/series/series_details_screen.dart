import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/purge_service.dart';
import '../../../../domain/models/models.dart';
import '../../providers/data_providers.dart';
import '../../providers/instances_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared/providers/formatted_options_provider.dart';
import '../../shared/widgets/batch_action_bar.dart';
import '../../shared/widgets/seeding_warning_dialog.dart';
import '../../widgets/common_widgets.dart';
import 'providers/series_metadata_provider.dart';
import 'providers/series_provider.dart';
import 'widgets/series_poster.dart';

import 'season_details_screen.dart';
import 'series_edit_screen.dart';

/// Displays detailed information about a specific series, including seasons and options.
class SeriesDetailsScreen extends ConsumerWidget {
  final int seriesId;

  const SeriesDetailsScreen({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesState = ref.watch(seriesDetailsProvider(seriesId));

    return Scaffold(
      body: seriesState.when(
        data: (series) => _buildContent(context, ref, series),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: ErrorDisplay(
            message: error.toString(),
            onRetry: () => ref.refresh(seriesDetailsProvider(seriesId)),
          ),
        ),
        loading: () => const Scaffold(
          body: LoadingIndicator(message: 'Loading details...'),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Series series) {
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
      backgroundImageUrl =
          '${instance.url.endsWith('/') ? instance.url.substring(0, instance.url.length - 1) : instance.url}$fanartLocalUrl';
      backgroundHeaders = instance.authHeaders;
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
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
              tooltip: 'Refresh & Scan',
              onPressed: () async {
                try {
                  await ref.read(seriesControllerProvider(seriesId)).rescan();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Refresh & Scan triggered')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.travel_explore),
              tooltip: 'Automatic Search',
              onPressed: () async {
                try {
                  await ref
                      .read(seriesControllerProvider(seriesId))
                      .automaticSearch();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search started')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
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
              tooltip: series.monitored ? 'Unmonitor' : 'Monitor',
              onPressed: () async {
                try {
                  await ref
                      .read(seriesControllerProvider(seriesId))
                      .toggleMonitor(series);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          series.monitored ? 'Unmonitored' : 'Monitored',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
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
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'deleteFiles',
                  enabled: series.episodeFileCount > 0,
                  child: const Row(
                    children: [
                      Icon(Icons.delete_sweep),
                      SizedBox(width: 8),
                      Text('Delete files'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'purge',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Purge', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(radiusMd),
                          child: SeriesPoster(series: series),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            series.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (series.year > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${series.year} • ${series.seasonCount} Seasons',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          _buildStatusChip(context, series),
                          const SizedBox(height: 8),
                          _buildRatings(context, series),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (series.overview != null) ...[
                  Text(
                    'Overview',
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
                Row(
                  children: [
                    Text(
                      'Seasons',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      key: const Key('monitorAllSeasonsBtn'),
                      onPressed: () async {
                        try {
                          await ref
                              .read(seriesControllerProvider(seriesId))
                              .monitorAllSeasons(series, true);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All seasons monitored'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.bookmark, size: 18),
                      label: const Text('All'),
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
                              const SnackBar(
                                content: Text('All seasons unmonitored'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.bookmark_border, size: 18),
                      label: const Text('None'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SeasonsSection(series: series),
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
    String label = series.status.name; // Use Enum name for now

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
      if (series.network != null) _InfoItem('Network', series.network!),
      _InfoItem('Status', series.status.name),
      _InfoItem('Quality Profile', qualityProfileLabel),
      if (series.path != null) _InfoItem('Path', series.path!),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items.map((item) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 48) / 2,
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
              Text(item.value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleDeleteSeries(
    BuildContext context,
    WidgetRef ref,
    Series series,
  ) async {
    bool deleteFiles = false;
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Delete Series'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete "${series.title}"?'),
                const SizedBox(height: 12),
                CheckboxListTile(
                  key: const Key('deleteSeriesAlsoDeleteFiles'),
                  title: const Text('Also delete files from disk'),
                  contentPadding: EdgeInsets.zero,
                  value: deleteFiles,
                  onChanged: (val) =>
                      setState(() => deleteFiles = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
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
                child: const Text('Delete'),
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
          .deleteSeries(deleteFiles: deleteFiles);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleteFiles ? 'Series and files deleted' : 'Series deleted',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
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
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete files'),
        content: Text(
          'Delete all files for "${series.title}"? '
          'This removes every episode file from disk; the series stays in Sonarr.',
        ),
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
            child: const Text('Delete'),
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
                ? 'No files to delete'
                : 'Deleted $count file${count == 1 ? '' : 's'}',
          ),
        ),
      );
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete files: $e'),
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
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purge series'),
        content: Text(
          'This will permanently remove "${series.title}" and all its '
          'episodes from Sonarr, delete its media files, and delete all '
          'source torrents (plus cross-seed duplicates) from qBittorrent. '
          'Frees disk space used by hardlinked data.',
        ),
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
            child: const Text('Purge'),
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
    try {
      action = await resolveSeedingAction(
        context: context,
        minimumSeedingDays: minimumSeedingDays,
        preview: (seconds) => purgeService.previewSeries(
          series.id,
          minimumSeedingSeconds: seconds,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to preview: $e'),
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
      );
      navigator.pop();
      ref.invalidate(seriesProvider);
      ref.read(notificationActionsProvider.notifier).refresh();
      if (context.mounted) {
        context.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.formatSummary(label: 'Series purged.')),
          ),
        );
      }
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to purge: $e'),
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
    final series = widget.series;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final controller = ref.read(seriesControllerProvider(series.id));
    _showLoading(navigator);
    try {
      for (final seasonNumber in _selectedSeasons.toList()) {
        final target = series.seasons.firstWhere(
          (s) => s.seasonNumber == seasonNumber,
        );
        if (target.monitored) {
          await controller.toggleSeasonMonitor(series, seasonNumber);
        }
      }
      _hideLoading(navigator);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Unmonitored ${_selectedSeasons.length} '
              'season${_selectedSeasons.length == 1 ? '' : 's'}',
            ),
          ),
        );
      }
    } catch (e) {
      _hideLoading(navigator);
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    _clearSelection();
  }

  Future<void> _handleBatchDeleteFiles() async {
    final series = widget.series;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final metadataController = ref.read(
      seriesMetadataControllerProvider(series.id),
    );
    final confirmed = await _confirm(
      title:
          'Delete files for ${_selectedSeasons.length} '
          'season${_selectedSeasons.length == 1 ? '' : 's'}',
      content:
          'This deletes the episode files of the selected seasons from '
          'disk. The series stays in Sonarr.',
    );
    if (confirmed != true) return;

    _showLoading(navigator);
    try {
      var filesDeleted = 0;
      for (final seasonNumber in _selectedSeasons.toList()) {
        filesDeleted += await metadataController.deleteAllFiles(
          seasonNumber: seasonNumber,
        );
      }
      _hideLoading(navigator);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Deleted $filesDeleted file${filesDeleted == 1 ? '' : 's'}',
            ),
          ),
        );
      }
    } catch (e) {
      _hideLoading(navigator);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to delete files: $e')),
        );
      }
    }
    _clearSelection();
  }

  Future<void> _handleBatchPurge() async {
    final series = widget.series;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final purgeService = ref.read(purgeServiceProvider);
    final minimumSeedingDays = ref.read(settingsProvider).minimumSeedingDays;
    final repository = ref.read(seriesRepositoryProvider);

    final confirmed = await _confirm(
      title:
          'Purge ${_selectedSeasons.length} '
          'season${_selectedSeasons.length == 1 ? '' : 's'}',
      content:
          'This deletes the episode files of the selected seasons and '
          'their source torrents from qBittorrent. The series stays in Sonarr.',
    );
    if (confirmed != true) return;

    if (repository == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No Sonarr instance configured')),
      );
      return;
    }

    final Map<int, List<int>> episodeIdsBySeason = {};
    try {
      final episodes = await repository.getEpisodes(series.id);
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
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to load episodes: $e')),
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
      messenger.showSnackBar(SnackBar(content: Text('Failed to preview: $e')));
      return;
    }

    if (action == null || action == SeedingAction.cancel) return;

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
        );
        filesDeleted += result.mediaFilesDeleted;
        hashesDeleted.addAll(result.torrentHashesDeleted);
      }
      _hideLoading(navigator);
      ref.read(notificationActionsProvider.notifier).refresh();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Purged ${_selectedSeasons.length} '
              'season${_selectedSeasons.length == 1 ? '' : 's'}: '
              '$filesDeleted file${filesDeleted == 1 ? '' : 's'}, '
              '${hashesDeleted.length} torrent${hashesDeleted.length == 1 ? '' : 's'}.',
            ),
          ),
        );
      }
    } catch (e) {
      _hideLoading(navigator);
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Failed to purge: $e')));
      }
    }
    _clearSelection();
  }

  Future<bool?> _confirm({required String title, required String content}) {
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
      useRootNavigator: false,
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
                  '${_selectedSeasons.length} selected',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const Spacer(),
                TextButton(onPressed: _selectAll, child: const Text('All')),
                TextButton(
                  onPressed: _clearSelection,
                  child: const Text('None'),
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
                title: Text('Season ${season.seasonNumber}'),
                subtitle: Text(
                  '${season.statistics?.episodeCount ?? 0} Episodes',
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
                    const SizedBox(width: 12),
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
                      tooltip: season.monitored ? 'Unmonitor' : 'Monitor',
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
                                      ? 'Unmonitored'
                                      : 'Monitored',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
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
                icon: Icons.bookmark_border,
                label: 'Unmonitor',
                onPressed: _handleBatchUnmonitor,
              ),
              BatchAction(
                icon: Icons.delete_sweep,
                label: 'Delete files',
                isDestructive: true,
                onPressed: _handleBatchDeleteFiles,
              ),
              BatchAction(
                icon: Icons.delete_forever,
                label: 'Purge',
                isDestructive: true,
                onPressed: _handleBatchPurge,
              ),
            ],
          ),
      ],
    );
  }
}
