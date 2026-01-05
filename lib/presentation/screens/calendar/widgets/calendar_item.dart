import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/calendar_provider.dart';

class CalendarItem extends StatelessWidget {
  final CalendarEvent event;

  const CalendarItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMovie = event.isMovie;
    final color = isMovie ? Colors.blue : Colors.purple;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      child: InkWell(
        onTap: () {
          if (isMovie && event.movie != null) {
            context.go('/movies/${event.movie!.id}');
          } else if (!isMovie && event.episode?.seriesId != null) {
            // Ideally go to episode details, but series details for now
            context.go('/series/${event.episode!.seriesId}');
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              height: 100,
              child: event.movie?.remotePoster != null
                  ? CachedNetworkImage(
                      imageUrl: event.movie!.remotePoster!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          isMovie ? Icons.movie_outlined : Icons.tv_outlined,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        isMovie ? Icons.movie_outlined : Icons.tv_outlined,
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
}
