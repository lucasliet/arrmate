import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/playback_launch_service.dart';
import '../../../../core/services/purge_service.dart';
import '../../../../domain/models/models.dart';
import '../../../../core/utils/formatters.dart';
import 'package:arrmate/presentation/l10n/labels.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/widgets/common_widgets.dart';
import 'package:arrmate/presentation/shared/widgets/releases_sheet.dart';
import 'package:arrmate/presentation/shared/widgets/seeding_warning_dialog.dart';
import 'package:arrmate/presentation/screens/series/providers/season_episodes_provider.dart';
import 'package:arrmate/presentation/screens/series/providers/series_metadata_provider.dart';
import 'package:arrmate/presentation/screens/series/providers/series_provider.dart';
import 'package:arrmate/presentation/screens/series/widgets/episode_details_sheet.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/notifications_provider.dart';
import 'package:arrmate/presentation/providers/settings_provider.dart';

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

    final hasAnyFile = episodesAsync.maybeWhen(
      data: (episodes) => episodes.any((e) => e.hasFile),
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.seriesTitleWithSeason(series.title, season.seasonNumber),
        ),
        actions: [
          IconButton(
            key: const Key('seasonAutomaticSearchBtn'),
            icon: const Icon(Icons.travel_explore),
            tooltip: context.l10n.commonAutomaticSearch,
            onPressed: () => _handleAutomaticSearch(context, ref),
          ),
          IconButton(
            key: const Key('seasonInteractiveSearchBtn'),
            icon: const Icon(Icons.troubleshoot),
            tooltip: context.l10n.commonInteractiveSearch,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => ReleasesSheet(
                  id: 0,
                  isMovie: false,
                  title: context.l10n.seriesTitleWithSeason(
                    series.title,
                    season.seasonNumber,
                  ),
                  episodeCode: context.l10n.formatSeason(season.seasonNumber),
                  seriesId: series.id,
                  seasonNumber: season.seasonNumber,
                  originalLanguage: series.originalLanguage?.name,
                ),
              );
            },
          ),
          IconButton(
            key: const Key('deleteSeasonFilesBtn'),
            icon: const Icon(Icons.delete_sweep),
            tooltip: context.l10n.seriesDeleteSeasonFiles,
            onPressed: hasAnyFile
                ? () => _handleDeleteFiles(context, ref)
                : null,
          ),
          IconButton(
            key: const Key('purgeSeasonBtn'),
            icon: const Icon(Icons.delete_forever),
            tooltip: context.l10n.seriesPurgeSeason,
            onPressed: hasAnyFile ? () => _handlePurge(context, ref) : null,
          ),
        ],
      ),
      body: episodesAsync.when(
        data: (episodes) {
          if (episodes.isEmpty) {
            return Center(child: Text(context.l10n.seriesNoEpisodesFound));
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
          message: context.l10n.seriesLoadEpisodesFailed(
            describeError(e, context.l10n),
          ),
          onRetry: () => ref.refresh(
            seasonEpisodesProvider(series.id, season.seasonNumber),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteFiles(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.seriesDeleteSeasonFiles),
        content: Text(
          l10n.seriesDeleteSeasonFilesConfirm(
            series.title,
            season.seasonNumber,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;
    showDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final count = await ref
          .read(seriesMetadataControllerProvider(series.id))
          .deleteAllFiles(seasonNumber: season.seasonNumber);
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count == 0
                  ? l10n.seriesNoFilesToDelete
                  : l10n.seriesDeletedFilesCount(count),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.seriesDeleteFilesFailed(describeError(e, l10n))),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleAutomaticSearch(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.seriesSearchingFor(
            l10n.seriesTitleWithSeason(series.title, season.seasonNumber),
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      await ref
          .read(seriesControllerProvider(series.id))
          .seasonAutomaticSearch(season.seasonNumber);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.commonSearchStarted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.seriesSearchFailed(describeError(e, l10n))),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handlePurge(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final purgeService = ref.read(purgeServiceProvider);
    final minimumSeedingDays = ref.read(settingsProvider).minimumSeedingDays;
    final repository = ref.read(seriesRepositoryProvider);

    if (repository == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.seriesNoSonarrInstance)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.seriesPurgeSeason),
        content: Text(
          l10n.seriesPurgeSeasonConfirm(series.title, season.seasonNumber),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.commonPurge),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    List<int> episodeIds;
    // Every episode of the season, with or without a file: a pack reaching
    // beyond them also holds other seasons and needs its own approval.
    List<int> scopeEpisodeIds;
    try {
      final episodes = await repository.getEpisodes(series.id);
      scopeEpisodeIds = episodes
          .where((e) => e.seasonNumber == season.seasonNumber)
          .map((e) => e.id)
          .toList();
      episodeIds = episodes
          .where(
            (e) =>
                e.seasonNumber == season.seasonNumber &&
                e.hasFile &&
                e.episodeFileId != null &&
                e.episodeFileId! > 0,
          )
          .map((e) => e.id)
          .toList();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.seriesLoadEpisodesFailed(describeError(e, l10n))),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    SeedingAction? action;
    var approvedCrossSeedHashes = <String>{};
    var approvedSharedPackHashes = <String>{};
    try {
      action = await resolveSeedingAction(
        context: context,
        minimumSeedingDays: minimumSeedingDays,
        preview: (seconds) => purgeService.previewSeason(
          series.id,
          episodeIds,
          minimumSeedingSeconds: seconds,
          scopeEpisodeIds: scopeEpisodeIds,
        ),
      );
      if (action != null && action != SeedingAction.cancel && context.mounted) {
        final preview = await purgeService.previewSeason(
          series.id,
          episodeIds,
          minimumSeedingSeconds: minimumSeedingDays * 86400,
          scopeEpisodeIds: scopeEpisodeIds,
        );
        if (!context.mounted) return;
        approvedCrossSeedHashes = await resolveCrossSeedApprovals(
          context: context,
          crossSeedCandidates: preview.crossSeedCandidates,
        );
        if (!context.mounted) return;
        approvedSharedPackHashes = await resolveSharedPackApprovals(
          context: context,
          sharedPackCandidates: preview.sharedPackCandidates,
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.seriesPreviewFailed(describeError(e, l10n))),
        ),
      );
      return;
    }

    if (action == null || action == SeedingAction.cancel) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final result = await purgeService.purgeSeason(
        series.id,
        season.seasonNumber,
        episodeIds,
        action: action,
        minimumSeedingSeconds: minimumSeedingDays * 86400,
        approvedCrossSeedHashes: approvedCrossSeedHashes,
        scopeEpisodeIds: scopeEpisodeIds,
        approvedSharedPackHashes: approvedSharedPackHashes,
      );
      if (context.mounted) navigator.pop();
      ref.read(notificationActionsProvider.notifier).refresh();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.seriesPurgedSummary(
                result.mediaFilesDeleted,
                result.torrentHashesDeleted.length,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) navigator.pop();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.seriesPurgeFailed(describeError(e, l10n))),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Actions offered in an episode row overflow menu.
enum _EpisodeAction { watch, toggleMonitor, automaticSearch, interactiveSearch }

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

    final canWatch =
        episode.hasFile && ref.watch(currentJellyfinInstanceProvider) != null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Text('${episode.episodeNumber}'),
      ),
      title: Text(episode.title ?? context.l10n.labelTba),
      subtitle: Text(
        episode.airDate != null
            ? formatDate(episode.airDate!)
            : context.l10n.labelTba,
        style: TextStyle(color: statusColor),
      ),
      trailing: context.isLargeScreen
          ? _buildExpandedActions(context, ref, canWatch)
          : _buildOverflowMenu(context, ref, canWatch),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => EpisodeDetailsSheet(episode: episode),
        );
      },
    );
  }

  void _openInteractiveSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReleasesSheet(
        id: episode.id,
        isMovie: false,
        title: '${series.title} - ${episode.episodeLabel}',
        episodeCode: episode.episodeLabel,
        originalLanguage: series.originalLanguage?.name,
      ),
    );
  }

  void _watch(BuildContext context, WidgetRef ref) {
    ref
        .read(playbackLaunchServiceProvider)
        .playEpisode(context, ref, episode: episode);
  }

  Widget _buildExpandedActions(
    BuildContext context,
    WidgetRef ref,
    bool canWatch,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canWatch)
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: context.l10n.commonWatchInJellyfin,
            onPressed: () => _watch(context, ref),
          ),
        IconButton(
          icon: Icon(
            episode.monitored ? Icons.bookmark : Icons.bookmark_border,
          ),
          tooltip: episode.monitored
              ? context.l10n.seriesUnmonitorEpisode
              : context.l10n.seriesMonitorEpisode,
          onPressed: () => _handleMonitoring(context, ref),
        ),
        IconButton(
          icon: const Icon(Icons.travel_explore),
          tooltip: context.l10n.commonAutomaticSearch,
          onPressed: () => _handleAutomaticSearch(context, ref),
        ),
        IconButton(
          icon: const Icon(Icons.troubleshoot),
          tooltip: context.l10n.commonInteractiveSearch,
          onPressed: () => _openInteractiveSearch(context),
        ),
      ],
    );
  }

  Widget _buildOverflowMenu(
    BuildContext context,
    WidgetRef ref,
    bool canWatch,
  ) {
    return PopupMenuButton<_EpisodeAction>(
      key: Key('episodeActionsMenu_${episode.id}'),
      tooltip: context.l10n.seriesEpisodeActions,
      onSelected: (action) {
        switch (action) {
          case _EpisodeAction.watch:
            _watch(context, ref);
          case _EpisodeAction.toggleMonitor:
            _handleMonitoring(context, ref);
          case _EpisodeAction.automaticSearch:
            _handleAutomaticSearch(context, ref);
          case _EpisodeAction.interactiveSearch:
            _openInteractiveSearch(context);
        }
      },
      itemBuilder: (context) => [
        if (canWatch)
          PopupMenuItem(
            value: _EpisodeAction.watch,
            child: ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text(context.l10n.commonWatchInJellyfin),
            ),
          ),
        PopupMenuItem(
          value: _EpisodeAction.toggleMonitor,
          child: ListTile(
            leading: Icon(
              episode.monitored ? Icons.bookmark : Icons.bookmark_border,
            ),
            title: Text(
              episode.monitored
                  ? context.l10n.seriesUnmonitorEpisode
                  : context.l10n.seriesMonitorEpisode,
            ),
          ),
        ),
        PopupMenuItem(
          value: _EpisodeAction.automaticSearch,
          child: ListTile(
            leading: const Icon(Icons.travel_explore),
            title: Text(context.l10n.commonAutomaticSearch),
          ),
        ),
        PopupMenuItem(
          value: _EpisodeAction.interactiveSearch,
          child: ListTile(
            leading: const Icon(Icons.troubleshoot),
            title: Text(context.l10n.commonInteractiveSearch),
          ),
        ),
      ],
    );
  }

  Future<void> _handleMonitoring(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      await ref
          .read(seriesControllerProvider(series.id))
          .setEpisodeMonitoring(episode, !episode.monitored);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              episode.monitored
                  ? l10n.seriesEpisodeUnmonitored
                  : l10n.seriesEpisodeMonitored,
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.seriesUpdateEpisodeFailed(describeError(error, l10n)),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleAutomaticSearch(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = context.l10n;
    final repository = ref.read(seriesRepositoryProvider);
    if (repository == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.seriesNoSonarrInstance)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.seriesSearchingFor(episode.episodeLabel)),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      await repository.searchEpisode(episode.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.seriesSearchStartedFor(episode.episodeLabel)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.seriesSearchFailed(describeError(e, l10n))),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
