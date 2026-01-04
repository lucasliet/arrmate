import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/models.dart';
import '../../../core/utils/formatters.dart';
import 'providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(activityHistoryProvider);

    return historyAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No history events'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(activityHistoryProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: events.length + 1,
            itemBuilder: (context, index) {
              if (index == events.length) {
                return _LoadMoreButton(
                  hasMore: ref.watch(activityHistoryProvider.notifier).hasMore,
                  onPressed: () => ref.read(activityHistoryProvider.notifier).loadMore(),
                );
              }

              return _HistoryEventCard(event: events[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(activityHistoryProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}


class _HistoryEventCard extends StatelessWidget {
  final HistoryEvent event;

  const _HistoryEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEventDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _EventTypeBadge(eventType: event.eventType),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.sourceTitle ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.high_quality,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.quality.quality.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatRelativeTime(event.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }

  void _showEventDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _HistoryEventSheet(event: event),
    );
  }
}

class _EventTypeBadge extends StatelessWidget {
  final HistoryEventType eventType;

  const _EventTypeBadge({required this.eventType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor(context).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        eventType.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getColor(context),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Color _getColor(BuildContext context) {
    switch (eventType) {
      case HistoryEventType.grabbed:
        return Colors.blue;
      case HistoryEventType.imported:
        return Colors.green;
      case HistoryEventType.failed:
        return Colors.red;
      case HistoryEventType.deleted:
        return Colors.orange;
      case HistoryEventType.renamed:
        return Colors.purple;
      case HistoryEventType.ignored:
        return Colors.grey;
      case HistoryEventType.unknown:
        return Colors.grey;
    }
  }
}

class _HistoryEventSheet extends StatelessWidget {
  final HistoryEvent event;

  const _HistoryEventSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  _EventTypeBadge(eventType: event.eventType),
                  const SizedBox(width: 8),
                  Text(
                    event.eventType.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                event.sourceTitle ?? 'Unknown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _DetailRow(label: 'Quality', value: event.quality.quality.name),
              _DetailRow(label: 'Language', value: event.languageLabel),
              _DetailRow(
                label: 'Date',
                value: formatDate(event.date),
              ),
              if (event.indexer != null)
                _DetailRow(label: 'Indexer', value: event.indexer!),
              if (event.downloadClient != null)
                _DetailRow(label: 'Client', value: event.downloadClient!),
              if (event.scoreLabel != null)
                _DetailRow(label: 'Score', value: event.scoreLabel!),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final bool hasMore;
  final VoidCallback onPressed;

  const _LoadMoreButton({required this.hasMore, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return const SizedBox(height: 16);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: OutlinedButton(
          onPressed: onPressed,
          child: const Text('Load More'),
        ),
      ),
    );
  }
}
