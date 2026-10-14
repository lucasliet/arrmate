import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/jellyfin_service.dart';
import '../../domain/models/models.dart';
import '../../presentation/providers/instances_provider.dart';
import '../../presentation/providers/jellyfin_session_state_provider.dart';
import '../../presentation/screens/movies/providers/movie_metadata_provider.dart';
import '../../presentation/screens/player/playback_request.dart';
import '../../presentation/screens/series/providers/episode_providers.dart';
import '../../presentation/screens/series/providers/series_provider.dart';
import '../constants/app_constants.dart';
import '../extensions/context_extensions.dart';
import '../network/api_error.dart';
import '../utils/formatters.dart';
import 'jellyfin_playback_reporter.dart';
import 'logger_service.dart';

/// Provider for the [PlaybackLaunchService].
final playbackLaunchServiceProvider = Provider<PlaybackLaunchService>(
  (ref) => PlaybackLaunchService(),
);

/// Outcome of a playback launch attempt.
sealed class PlaybackLaunchResult {
  const PlaybackLaunchResult();
}

/// The media was resolved and handed to the in-app player.
class PlaybackLaunched extends PlaybackLaunchResult {
  /// The request that was pushed to the player route.
  final PlaybackRequest request;

  /// Creates a successful launch result.
  const PlaybackLaunched(this.request);
}

/// Jellyfin has no playable item for the requested file, even after a
/// library scan.
class PlaybackTargetNotFound extends PlaybackLaunchResult {
  /// Creates a not-found result.
  const PlaybackTargetNotFound();
}

/// Playback could not be started (authentication, network, session error).
class PlaybackLaunchFailure extends PlaybackLaunchResult {
  /// Human readable description of what went wrong.
  final String message;

  /// Creates a failure result.
  const PlaybackLaunchFailure(this.message);
}

/// The user dismissed the status dialog, cancelling the launch.
class PlaybackLaunchCancelled extends PlaybackLaunchResult {
  /// Creates a cancelled result.
  const PlaybackLaunchCancelled();
}

/// Resolves a Radarr/Sonarr media file against the configured Jellyfin
/// server and hands the resulting stream to the in-app player.
///
/// The launch runs behind a dismissible status dialog: resolving a freshly
/// imported file may trigger a library scan and poll the catalog for a few
/// seconds. Dismissing the dialog cancels the launch (navigation is
/// skipped), although an in-flight server request cannot be aborted.
class PlaybackLaunchService {
  static const _logPrefix = 'PlaybackLaunchService';

  final JellyfinService Function(Instance instance) _jellyfinServiceFactory;

  /// Cached clients keyed by instance id (see [serviceFor]).
  final Map<String, JellyfinService> _servicesByInstanceId = {};

  /// Creates the service.
  ///
  /// [jellyfinServiceFactory] is an injection point for tests; production
  /// builds real [JellyfinService] clients from the resolved instance.
  PlaybackLaunchService({
    JellyfinService Function(Instance instance)? jellyfinServiceFactory,
  }) : _jellyfinServiceFactory = jellyfinServiceFactory ?? JellyfinService.new;

  /// Returns the [JellyfinService] for [instance], creating it through the
  /// injectable factory on first use (or when [instance] changes) and reusing
  /// it afterwards.
  ///
  /// Jellyfin invalidates the previous token of the same DeviceId on every
  /// authentication, so a fresh client per play would kill the playback
  /// session started from another screen. One cached client per instance
  /// keeps the resolver, the session builder and the reporter on the same
  /// authenticated session, while invalidating the cache if the instance
  /// configuration is edited.
  JellyfinService serviceFor(Instance instance) {
    final cached = _servicesByInstanceId[instance.id];
    if (cached != null && cached.instance == instance) {
      return cached;
    }
    final created = _jellyfinServiceFactory(instance);
    _servicesByInstanceId[instance.id] = created;
    return created;
  }

