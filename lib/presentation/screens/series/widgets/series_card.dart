import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../domain/models/models.dart';
import 'series_poster.dart';

class SeriesCard extends StatelessWidget {
  final Series series;
  final VoidCallback? onTap;

  const SeriesCard({super.key, required this.series, this.onTap});

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
            Positioned.fill(child: SeriesPoster(series: series)),
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
            _buildStatusIndicator(context),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    series.title,
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
                    '${series.year} • ${series.seasonCount} Seasons',
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

  Widget _buildStatusIndicator(BuildContext context) {
    Color color;

    // Logic for Series status varies slightly from Movies.
    // Simplifying for now based on 'monitored' and 'status'.
    if (series.monitored) {
      if (series.status == SeriesStatus.ended) {
        color = Colors.green;
      } else {
        color = Colors.blue;
      }
    } else {
      color = Colors.grey;
    }

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
