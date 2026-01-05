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
import '../providers/series_metadata_provider.dart';

class SeriesMetadataSection extends ConsumerWidget {
  final int seriesId;

  const SeriesMetadataSection({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilesSection(context, ref),
        const SizedBox(height: 24),
        _buildHistorySection(context, ref),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFilesSection(BuildContext context, WidgetRef ref) {
    final filesState = ref.watch(seriesFilesProvider(seriesId));
    final extraFilesState = ref.watch(seriesExtraFilesProvider(seriesId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Files',
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
                'No media files',
              );
            }
            return Column(
              children: files
                  .map((file) => MediaFileCard(
                        file: file,
                        onTap: () => context.showBottomSheet(
                          MediaFileDetailsSheet(
                            file: file,
                            onDelete: () async {
                              final controller = ref.read(
                                seriesMetadataControllerProvider(seriesId),
                              );
                              await controller.deleteFile(file.id);
                            },
                          ),
                        ),
                        onDelete: () async {
                          final shouldDelete = await _confirmDelete(context);
                          if (shouldDelete == true) {
                            final controller = ref.read(
                              seriesMetadataControllerProvider(seriesId),
                            );
                            await controller.deleteFile(file.id);
                            if (context.mounted) {
                              context.showSnackBar('File deleted');
                            }
                          }
                        },
                      ))
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
            message: 'Failed to load files',
            onRetry: () => ref.refresh(seriesFilesProvider(seriesId)),
          ),
        ),
        const SizedBox(height: 12),
        extraFilesState.when(
          data: (extraFiles) {
            if (extraFiles.isEmpty) return const SizedBox();
            return Column(
              children: extraFiles
                  .map((file) => ExtraFileCard.fromSeriesExtraFile(file))
                  .toList(),
            );
          },
          loading: () => const SizedBox(),
          error: (error, stack) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(seriesHistoryProvider(seriesId));
    final theme = Theme.of(context);

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
        historyState.when(
          data: (events) {
            if (events.isEmpty) {
              return _buildEmptyState(
                context,
                Icons.history,
                'No history events',
              );
            }
            final limitedEvents = events.take(10).toList();
            return Column(
              children: limitedEvents
                  .map((event) => HistoryEventCard(
                        event: event,
                        onTap: () => context.showBottomSheet(
                          HistoryEventDetailsSheet(event: event),
                        ),
                      ))
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
            message: 'Failed to load history',
            onRetry: () => ref.refresh(seriesHistoryProvider(seriesId)),
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
  }
}