  /// Resolves the playable file of [movie] and starts playback.
  ///
  /// The file path comes from [movieFilesProvider]; the movie's own
  /// `movieFile` is used as a fallback when the metadata listing carries no
  /// path.
  Future<void> playMovie(
    BuildContext context,
    WidgetRef ref, {
    required Movie movie,
  }) async {
    if (!_ensureJellyfinConfigured(context, ref)) return;

    List<MediaFile> files;
    try {
      files = await ref.read(movieFilesProvider(movie.id).future);
    } catch (error, stackTrace) {
      logger.error(
        '[$_logPrefix] Failed to load files for movie "${movie.title}"',
        error,
        stackTrace,
      );
      if (context.mounted) {
        context.showErrorSnackBar('Could not load the movie file');
      }
      return;
    }

    final filePath = files
        .map((file) => file.path)
        .firstWhere(
          (path) => path != null && path.trim().isNotEmpty,
          orElse: () => movie.movieFile?.path,
        )
        ?.trim();
    if (filePath == null || filePath.isEmpty) {
      logger.warning(
        '[$_logPrefix] Movie "${movie.title}" has no file path to play',
      );
      if (context.mounted) {
        context.showErrorSnackBar('No playable file found for this movie');
      }
      return;
    }

    if (!context.mounted) return;
    await playFile(
      context,
      ref,
      filePath: filePath,
      title: movie.title,
      productionYear: movie.year,
      tmdbId: movie.tmdbId,
      imdbId: movie.imdbId,
      isEpisode: false,
    );
  }

  /// Resolves the playable file of [episode] and starts playback.
  ///
  /// Sonarr episode listings are fetched without `includeEpisodeFile` /
  /// `includeSeries`, so the embedded [Episode.episodeFile] and
  /// [Episode.series] are usually null in production. When absent, the file
  /// is resolved through [episodeFileProvider] and the series through
  /// [seriesDetailsProvider] — the same sources the episode details UI uses.
  ///
  /// Episode provider ids (`tvdbId`, season/episode numbers) and the series
  /// name are forwarded so Jellyfin can match the item even when the file
  /// path is mounted under a different root.
  Future<void> playEpisode(
    BuildContext context,
    WidgetRef ref, {
    required Episode episode,
  }) async {
    if (!_ensureJellyfinConfigured(context, ref)) return;

    final episodeFile =
        episode.episodeFile ?? await _resolveEpisodeFile(ref, episode);
    final filePath = episodeFile?.path?.trim();
    if (filePath == null || filePath.isEmpty) {
      logger.warning(
        '[$_logPrefix] Episode ${episode.episodeLabel} has no file path to '
        'play',
      );
      if (context.mounted) {
        context.showErrorSnackBar('No playable file found for this episode');
      }
      return;
    }

    final series = episode.series ?? await _resolveEpisodeSeries(ref, episode);
    if (!context.mounted) return;

    await playFile(
      context,
      ref,
      filePath: filePath,
      title: _episodeTitle(episode),
      seriesTvdbId: series?.tvdbId,
      episodeTvdbId: episode.tvdbId,
      seasonNumber: episode.seasonNumber,
      episodeNumber: episode.episodeNumber,
      seriesName: series?.title,
      isEpisode: true,
    );
  }

  /// Fetches the media file of [episode] when the episode listing did not
  /// embed it (`episodeFileId` is set but `episodeFile` is null).
  ///
  /// Returns null when there is nothing to fetch or the fetch fails — the
  /// caller then surfaces the usual "no playable file" error.
  Future<MediaFile?> _resolveEpisodeFile(WidgetRef ref, Episode episode) async {
    final fileId = episode.episodeFileId;
    if (fileId == null) return null;
    try {
      return await ref.read(episodeFileProvider(fileId).future);
    } catch (error, stackTrace) {
      logger.error(
        '[$_logPrefix] Failed to load file $fileId of episode '
        '${episode.episodeLabel}',
        error,
        stackTrace,
      );
      return null;
    }
  }

  /// Fetches the series of [episode] when the episode listing did not embed
  /// it, so Jellyfin still receives the `seriesTvdbId` / `seriesName` hints.
  ///
  /// Returns null on failure; path matching in Jellyfin still works without
  /// the hints.
  Future<Series?> _resolveEpisodeSeries(WidgetRef ref, Episode episode) async {
    try {
      return await ref.read(seriesDetailsProvider(episode.seriesId).future);
    } catch (error, stackTrace) {
      logger.warning(
        '[$_logPrefix] Failed to load series ${episode.seriesId} of episode '
        '${episode.episodeLabel}',
        error,
        stackTrace,
      );
      return null;
    }
  }

