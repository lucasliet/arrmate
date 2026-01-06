import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrmate/core/constants/app_constants.dart';
import 'package:arrmate/core/extensions/context_extensions.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/widgets/common_widgets.dart';
import 'package:arrmate/presentation/widgets/media/media_file_card.dart';
import 'package:arrmate/presentation/widgets/media/media_file_details_sheet.dart';
import 'package:arrmate/presentation/widgets/media/history_event_card.dart';
import 'package:arrmate/presentation/widgets/media/history_event_details_sheet.dart';
import 'package:intl/intl.dart';
import '../providers/episode_providers.dart';
import '../providers/series_metadata_provider.dart';

class EpisodeDetailsSheet extends ConsumerWidget {
  final Episode episode;

  const EpisodeDetailsSheet({super.key, required this.episode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                episode.fullLabel,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMetadataRow(context),
                  const SizedBox(height: 16),
                  if (episode.overview != null) ...[
                    Text(
                      'Overview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(episode.overview!, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 24),
                  ],
                  _buildFileSection(context, ref),
                  const SizedBox(height: 24),
                  _buildHistorySection(context, ref),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetadataRow(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (episode.airDate != null)
          _buildMetadataItem(
            context,
            Icons.calendar_today,
            dateFormat.format(episode.airDate!),
            'Air Date',
          ),
        if (episode.runtime > 0)
          _buildMetadataItem(
            context,
            Icons.timer_outlined,
            '${episode.runtime}m',
            'Runtime',
          ),
        _buildMetadataItem(
          context,
          episode.monitored ? Icons.bookmark : Icons.bookmark_border,
          episode.monitored ? 'Monitored' : 'Unmonitored',
          'Status',
          color: episode.monitored ? theme.colorScheme.primary : null,
        ),
      ],
    );
  }

  Widget _buildMetadataItem(
    BuildContext context,
    IconData icon,
    String label,
    String tooltip, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color ?? theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFileSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final file = episode.episodeFile;

    if (file != null) {
      return _buildFileCard(context, ref, file);
    }

    if (episode.episodeFileId != null && episode.episodeFileId! > 0) {
      final fileAsync = ref.watch(episodeFileProvider(episode.episodeFileId!));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          fileAsync.when(
            data: (fetchedFile) => _buildFileCard(context, ref, fetchedFile),
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorDisplay(
              message: 'Failed to load file info',
              onRetry: () =>
                  ref.refresh(episodeFileProvider(episode.episodeFileId!)),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'File',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(paddingLg),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          child: Column(
            children: [
              Icon(
                Icons.folder_off_outlined,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text('No file available'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileCard(BuildContext context, WidgetRef ref, MediaFile file) {
    return MediaFileCard(
      file: file,
      onTap: () => context.showBottomSheet(
        MediaFileDetailsSheet(
          file: file,
          onDelete: () => _deleteFile(context, ref, file.id),
        ),
      ),
      onDelete: () => _deleteFile(context, ref, file.id),
    );
  }

  Widget _buildHistorySection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(episodeHistoryProvider(episode.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        historyAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return const Center(child: Text('No history events'));
            }
            return Column(
              children: events
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
          loading: () => const LoadingIndicator(),
          error: (e, st) => ErrorDisplay(
            message: 'Failed to load history',
            onRetry: () => ref.refresh(episodeHistoryProvider(episode.id)),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteFile(
    BuildContext context,
    WidgetRef ref,
    int fileId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text(
          'Are you sure you want to delete this file? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final controller = ref.read(
          seriesMetadataControllerProvider(episode.seriesId),
        );
        await controller.deleteFile(fileId);
        if (context.mounted) {
          Navigator.of(context).pop();
          context.showSnackBar('File deleted');
        }
      } catch (e) {
        if (context.mounted) {
          context.showErrorSnackBar('Failed to delete: $e');
        }
      }
    }
  }
}
