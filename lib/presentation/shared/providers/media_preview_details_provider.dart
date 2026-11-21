import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// surfaces as an error state the preview hides.
final moviePreviewDetailsProvider = FutureProvider.autoDispose
    .family<MediaPreviewDetails, int>((ref, tmdbId) async {
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
/// surfaces as an error state the preview hides.
final seriesPreviewDetailsProvider = FutureProvider.autoDispose
    .family<MediaPreviewDetails, int>((ref, tvdbId) async {
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
