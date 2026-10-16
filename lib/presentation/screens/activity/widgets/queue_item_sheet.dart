import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/models.dart';
import '../../../providers/instances_provider.dart';
import '../../../widgets/instance_origin_badge.dart';
import '../providers/activity_provider.dart';
import '../manual_import_screen.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../l10n/labels.dart';

/// Detailed bottom sheet for a queue item, allowing management (remove, blocklist).
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
                item.localizedDisplayTitle(context.l10n),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (item.episode != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.episode!.localizedFullLabel(context.l10n),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (item.instanceId != null) ...[
                const SizedBox(height: 8),
                InstanceOriginBadge(
                  instanceId: item.instanceId,
                  instanceType: item.instanceType,
                ),
              ],
              const SizedBox(height: 8),
              if (item.qualityLabel != null || item.size != null)
                Text(
                  formatListWithSeparator([
                    if (item.qualityLabel != null) item.qualityLabel!,
                    if (item.size != null) formatBytes(item.size!),
                  ]),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              if (item.movieId != null ||
                  item.seriesId != null ||
                  item.movie != null ||
                  item.series != null) ...[
                const SizedBox(height: 16),
                _buildOpenMediaSection(context),
              ],
              if (item.customFormats.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildCustomFormats(context, item),
              ],
              if (item.status == QueueStatus.downloading) ...[
                const SizedBox(height: 16),
                _buildProgressSection(context, item, progress),
              ],
              if ((item.errorMessage?.trim().isNotEmpty ?? false) ||
                  item.statusMessages.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildErrorSection(context, item),
              ],
              if (item.needsManualImport && item.downloadId != null) ...[
                const SizedBox(height: 24),
                _buildManualImportSection(context),
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

  Widget _buildOpenMediaSection(BuildContext context) {
    final item = widget.item;
    final movieId = item.movieId ?? item.movie?.id;
    final seriesId = item.seriesId ?? item.series?.id;
    final isMovie = movieId != null;
    final isSeries = seriesId != null;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: () => _openRelatedMedia(),
        icon: const Icon(Icons.open_in_new),
        label: Text(
          isMovie
              ? context.l10n.queueOpenMovie
              : isSeries
              ? context.l10n.queueOpenSeries
              : context.l10n.queueOpenDetails,
        ),
      ),
    );
  }

  Future<void> _openRelatedMedia() async {
    final item = widget.item;
    final movieId = item.movieId ?? item.movie?.id;
    final seriesId = item.seriesId ?? item.series?.id;
    final episodeId = item.episodeId ?? item.episode?.id;
    final seasonNumber = item.seasonNumber ?? item.episode?.seasonNumber;

    if (movieId == null && seriesId == null) return;

    if (item.instanceId != null && item.instanceType != null) {
      try {
        await ref
            .read(instancesProvider.notifier)
            .selectInstance(item.instanceType!, item.instanceId!);
      } catch (_) {
        // Instance selection is best-effort; navigation should still proceed.
      }
    }
    if (!mounted) return;

    Navigator.of(context).pop();
    if (movieId != null) {
      context.go('/movies/$movieId');
    } else if (seriesId != null) {
      if (episodeId != null &&
          episodeId > 0 &&
          seasonNumber != null &&
          seasonNumber >= 0) {
        context.go('/series/$seriesId/season/$seasonNumber/episode/$episodeId');
      } else {
        context.go('/series/$seriesId');
      }
    }
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
        item.status.localizedLabel(context.l10n).toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    QueueItem item,
    double progress,
  ) {
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
                _formatTimeRemaining(
                  context.l10n,
                  item.estimatedCompletionTime!,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress, minHeight: 8),
        ),
      ],
    );
  }

  Widget _buildErrorSection(BuildContext context, QueueItem item) {
    final errorMessage = item.errorMessage?.trim();
    final message = errorMessage?.isNotEmpty == true
        ? errorMessage!
        : item.statusMessages.firstOrNull?.messages.firstOrNull ??
              item.statusMessages.firstOrNull?.title ??
              context.l10n.queueUnknownError;

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

  Widget _buildManualImportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.queueManualImportRequired,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.queueManualImportDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _showManualImportScreen(context),
            icon: const Icon(Icons.file_download),
            label: Text(context.l10n.manualImportTitle),
          ),
        ),
      ],
    );
  }

  void _showManualImportScreen(BuildContext context) {
    Navigator.pop(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => ManualImportScreen(item: widget.item),
      );
    });
  }

  Widget _buildActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.queueRemovalOptions,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: Text(context.l10n.queueRemoveFromClient),
          subtitle: Text(context.l10n.queueRemoveFromClientSubtitle),
          value: _removeFromClient,
          onChanged: (value) => setState(() => _removeFromClient = value),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: Text(context.l10n.queueAddToBlocklist),
          subtitle: Text(context.l10n.queueAddToBlocklistSubtitle),
          value: _addToBlocklist,
          onChanged: (value) => setState(() {
            _addToBlocklist = value;
            if (value) _searchForReplacement = false;
          }),
          contentPadding: EdgeInsets.zero,
        ),
        if (!_addToBlocklist)
          SwitchListTile(
            title: Text(context.l10n.queueSearchReplacement),
            subtitle: Text(context.l10n.queueSearchReplacementSubtitle),
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
            label: Text(context.l10n.queueRemoveFromQueue),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, QueueItem item) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.queueInformation,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (item.qualityLabel != null)
          _DetailRow(label: l10n.commonQuality, value: item.qualityLabel!),
        _DetailRow(
          label: l10n.commonLanguage,
          value: item.localizedLanguagesLabel(l10n),
        ),
        if (item.customFormatsLabel != null)
          _DetailRow(
            label: l10n.queueCustomFormats,
            value: item.customFormatsLabel!,
          ),
        if (item.customFormatScore != null)
          _DetailRow(
            label: l10n.queueCustomFormatScore,
            value: formatCustomScore(item.customFormatScore!),
          ),
        if (item.indexer != null)
          _DetailRow(label: l10n.commonIndexer, value: item.indexer!),
        _DetailRow(label: l10n.commonProtocol, value: item.protocol),
        if (item.downloadClient != null)
          _DetailRow(label: l10n.commonClient, value: item.downloadClient!),
        if (item.added != null)
          _DetailRow(
            label: l10n.labelSortAdded,
            value: formatDate(item.added!.toLocal()),
          ),
        if (item.taskGroupCount > 1)
          _DetailRow(
            label: l10n.queueGroupedTasks,
            value: '${item.taskGroupCount}',
          ),
        if (item.outputPath != null)
          _DetailRow(label: l10n.queueDetailPath, value: item.outputPath!),
      ],
    );
  }

  Widget _buildCustomFormats(BuildContext context, QueueItem item) {
    final color = Theme.of(context).colorScheme.secondary;
    final labels = [
      if (item.customFormatScore != null)
        formatCustomScore(item.customFormatScore!),
      ...item.customFormats.map((format) => format.name),
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: labels.map((label) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTimeRemaining(AppLocalizations l10n, DateTime eta) {
    final diff = eta.difference(DateTime.now());
    if (diff.isNegative) return l10n.queueEtaDone;

    if (diff.inDays > 0) {
      return l10n.queueTimeRemainingDaysHours(diff.inDays, diff.inHours % 24);
    }
    if (diff.inHours > 0) {
      return l10n.queueTimeRemainingHoursMinutes(
        diff.inHours,
        diff.inMinutes % 60,
      );
    }
    if (diff.inMinutes > 0) {
      return l10n.queueTimeRemainingMinutes(diff.inMinutes);
    }
    return l10n.queueTimeRemainingLessThanMinute;
  }

  Future<void> _handleRemove() async {
    final item = widget.item;

    try {
      await ref
          .read(queueProvider.notifier)
          .removeQueueItem(
            item,
            removeFromClient: _removeFromClient,
            blocklist: _addToBlocklist,
            skipRedownload: !_searchForReplacement,
          );

      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.queueItemRemoved)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.commonErrorWithDetails(describeError(e, context.l10n)),
          ),
        ),
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
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
