import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/playback_launch_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../providers/instances_provider.dart';
import '../../movies/widgets/movie_poster.dart';
import '../../series/widgets/series_poster.dart';
import '../providers/watching_provider.dart';

/// Card widget displaying an in-progress Jellyfin item matched to the library.
///
/// Tapping the card resumes playback in the in-app player, while the trailing
/// library action opens the corresponding Movie or Series details screen.
class WatchingListItem extends ConsumerWidget {
  /// Matched Continue Watching entry to render.
  final WatchingItem item;

  /// Creates a [WatchingListItem].
  const WatchingListItem({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subtitle = item.subtitle;
    final timeLabel = _buildTimeLabel();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      child: InkWell(
        onTap: () => _resumePlayback(context, ref),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 70, height: 105, child: _buildPoster()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.displayTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Open in library',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: const Icon(Icons.open_in_new, size: 20),
                          onPressed: () => _openInLibrary(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        if (timeLabel != null)
                          Expanded(
                            child: Text(
                              timeLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else
                          const Spacer(),
                        Text(
                          formatPercentage(item.progress * 100),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: item.progress,
                        backgroundColor: theme.colorScheme.surfaceDim,
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.primary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster() {
    if (item.movie != null) {
      return MoviePoster(movie: item.movie!, instance: item.mediaInstance);
    }
    if (item.series != null) {
      return SeriesPoster(series: item.series!, instance: item.mediaInstance);
    }
    return const SizedBox.shrink();
  }

  String? _buildTimeLabel() {
    final posSeconds = item.positionDuration.inSeconds;
    final runSeconds = item.totalDuration?.inSeconds ?? 0;
    if (posSeconds <= 0) return null;
    final watched = formatDurationSeconds(posSeconds);
    if (runSeconds <= 0) return watched;
    final total = formatDurationSeconds(runSeconds);
    return '$watched / $total';
  }

  Future<void> _resumePlayback(BuildContext context, WidgetRef ref) async {
    await ref
        .read(playbackLaunchServiceProvider)
        .playItem(
          context,
          ref,
          item: item.jellyfinItem,
          title: item.playbackTitle,
        );
    ref.invalidate(watchingItemsProvider);
  }

  Future<void> _openInLibrary(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(instancesProvider.notifier)
          .selectInstance(item.mediaInstance.type, item.mediaInstance.id);
    } catch (_) {}
    if (!context.mounted) return;

    if (item.movie != null) {
      context.go('/movies/${item.movie!.id}');
      return;
    }
    if (item.series != null) {
      context.go('/series/${item.series!.id}');
    }
  }
}
