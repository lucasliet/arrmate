import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/instances_provider.dart';
import '../../../../core/network/custom_cache_manager.dart';

/// Helper widget to display a movie poster, handling caching and auth headers.
class MoviePoster extends ConsumerWidget {
  final Movie movie;
  final BoxFit fit;

  const MoviePoster({super.key, required this.movie, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instance = ref.watch(currentRadarrInstanceProvider);
    final posterUrl = movie.remotePoster;
    final headers = instance?.authHeaders;

    if (posterUrl == null) {
      return _buildPlaceholder(context);
    }

    // Radarr usually provides a relative path /MediaCover/1/poster.jpg
    // We need to construct the full URL if it's not absolute (remotePoster logic in model might need check)
    // The model getter `remotePoster` gets `remoteUrl`, but for local images we might need `url`.
    // Actually, Radarr API returns `url` like "/MediaCover/1/poster.jpg" and `remoteUrl` like "http://image.tmdb.org/...".
    // We prefer the local `url` served by Radarr to use the cache and API key authentication.

    // Priority:
    // 1. Remote URL (TMDB/TVDB) - No auth needed, faster, but might be empty?
    // 2. Local URL - Needs auth, served by Radarr.

    // Radarr API returns `remoteUrl` (http://tmdb...) and `url` (/MediaCover/...).
    // Rudarr prefers `remoteUrl`. Let's allow utilizing it if available.

    final remotePoster = movie.remotePoster;
    if (remotePoster != null && remotePoster.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: remotePoster,
        cacheManager: CustomCacheManager.instance,
        fit: fit,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(context),
      );
    }

    // Fallback to local authenticated URL
    final localPosterPath = movie.images
        .where((i) => i.isPoster)
        .firstOrNull
        ?.url;

    if (localPosterPath == null || instance == null) {
      return _buildPlaceholder(context);
    }

    // Better URL construction:
    final uri = Uri.parse(instance.url).replace(
      path: '${Uri.parse(instance.url).path}$localPosterPath'.replaceAll(
        '//',
        '/',
      ),
    );

    return CachedNetworkImage(
      imageUrl: uri.toString(),
      cacheManager: CustomCacheManager.instance,
      httpHeaders: headers,
      fit: fit,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          size: 32,
        ),
      ),
    );
  }
}
