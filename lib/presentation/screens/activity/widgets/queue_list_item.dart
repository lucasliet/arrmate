import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/models.dart';
import 'queue_item_sheet.dart';

class QueueListItem extends ConsumerWidget {
  final QueueItem item;

  const QueueListItem({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = item.progressPercent / 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showQueueItemSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIcon(context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.episode != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.episode!.fullLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusBadge(context),
                            if (item.needsManualImport) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Colors.orange,
                              ),
                            ],
                            const Spacer(),
                            if (item.status == QueueStatus.downloading &&
                                item.sizeleft > 0)
                              Text(
                                '${formatBytes(item.sizeleft)} left',
                                style: theme.textTheme.labelSmall,
                              ),
                            if (item.estimatedCompletionTime != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '•  ${_formatEta(item.estimatedCompletionTime!)}',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.surfaceDim,
                  valueColor: AlwaysStoppedAnimation(
                    item.hasWarning || item.hasError
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  minHeight: 4,
                ),
              ),
              if (item.needsManualImport) ...[
                const SizedBox(height: 8),
                Text(
                  'Unable to Import Automatically',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else if (item.errorMessage != null ||
                  item.statusMessages.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.errorMessage ??
                      item.statusMessages.first.messages.firstOrNull ??
                      'Unknown error',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showQueueItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => QueueItemSheet(item: item),
    );
  }

  Widget _buildIcon(BuildContext context) {
    // Distinguish Series vs Movie
    final isMovie = item.movieId != null || item.movie != null;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      child: Icon(
        isMovie ? Icons.movie : Icons.tv,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    switch (item.status) {
      case QueueStatus.downloading:
        color = Colors.blue;
        break;
      case QueueStatus.completed:
        color = Colors.green;
        break;
      case QueueStatus.failed:
      case QueueStatus.warning:
        color = Colors.red;
        break;
      case QueueStatus.paused:
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        item.status.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatEta(DateTime eta) {
    final diff = eta.difference(DateTime.now());
    if (diff.isNegative) return 'Done';

    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return '<1m';
  }
}
