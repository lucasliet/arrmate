import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/instances_provider.dart';
import '../../../widgets/poster_network_image.dart';

/// Helper widget to display a series poster, handling caching and auth headers.
class SeriesPoster extends ConsumerWidget {
  /// The series whose poster is displayed.
  final Series series;

  /// How the image should be inscribed into the space allocated during layout.
  final BoxFit fit;

  /// Optional Sonarr instance override for local poster URLs.
  final Instance? instance;

  /// Creates a [SeriesPoster].
  const SeriesPoster({
    super.key,
    required this.series,
    this.fit = BoxFit.cover,
    this.instance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: Use currentSonarrInstanceProvider instead of Radarr
    final instance = this.instance ?? ref.watch(currentSonarrInstanceProvider);
    final headers = instance?.authHeaders;

    // Priority:
    // 1. Remote URL (TVDB) - No auth needed, faster.
    // 2. Local URL - Needs auth, served by Sonarr.

    // Check for remote URL
    final remotePoster = series.images
        .where((i) => i.coverType == 'poster')
        .firstOrNull
        ?.remoteUrl;

    if (remotePoster != null && remotePoster.isNotEmpty) {
      return PosterNetworkImage(
        imageUrl: remotePoster,
        fit: fit,
        errorBuilder: _buildPlaceholder,
      );
    }

    // Fallback to local authenticated URL
    final localPosterPath = series.images
        .where((i) => i.coverType == 'poster')
        .firstOrNull
        ?.url;

    if (localPosterPath == null || instance == null) {
      return _buildPlaceholder(context);
    }

    // URL Construction logic
    final uri = Uri.parse(instance.effectiveUrl).replace(
      path: '${Uri.parse(instance.effectiveUrl).path}$localPosterPath'
          .replaceAll('//', '/'),
    );

    return PosterNetworkImage(
      imageUrl: uri.toString(),
      httpHeaders: headers,
      fit: fit,
      errorBuilder: _buildPlaceholder,
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.tv,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          size: 32,
        ),
      ),
    );
  }
}
