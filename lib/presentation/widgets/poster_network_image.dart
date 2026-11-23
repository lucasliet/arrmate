import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/custom_cache_manager.dart';
import '../../core/platform/platform_capabilities.dart';

/// Network poster image with a loading placeholder and an error fallback.
///
/// Native platforms keep the disk-cached [CachedNetworkImage]. The web build
/// uses the framework [Image.network] instead, which decodes a static image
/// only once.
class PosterNetworkImage extends ConsumerWidget {
  /// Absolute URL of the poster.
  final String imageUrl;

  /// Builds the widget shown when the poster cannot be loaded.
  final WidgetBuilder errorBuilder;

  /// Builds the widget shown while the poster loads.
  ///
  /// Defaults to a centered progress indicator.
  final WidgetBuilder? placeholderBuilder;

  /// Optional headers sent with the image request, such as instance auth.
  final Map<String, String>? httpHeaders;

  /// How the image should be inscribed into the space allocated during layout.
  final BoxFit fit;

  /// Creates a [PosterNetworkImage].
  const PosterNetworkImage({
    super.key,
    required this.imageUrl,
    required this.errorBuilder,
    this.placeholderBuilder,
    this.httpHeaders,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(platformCapabilitiesProvider).isWeb) {
      // cached_network_image 3.x decodes the image again each time a covered
      // route is shown again, which blanks it on web (issue #59).
      return Image.network(
        imageUrl,
        // The `<img>` fallback keeps showing the previous poster when the same
        // element is given another URL, so each URL gets its own element.
        key: ValueKey(imageUrl),
        headers: httpHeaders,
        fit: fit,
        // TMDB and local servers do not always send CORS headers; without
        // the fallback the image fails to load instead of using <img>.
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
            wasSynchronouslyLoaded || frame != null
            ? child
            : _buildLoading(context),
        errorBuilder: (context, error, stackTrace) => errorBuilder(context),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: CustomCacheManager.instance,
      httpHeaders: httpHeaders,
      fit: fit,
      placeholder: (context, url) => _buildLoading(context),
      errorWidget: (context, url, error) => errorBuilder(context),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final placeholderBuilder = this.placeholderBuilder;
    if (placeholderBuilder != null) return placeholderBuilder(context);
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
