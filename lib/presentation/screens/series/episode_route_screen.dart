import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/models.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../l10n/labels.dart';
import '../../widgets/common_widgets.dart';
import 'providers/series_provider.dart';
import 'providers/season_episodes_provider.dart';
import 'season_details_screen.dart';
import 'widgets/episode_details_sheet.dart';

/// Resolves a single episode from its id within a season, then opens its
/// details sheet over the hosting season screen.
///
/// Used by calendar navigation and episode deep links so the user lands on the
/// exact episode instead of just the season list.
class EpisodeRouteScreen extends ConsumerStatefulWidget {
  final int seriesId;
  final int seasonNumber;
  final int episodeId;

  const EpisodeRouteScreen({
    super.key,
    required this.seriesId,
    required this.seasonNumber,
    required this.episodeId,
  });

  @override
  ConsumerState<EpisodeRouteScreen> createState() => _EpisodeRouteScreenState();
}

class _EpisodeRouteScreenState extends ConsumerState<EpisodeRouteScreen> {
  bool _sheetShown = false;

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(seriesDetailsProvider(widget.seriesId));
    final episodesAsync = ref.watch(
      seasonEpisodesProvider(widget.seriesId, widget.seasonNumber),
    );

    _maybeOpenEpisodeSheet(episodesAsync);

    return seriesAsync.when(
      data: (series) {
        final season = series.seasons
            .where((season) => season.seasonNumber == widget.seasonNumber)
            .firstWhere(
              (_) => true,
              orElse: () =>
                  Season(seasonNumber: widget.seasonNumber, monitored: false),
            );
        return SeasonDetailsScreen(series: series, season: season);
      },
      loading: () => Scaffold(
        body: LoadingIndicator(message: context.l10n.seriesEpisodeLoading),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.labelEpisode)),
        body: ErrorDisplay(
          message: context.l10n.seriesEpisodeLoadFailed(
            describeError(error, context.l10n),
          ),
          onRetry: () => ref.invalidate(seriesDetailsProvider(widget.seriesId)),
        ),
      ),
    );
  }

  void _maybeOpenEpisodeSheet(AsyncValue<List<Episode>> episodesAsync) {
    if (_sheetShown) return;
    final episodes = episodesAsync.valueOrNull;
    if (episodes == null) return;

    final episode = episodes
        .where((episode) => episode.id == widget.episodeId)
        .firstOrNull;
    if (episode == null) return;

    _sheetShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => EpisodeDetailsSheet(episode: episode),
      );
    });
  }
}

/// Builds a [CalendarEvent] deep-link location for the given episode.
///
/// Exposed so calendar navigation and deep-link builders stay in sync.
String episodeLocation({
  required int seriesId,
  required int seasonNumber,
  required int episodeId,
}) {
  return '/series/$seriesId/season/$seasonNumber/episode/$episodeId';
}
