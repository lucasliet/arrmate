import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_capabilities.dart';
import '../../../core/services/logger_service.dart';
import '../../../data/api/media_metadata_service.dart';
import '../../../domain/models/shared/media_credits.dart';

/// Provides the [MediaMetadataService] behind the add-content previews.
final mediaMetadataServiceProvider = Provider<MediaMetadataService>(
  (ref) => MediaMetadataService(),
);

/// Titles, cast and crew of a looked-up movie, by TMDB id.
///
/// The data only helps identifying the title, so a failure is logged and
/// surfaces as an error state the preview hides. The web build asks nothing:
/// the metadata servers send no CORS headers, so a browser cannot read them.
final moviePreviewDetailsProvider = FutureProvider.autoDispose
    .family<MediaPreviewDetails, int>((ref, tmdbId) async {
      if (ref.watch(platformCapabilitiesProvider).isWeb) {
        return const MediaPreviewDetails();
      }
      try {
        return await ref
            .watch(mediaMetadataServiceProvider)
            .getMovieDetails(tmdbId);
      } catch (e) {
        logger.warning(
          '[MediaPreviewDetails] Movie details unavailable for $tmdbId: '
          '${e.runtimeType}',
        );
        rethrow;
      }
    });

/// Cast of a looked-up series, by TVDB id.
///
/// The data only helps identifying the title, so a failure is logged and
/// surfaces as an error state the preview hides. The web build asks nothing:
/// the metadata servers send no CORS headers, so a browser cannot read them.
final seriesPreviewDetailsProvider = FutureProvider.autoDispose
    .family<MediaPreviewDetails, int>((ref, tvdbId) async {
      if (ref.watch(platformCapabilitiesProvider).isWeb) {
        return const MediaPreviewDetails();
      }
      try {
        return await ref
            .watch(mediaMetadataServiceProvider)
            .getSeriesDetails(tvdbId);
      } catch (e) {
        logger.warning(
          '[MediaPreviewDetails] Series details unavailable for $tvdbId: '
          '${e.runtimeType}',
        );
        rethrow;
      }
    });
