import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/models.dart';
import '../../../../core/utils/formatters.dart';
import 'package:arrmate/presentation/widgets/common_widgets.dart';
import 'package:arrmate/presentation/shared/widgets/releases_sheet.dart';
import 'package:arrmate/presentation/screens/series/providers/season_episodes_provider.dart';
import 'package:arrmate/presentation/screens/series/widgets/episode_details_sheet.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';

/// Screens that lists episodes for a specific season of a series.
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

class _EpisodeTile extends ConsumerWidget {
  final Series series;
  final Episode episode;

  const _EpisodeTile({required this.series, required this.episode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          IconButton(
            icon: const Icon(Icons.travel_explore),
            tooltip: 'Automatic Search',
            onPressed: () => _handleAutomaticSearch(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.troubleshoot),
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
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => EpisodeDetailsSheet(episode: episode),
        );
      },
    );
  }

  Future<void> _handleAutomaticSearch(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final repository = ref.read(seriesRepositoryProvider);
    if (repository == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Sonarr instance configured')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for ${episode.episodeLabel}...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      await repository.searchEpisode(episode.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search started for ${episode.episodeLabel}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to search: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