  /// Low-level launch pipeline shared by [playMovie] and [playEpisode]:
  /// status dialog → authenticate → resolve → session → navigate to the
  /// player route.
  ///
  /// Returns the outcome so callers (and tests) can distinguish "not found
  /// in Jellyfin" from an unexpected failure.
  Future<PlaybackLaunchResult> playFile(
    BuildContext context,
    WidgetRef ref, {
    required String filePath,
    String? title,
    int? productionYear,
    int? tmdbId,
    String? imdbId,
    int? seriesTvdbId,
    int? episodeTvdbId,
    int? seasonNumber,
    int? episodeNumber,
    String? seriesName,
    required bool isEpisode,
  }) async {
    if (!_ensureJellyfinConfigured(context, ref)) {
      return const PlaybackLaunchFailure('No Jellyfin server is configured');
    }

    final instance = ref.read(currentJellyfinInstanceProvider)!;
    final jellyfin = serviceFor(instance);
    final displayTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : filePath;

    var dialogDismissed = false;
    var statusMessage = 'Searching the Jellyfin library…';
    void Function(String message)? updateStatus;

    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            updateStatus = (message) =>
                setDialogState(() => statusMessage = message);
            return AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: paddingMd),
                  Expanded(child: Text(statusMessage)),
                ],
              ),
            );
          },
        ),
      ).then((_) => dialogDismissed = true),
    );

    void closeDialog() {
      if (dialogDismissed || !context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    }

    try {
      await jellyfin.authenticate();
      final item = await jellyfin.resolvePlayableItem(
        filePath: filePath,
        title: title,
        productionYear: productionYear,
        tmdbId: tmdbId,
        imdbId: imdbId,
        seriesTvdbId: seriesTvdbId,
        episodeTvdbId: episodeTvdbId,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        seriesName: seriesName,
        isEpisode: isEpisode,
        onProgress: (message) {
          // The dialog may have been dismissed while resolving; touching
          // its state afterwards would crash.
          if (dialogDismissed) return;
          updateStatus?.call(message);
        },
      );

      if (item == null) {
        logger.warning(
          '[$_logPrefix] "$displayTitle" was not found in Jellyfin '
          '(file: $filePath)',
        );
        closeDialog();
        if (context.mounted) {
          context.showErrorSnackBar('Could not find this media in Jellyfin');
        }
        return const PlaybackTargetNotFound();
      }

      final session = await jellyfin.getPlaybackSession(item);
      final request = _buildRequest(
        jellyfin,
        session: session,
        title: displayTitle,
      );

      closeDialog();
      if (dialogDismissed) {
        logger.debug(
          '[$_logPrefix] Dialog dismissed during resolution; skipping '
          'playback of "$displayTitle"',
        );
        return const PlaybackLaunchCancelled();
      }
      if (context.mounted) {
        unawaited(context.push<void>('/player', extra: request));
        return PlaybackLaunched(request);
      }
      return const PlaybackLaunchCancelled();
    } on UnauthorizedError catch (error) {
      closeDialog();
      if (context.mounted) {
        return _handleSessionExpired(context, ref, instance, error);
      }
      return PlaybackLaunchFailure(error.message);
    } catch (error, stackTrace) {
      logger.error(
        '[$_logPrefix] Failed to launch "$displayTitle" from Jellyfin',
        error,
        stackTrace,
      );
      closeDialog();
      if (context.mounted) {
        context.showErrorSnackBar('Could not start playback: $error');
      }
      return PlaybackLaunchFailure(error.toString());
    }
  }

  /// Starts playback of an already-resolved [JellyfinItem].
  ///
  /// Used by the Continue Watching list, where [item] (including its media
  /// sources and resume position) was already fetched from Jellyfin.
  Future<PlaybackLaunchResult> playItem(
    BuildContext context,
    WidgetRef ref, {
    required JellyfinItem item,
    String? title,
  }) async {
    if (!_ensureJellyfinConfigured(context, ref)) {
      return const PlaybackLaunchFailure('No Jellyfin server is configured');
    }

    final instance = ref.read(currentJellyfinInstanceProvider)!;
    final jellyfin = serviceFor(instance);
    final displayTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : (item.name ?? item.id);

    try {
      await jellyfin.authenticate();
      final session = await jellyfin.getPlaybackSession(item);
      final request = _buildRequest(
        jellyfin,
        session: session,
        title: displayTitle,
      );
      if (context.mounted) {
        unawaited(context.push<void>('/player', extra: request));
        return PlaybackLaunched(request);
      }
      return const PlaybackLaunchCancelled();
    } on UnauthorizedError catch (error) {
      if (context.mounted) {
        return _handleSessionExpired(context, ref, instance, error);
      }
      return PlaybackLaunchFailure(error.message);
    } catch (error, stackTrace) {
      logger.error(
        '[$_logPrefix] Failed to launch "$displayTitle" from Jellyfin',
        error,
        stackTrace,
      );
      if (context.mounted) {
        context.showErrorSnackBar('Could not start playback: $error');
      }
      return PlaybackLaunchFailure(error.toString());
    }
  }

  /// Marks [instance] as expired and shows the re-authentication snackbar.
  PlaybackLaunchFailure _handleSessionExpired(
    BuildContext context,
    WidgetRef ref,
    Instance instance,
    UnauthorizedError error,
  ) {
    logger.warning(
      '[$_logPrefix] Jellyfin session expired for instance ${instance.id}',
    );
    ref.read(jellyfinSessionExpiredProvider.notifier).markExpired(instance.id);
    if (context.mounted) {
      final router = GoRouter.of(context);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Your Jellyfin session has expired. Sign in again.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Sign in',
            onPressed: () => router.push('/settings/instance/${instance.id}'),
          ),
        ),
      );
    }
    return PlaybackLaunchFailure(error.message);
  }

  /// Shows the "no Jellyfin server" guard and returns whether playback can
  /// proceed. Callers normally hide the play affordances, but this protects
  /// against racing configuration changes.
  bool _ensureJellyfinConfigured(BuildContext context, WidgetRef ref) {
    final instance = ref.read(currentJellyfinInstanceProvider);
    if (instance != null) return true;
    _warnNoJellyfin();
    if (context.mounted) {
      context.showErrorSnackBar('No Jellyfin server is configured');
    }
    return false;
  }

  /// Maps a resolved [JellyfinPlaybackSession] to the player contract.
  ///
  /// HLS is intentionally left out (Direct Play only in this iteration) and
  /// progress reporting is only wired in user mode, where Jellyfin allows
  /// watch-state writes.
  PlaybackRequest _buildRequest(
    JellyfinService jellyfin, {
    required JellyfinPlaybackSession session,
    required String title,
  }) {
    return PlaybackRequest(
      title: title,
      streamUrl: session.streamUrl,
      httpHeaders: session.httpHeaders,
      resumePosition: session.playbackPosition,
      audioTracks: [
        for (final stream in session.audioStreams)
          AudioTrackOption(index: stream.index, label: _trackLabel(stream)),
      ],
      subtitleTracks: [
        for (final stream in session.subtitleStreams)
          SubtitleTrackOption(
            index: stream.index,
            label: _trackLabel(stream),
            isExternal: stream.isExternal,
            deliveryPath: stream.deliveryUrl,
          ),
      ],
      // The stream URL carries the access token: in user mode it is a
      // session-scoped token and acceptable to hand out, but in API-key
      // mode it is a full server admin key — never expose it to external
      // apps or the browser history.
      externalUrl: jellyfin.supportsProgressSync
          ? session.streamUrl.toString()
          : null,
      reporter: jellyfin.supportsProgressSync
          ? JellyfinPlaybackReporter(
              jellyfin,
              itemId: session.itemId,
              mediaSourceId: session.mediaSourceId,
            )
          : null,
    );
  }

  /// Formats the player title of an episode (`S01E02 · Title`).
  String _episodeTitle(Episode episode) {
    return '${formatEpisodeNumber(episode.seasonNumber, episode.episodeNumber, short: true)} · ${episode.title ?? 'TBA'}';
  }

  /// Builds a readable track label, preferring the server-composed display
  /// title and falling back to language/codec so a track is never shown
  /// without a name.
  String _trackLabel(JellyfinMediaStream stream) {
    final displayTitle = stream.displayTitle?.trim();
    if (displayTitle != null && displayTitle.isNotEmpty) {
      return displayTitle;
    }
    final title = stream.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    final parts = [
      stream.language?.trim(),
      stream.codec?.trim(),
    ].nonNulls.where((part) => part.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' · ');
    return 'Track ${stream.index}';
  }

  void _warnNoJellyfin() {
    logger.warning(
      '[$_logPrefix] Playback requested but no Jellyfin instance is '
      'configured',
    );
  }
}
