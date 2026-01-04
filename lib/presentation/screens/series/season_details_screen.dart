import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/models.dart';
import '../../../../core/utils/formatters.dart';
import 'package:arrmate/presentation/widgets/common_widgets.dart';
import 'package:arrmate/presentation/shared/widgets/releases_sheet.dart';
import 'package:arrmate/presentation/screens/series/providers/season_episodes_provider.dart';

class SeasonDetailsScreen extends ConsumerWidget {
  final Series series; // We pass the full series or at least ID
  final Season season;

  const SeasonDetailsScreen({
    super.key,
    required this.series,
    required this.season,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app we might want to fetch episodes if they are not fully populated in the Series object.
    // The Series object from Sonarr usually contains all seasons and statistics but maybe not full episode list details if not requested?
    // Actually Sonarr `/series/{id}` returns seasons statistics, but episodes are fetched via `/episode?seriesId={id}`.
    // My `Series` model has `seasons` list but `Season` model only has stats, usually.
    // I need to fetch episodes for this season.
    // I'll create a provider `seasonEpisodesProvider(seriesId, seasonNumber)`.

    final episodesAsync = ref.watch(
      seasonEpisodesProvider(series.id, season.seasonNumber),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${series.title} - Season ${season.seasonNumber}'),
      ),
      body: episodesAsync.when(
        data: (episodes) {
          if (episodes.isEmpty) {
            return const Center(child: Text('No episodes found'));
          }
          return ListView.builder(
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return _EpisodeTile(series: series, episode: episode);
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, st) => ErrorDisplay(
          message: 'Failed to load episodes: $e',
          onRetry: () => ref.refresh(
            seasonEpisodesProvider(series.id, season.seasonNumber),
          ),
        ),
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Series series;
  final Episode episode;

  const _EpisodeTile({required this.series, required this.episode});

  @override
  Widget build(BuildContext context) {
    final hasFile = episode.hasFile;
    final monitored = episode.monitored;
    final aired = episode.isAired;

    Color statusColor = Colors.grey;
    if (hasFile) {
      statusColor = Colors.green;
    } else if (monitored && aired) {
      statusColor = Colors.red;
    } else if (!monitored) {
      statusColor = Colors.grey; // Unmonitored
    } else {
      statusColor = Colors.blue; // Upcoming
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Text('${episode.episodeNumber}'),
      ),
      title: Text(episode.title ?? 'TBA'),
      subtitle: Text(
        episode.airDate != null ? formatDate(episode.airDate!) : 'TBA',
        style: TextStyle(color: statusColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          /* 
           // Example: Manual/Auto Search buttons 
           IconButton(icon: Icon(Icons.search), onPressed: () {}), 
           */
          IconButton(
            icon: const Icon(Icons.travel_explore),
            tooltip: 'Interactive Search',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => ReleasesSheet(
                  id: episode.id,
                  isMovie: false,
                  title: '${series.title} - ${episode.episodeLabel}',
                  episodeCode: episode.episodeLabel,
                ),
              );
            },
          ),
        ],
      ),
      onTap: () {
        // Show episode details bottom sheet?
      },
    );
  }
}
