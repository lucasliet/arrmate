import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/models.dart';
import '../../../providers/instances_provider.dart';

class SeriesPoster extends ConsumerWidget {
  final Series series;
  final BoxFit fit;

  const SeriesPoster({
    super.key,
    required this.series,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: Use currentSonarrInstanceProvider instead of Radarr
    final instance = ref.watch(currentSonarrInstanceProvider);
    final headers = instance?.authHeaders;

    // Series usually have images list. Find poster.
    final localPosterPath = series.images.where((i) => i.coverType == 'poster').firstOrNull?.url;
    
    if (localPosterPath == null) {
      return _buildPlaceholder(context);
    }

    // URL Construction logic
    final uri = Uri.parse(instance!.url).replace(path: '${Uri.parse(instance.url).path}$localPosterPath'.replaceAll('//', '/'));

    return CachedNetworkImage(
      imageUrl: uri.toString(),
      httpHeaders: headers,
      fit: fit,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.tv,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          size: 32,
        ),
      ),
    );
  }
}
