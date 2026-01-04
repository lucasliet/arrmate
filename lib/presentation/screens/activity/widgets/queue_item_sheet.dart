import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/models.dart';
import '../providers/activity_provider.dart';

class QueueItemSheet extends ConsumerStatefulWidget {
  final QueueItem item;

  const QueueItemSheet({super.key, required this.item});

  @override
  ConsumerState<QueueItemSheet> createState() => _QueueItemSheetState();
}

class _QueueItemSheetState extends ConsumerState<QueueItemSheet> {
  bool _removeFromClient = true;
  bool _addToBlocklist = false;
  bool _searchForReplacement = true;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = item.progressPercent / 100;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
              _buildStatusBadge(context),
              const SizedBox(height: 8),
              Text(
                item.displayTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (item.episode != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.episode!.fullLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              if (item.size != null)
                Row(
                  children: [
                    Text(
                      item.protocol,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    const Text('•'),
                    const SizedBox(width: 8),
                    Text(
                      formatBytes(item.size!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              if (item.status == QueueStatus.downloading) ...[
                const SizedBox(height: 16),
                _buildProgressSection(context, item, progress),
              ],
              if (item.errorMessage != null || item.statusMessages.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildErrorSection(context, item),
              ],
              const SizedBox(height: 24),
              _buildActionsSection(context),
              const SizedBox(height: 24),
              _buildDetailsSection(context, item),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final item = widget.item;
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        item.status.label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, QueueItem item, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (item.estimatedCompletionTime != null)
              Text(
                _formatTimeRemaining(item.estimatedCompletionTime!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection(BuildContext context, QueueItem item) {
    final message = item.errorMessage ?? 
        item.statusMessages.firstOrNull?.messages.firstOrNull ?? 
        'Unknown error';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Removal Options',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Remove from Download Client'),
          subtitle: const Text('Delete the download from the client'),
          value: _removeFromClient,
          onChanged: (value) => setState(() => _removeFromClient = value),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Add to Blocklist'),
          subtitle: const Text('Prevent this release from being grabbed again'),
          value: _addToBlocklist,
          onChanged: (value) => setState(() {
            _addToBlocklist = value;
            if (value) _searchForReplacement = false;
          }),
          contentPadding: EdgeInsets.zero,
        ),
        if (!_addToBlocklist)
          SwitchListTile(
            title: const Text('Search for Replacement'),
            subtitle: const Text('Automatically search for another release'),
            value: _searchForReplacement,
            onChanged: (value) => setState(() => _searchForReplacement = value),
            contentPadding: EdgeInsets.zero,
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleRemove,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            icon: const Icon(Icons.delete),
            label: const Text('Remove from Queue'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, QueueItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _DetailRow(label: 'Protocol', value: item.protocol),
        if (item.downloadClient != null)
          _DetailRow(label: 'Client', value: item.downloadClient!),
        if (item.outputPath != null)
          _DetailRow(label: 'Path', value: item.outputPath!),
      ],
    );
  }

  String _formatTimeRemaining(DateTime eta) {
    final diff = eta.difference(DateTime.now());
    if (diff.isNegative) return 'Done';

    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h remaining';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m remaining';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m remaining';
    return 'Less than a minute';
  }

  Future<void> _handleRemove() async {
    final item = widget.item;
    
    try {
      await ref.read(queueProvider.notifier).removeQueueItem(
            item.id,
            removeFromClient: _removeFromClient,
            blocklist: _addToBlocklist,
            skipRedownload: !_searchForReplacement,
          );
      
      if (!mounted) return;
      
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from queue')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
