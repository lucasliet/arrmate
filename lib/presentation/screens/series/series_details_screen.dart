import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../domain/models/models.dart';
import '../../providers/instances_provider.dart';
import '../../shared/providers/formatted_options_provider.dart';
import '../../widgets/common_widgets.dart';
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
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Series'),
                      content: const Text(
                        'Are you sure you want to delete this series?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await ref
                          .read(seriesControllerProvider(seriesId))
                          .deleteSeries();
                      if (context.mounted) {
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Series deleted')),
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
                      onPressed: series.monitored
                          ? () async {
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
                            }
                          : null,
                      icon: const Icon(Icons.bookmark, size: 18),
                      label: const Text('All'),
                    ),
                    TextButton.icon(
                      onPressed: series.monitored
                          ? () async {
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
                            }
                          : null,
                      icon: const Icon(Icons.bookmark_border, size: 18),
                      label: const Text('None'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSeasonsList(context, ref, series),
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

  Widget _buildSeasonsList(BuildContext context, WidgetRef ref, Series series) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: series.seasons.length,
      itemBuilder: (context, index) {
        final season = series.seasons[index];
        if (season.seasonNumber == 0) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainer,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('Season ${season.seasonNumber}'),
            subtitle: Text('${season.statistics?.episodeCount ?? 0} Episodes'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: (season.statistics?.percentOfEpisodes ?? 0) / 100,
                    backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    season.monitored ? Icons.bookmark : Icons.bookmark_border,
                    color: series.monitored
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  tooltip: season.monitored ? 'Unmonitor' : 'Monitor',
                  onPressed: series.monitored
                      ? () async {
                          try {
                            await ref
                                .read(seriesControllerProvider(seriesId))
                                .toggleSeasonMonitor(
                                  series,
                                  season.seasonNumber,
                                );
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
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      SeasonDetailsScreen(series: series, season: season),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  _InfoItem(this.label, this.value);
}
