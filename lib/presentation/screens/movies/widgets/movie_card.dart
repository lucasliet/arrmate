import 'package:flutter/material.dart';

import '../../../../domain/models/models.dart';
import '../../../../core/constants/app_constants.dart';
import 'movie_poster.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;

  const MovieCard({super.key, required this.movie, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
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
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.5, 0.7, 1.0],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Monitored Status
          if (movie.monitored)
            const Icon(Icons.bookmark, size: 20, color: Colors.white)
          else
            Icon(
              Icons.bookmark_border,
              size: 20,
              color: Colors.white.withValues(alpha: 0.7),
            ),

          // Right: Download Status
          if (movie.isDownloaded)
            const Icon(Icons.check_circle, size: 20, color: Colors.white)
          else if (movie.monitored)
            if (movie.isWaiting)
              const Icon(Icons.access_time, size: 20, color: Colors.white)
            else
              const Icon(Icons.cancel_outlined, size: 20, color: Colors.white)
          else
            const SizedBox(),
        ],
      ),
    );
  }
}
