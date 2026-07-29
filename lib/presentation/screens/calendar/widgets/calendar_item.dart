import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../providers/instances_provider.dart';
import '../../../widgets/instance_origin_badge.dart';
import '../../../widgets/queue_status_indicator.dart';
import '../providers/calendar_provider.dart';

/// A card widget displaying a single calendar event with poster and details.
class CalendarItem extends ConsumerWidget {
  /// The calendar event to display.
  final CalendarEvent event;

  const CalendarItem({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = event.type.getColor(context);
    final posterUrl = event.movie?.remotePoster ?? event.series?.remotePoster;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      child: InkWell(
        onTap: () => _openDetails(context, ref),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              height: 100,
              child: posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          event.type.icon,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        event.type.icon,
                        color: theme.colorScheme.outline,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat(
                            'HH:mm',
                          ).format(event.releaseDate.toLocal()),
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(event.type.icon, size: 12, color: color),
                              const SizedBox(width: 4),
                              Text(
                                event.type.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InstanceOriginBadge(
                          instanceId: event.instanceId,
                          instanceType: event.instanceType,
                        ),
                        QueueStatusIndicator(
                          movieId: event.movie?.guid,
                          seriesId: event.series?.id,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 4, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetails(BuildContext context, WidgetRef ref) async {
    try {
      final instanceId = event.instanceId;
      final instanceType = event.instanceType;
      if (instanceId != null && instanceType != null) {
        await ref
            .read(instancesProvider.notifier)
            .selectInstance(instanceType, instanceId);
      }
      if (!context.mounted) {
        return;
      }
      if (event.isMovie && event.movie != null) {
        context.go('/movies/${event.movie!.id}');
      } else if (event.isEpisode && event.episode?.seriesId != null) {
        final seriesId = event.episode!.seriesId;
        final episode = event.episode;
        if (episode != null &&
            episode.seasonNumber >= 0 &&
            episode.episodeNumber > 0) {
          context.go(
            '/series/$seriesId/season/${episode.seasonNumber}/episode/${episode.id}',
          );
        } else if (episode?.seasonNumber != null) {
          context.go('/series/$seriesId/season/${episode!.seasonNumber}');
        } else {
          context.go('/series/$seriesId');
        }
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open item: $error')));
    }
  }
}
