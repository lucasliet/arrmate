import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/media_external_links.dart';
import '../../../../domain/models/models.dart';
import '../../../widgets/media/media_quick_actions_menu.dart';
import '../../../widgets/queue_status_indicator.dart';
import 'movie_poster.dart';

/// A card widget displaying a movie poster and status, utilized in grid view.
class MovieCard extends ConsumerWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Future<void> Function()? onAutomaticSearch;
  final Future<void> Function(Uri uri)? onOpenExternal;
  final bool isSelected;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.onLongPress,
    this.onAutomaticSearch,
    this.onOpenExternal,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 3)
            : BorderSide.none,
      ),
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Positioned.fill(child: MoviePoster(movie: movie)),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.2, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            _buildStatusIcons(context),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    movie.yearLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcons(BuildContext context) {
    return Positioned(
      top: 6,
      left: 6,
      right: 6,
      child: Row(
        children: [
          if (movie.monitored)
            const Icon(Icons.bookmark, size: 20, color: Colors.white)
          else
            Icon(
              Icons.bookmark_border,
              size: 20,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          const Spacer(),
          if (movie.isDownloaded)
            const Icon(Icons.check_circle, size: 20, color: Colors.white)
          else if (movie.monitored)
            if (movie.isWaiting)
              const Icon(Icons.access_time, size: 20, color: Colors.white)
            else
              const Icon(Icons.cancel_outlined, size: 20, color: Colors.white)
          else
            const SizedBox(),
          const SizedBox(width: 4),
          QueueStatusIndicator(movieId: movie.guid),
          if (onAutomaticSearch != null && onOpenExternal != null)
            SizedBox(
              width: 36,
              height: 36,
              child: MediaQuickActionsMenu(
                key: Key('movieQuickActions-${movie.id}'),
                links: MediaExternalLinks.movie(
                  title: movie.title,
                  imdbId: movie.imdbId,
                ),
                onAutomaticSearch: onAutomaticSearch!,
                onOpenExternal: onOpenExternal!,
                iconColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
