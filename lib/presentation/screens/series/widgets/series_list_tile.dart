import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../domain/models/models.dart';
import '../../../../core/utils/formatters.dart';

/// A list tile widget for displaying series details in a list view.
class SeriesListTile extends StatelessWidget {
  const SeriesListTile({super.key, required this.series, this.onTap});

  final Series series;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(width: 80, height: 120, child: _buildPoster(context)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIcons(context),
                    const SizedBox(height: 4),
                    Text(
                      series.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildSubtitle(context),
                    const SizedBox(height: 4),
                    _buildInfo(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context) {
    final posterUrl = series.remotePoster;

    if (posterUrl == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.tv_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: posterUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.tv_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final theme = Theme.of(context);
    final year = series.yearLabel;
    final runtime = series.runtime > 0 ? formatRuntime(series.runtime) : null;

    return Row(
      children: [
        Text(
          year,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (runtime != null && runtime.isNotEmpty) ...[
          Text(
            ' • ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            runtime,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    final theme = Theme.of(context);
    final size = series.statistics != null && series.statistics!.sizeOnDisk > 0
        ? formatBytes(series.statistics!.sizeOnDisk)
        : null;

    return Row(
      children: [
        Text(
          '${series.seasonCount} Seasons',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (size != null) ...[
          Text(
            ' • ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            size,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIcons(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          series.monitored ? Icons.bookmark : Icons.bookmark_border,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        if (series.isDownloaded)
          const Icon(Icons.check_circle, size: 18, color: Colors.white)
        else if (series.monitored)
          if (series.isWaiting)
            Icon(
              Icons.access_time,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            )
          else
            Icon(
              Icons.cancel_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        const SizedBox(width: 8),
        _buildStatusChip(context),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        series.status.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
