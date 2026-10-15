import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrmate/core/constants/app_constants.dart';
import 'package:arrmate/core/extensions/context_extensions.dart';
import 'package:arrmate/presentation/widgets/common_widgets.dart';
import 'package:arrmate/presentation/widgets/media/media_file_card.dart';
import 'package:arrmate/presentation/widgets/media/extra_file_card.dart';
import 'package:arrmate/presentation/widgets/media/history_event_card.dart';
import 'package:arrmate/presentation/widgets/media/media_file_details_sheet.dart';
import 'package:arrmate/presentation/widgets/media/history_event_details_sheet.dart';
import 'package:arrmate/presentation/shared/providers/media_torrents_provider.dart';
import 'package:arrmate/presentation/shared/widgets/media_torrents_section.dart';
import '../../../../core/services/playback_launch_service.dart';
import '../../../l10n/labels.dart';
import '../../../providers/instances_provider.dart';
import '../providers/movie_details_provider.dart';
import '../providers/movie_metadata_provider.dart';

/// A section widget displaying related files and history for a movie.
class MovieMetadataSection extends ConsumerWidget {
  final int movieId;

  const MovieMetadataSection({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilesSection(context, ref),
        const SizedBox(height: 24),
        MediaTorrentsSection(provider: movieTorrentsProvider(movieId)),
        const SizedBox(height: 24),
        _buildHistorySection(context, ref),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFilesSection(BuildContext context, WidgetRef ref) {
    final filesState = ref.watch(movieFilesProvider(movieId));
    final extraFilesState = ref.watch(movieExtraFilesProvider(movieId));
    final movieAsync = ref.watch(movieDetailsProvider(movieId));
    final jellyfinConfigured =
        ref.watch(currentJellyfinInstanceProvider) != null;
    final movie = movieAsync.asData?.value;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.moviesFilesSection,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        filesState.when(
          data: (files) {
            if (files.isEmpty) {
              return _buildEmptyState(
                context,
                Icons.movie_outlined,
                context.l10n.moviesNoMediaFiles,
              );
            }
            return Column(
              children: files
                  .map(
                    (file) => MediaFileCard(
                      file: file,
                      onPlay: jellyfinConfigured && movie != null
                          ? () => ref
                                .read(playbackLaunchServiceProvider)
                                .playMovie(context, ref, movie: movie)
                          : null,
                      onTap: () => context.showBottomSheet(
                        MediaFileDetailsSheet(
                          file: file,
                          onDelete: () async {
                            final shouldDelete = await _confirmDelete(context);
                            if (shouldDelete == true) {
                              try {
                                final controller = ref.read(
                                  movieMetadataControllerProvider(movieId),
                                );
                                await controller.deleteFile(file.id);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  context.showSnackBar(
                                    context.l10n.moviesFileDeleted,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  context.showErrorSnackBar(
                                    context.l10n.moviesDeleteFailed(
                                      describeError(e, context.l10n),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                      onDelete: () async {
                        final shouldDelete = await _confirmDelete(context);
                        if (shouldDelete == true) {
                          try {
                            final controller = ref.read(
                              movieMetadataControllerProvider(movieId),
                            );
                            await controller.deleteFile(file.id);
                            if (context.mounted) {
                              context.showSnackBar(
                                context.l10n.moviesFileDeleted,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              context.showErrorSnackBar(
                                context.l10n.moviesDeleteFailed(
                                  describeError(e, context.l10n),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(paddingMd),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => ErrorDisplay(
            message: context.l10n.moviesLoadFilesFailed,
            onRetry: () => ref.refresh(movieFilesProvider(movieId)),
          ),
        ),
        const SizedBox(height: 12),
        extraFilesState.when(
          data: (extraFiles) {
            if (extraFiles.isEmpty) return const SizedBox();
            return Column(
              children: extraFiles
                  .map((file) => ExtraFileCard.fromMovieExtraFile(file))
                  .toList(),
            );
          },
          loading: () => const SizedBox(),
          error: (_, _) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(movieHistoryProvider(movieId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.moviesHistorySection,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        historyState.when(
          data: (events) {
            if (events.isEmpty) {
              return _buildEmptyState(
                context,
                Icons.history,
                context.l10n.moviesNoHistoryEvents,
              );
            }
            final limitedEvents = events.take(10).toList();
            return Column(
              children: limitedEvents
                  .map(
                    (event) => HistoryEventCard(
                      event: event,
                      onTap: () => context.showBottomSheet(
                        HistoryEventDetailsSheet(event: event),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(paddingMd),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => ErrorDisplay(
            message: context.l10n.moviesLoadHistoryFailed,
            onRetry: () => ref.refresh(movieHistoryProvider(movieId)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String message) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(paddingLg),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.moviesDeleteFileTitle),
        content: Text(context.l10n.moviesDeleteFileConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
  }
}
