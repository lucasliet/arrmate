import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/models.dart';
import '../providers/qbittorrent_provider.dart';
import '../qbittorrent/change_location_sheet.dart';
import '../qbittorrent/torrent_files_sheet.dart';

class TorrentDetailsSheet extends ConsumerWidget {
  final Torrent torrent;

  const TorrentDetailsSheet({super.key, required this.torrent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildStatusBadge(context),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      torrent.name,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  children: [
                    // Progress Section
                    _buildSectionTitle(context, 'Progress'),
                    const SizedBox(height: 8),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: torrent.progress,
                        minHeight: 8,
                        backgroundColor: context.colorScheme.surfaceDim,
                        valueColor: AlwaysStoppedAnimation(
                          _getStatusColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${formatPercentage(torrent.progress)} completed',
                          style: context.textTheme.bodyMedium,
                        ),
                        Text(
                          torrent.eta > 0 && torrent.eta < 8640000
                              ? 'ETA: ${formatRuntime(torrent.eta ~/ 60)}'
                              : 'ETA: ∞',
                          style: context.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth / 2 - 8;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildStatItem(
                              context,
                              'Total Size',
                              formatBytes(torrent.size),
                              width: width,
                            ),
                            _buildStatItem(
                              context,
                              'Downloaded',
                              formatBytes(torrent.downloaded),
                              width: width,
                            ),
                            _buildStatItem(
                              context,
                              'Uploaded',
                              formatBytes(torrent.uploaded),
                              width: width,
                            ),
                            _buildStatItem(
                              context,
                              'Ratio',
                              torrent.ratio.toStringAsFixed(2),
                              width: width,
                            ),
                            if (torrent.status.isActive) ...[
                              _buildStatItem(
                                context,
                                'DL Speed',
                                '${formatBytes(torrent.dlspeed)}/s',
                                width: width,
                                color: Colors.blue,
                              ),
                              _buildStatItem(
                                context,
                                'UL Speed',
                                '${formatBytes(torrent.upspeed)}/s',
                                width: width,
                                color: Colors.green,
                              ),
                            ],
                            _buildStatItem(
                              context,
                              'Seeds',
                              '${torrent.numSeeds} connected',
                              width: width,
                            ),
                            _buildStatItem(
                              context,
                              'Leechers',
                              '${torrent.numLeechs} connected',
                              width: width,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Info Section
                    _buildSectionTitle(context, 'Information'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      'Added On',
                      _formatDate(torrent.addedOn),
                    ),
                    _buildInfoRow(
                      context,
                      'Category',
                      torrent.category?.isNotEmpty == true
                          ? torrent.category!
                          : 'None',
                    ),
                    _buildInfoRow(context, 'Save Path', torrent.savePath),
                    _buildInfoRow(
                      context,
                      'Tags',
                      torrent.tags.isNotEmpty
                          ? torrent.tags.join(', ')
                          : 'None',
                    ),
                    _buildInfoRow(context, 'Hash', torrent.hash),

                    const SizedBox(height: 32),

                    // Actions
                    _buildSectionTitle(context, 'Actions'),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: torrent.status.isPaused
                              ? FilledButton.icon(
                                  onPressed: () {
                                    ref
                                        .read(
                                          qbittorrentTorrentsProvider.notifier,
                                        )
                                        .resumeTorrents([torrent.hash]);
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Resume'),
                                )
                              : FilledButton.icon(
                                  onPressed: () {
                                    ref
                                        .read(
                                          qbittorrentTorrentsProvider.notifier,
                                        )
                                        .pauseTorrents([torrent.hash]);
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.pause),
                                  label: const Text('Pause'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ref
                                  .read(qbittorrentTorrentsProvider.notifier)
                                  .recheckTorrents([torrent.hash]);
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.sync),
                            label: const Text('Recheck'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    TorrentFilesSheet(torrent: torrent),
                              );
                            },
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Files'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    ChangeLocationSheet(torrent: torrent),
                              );
                            },
                            icon: const Icon(Icons.drive_file_move_outline),
                            label: const Text('Move'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _confirmDelete(context, ref),
                        icon: const Icon(Icons.delete),
                        label: const Text('Remove Torrent'),
                        style: TextButton.styleFrom(
                          foregroundColor: context.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    bool deleteFiles = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Remove Torrent?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to remove "${torrent.name}"?'),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Also delete files on disk'),
                  contentPadding: EdgeInsets.zero,
                  value: deleteFiles,
                  onChanged: (val) =>
                      setState(() => deleteFiles = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(qbittorrentTorrentsProvider.notifier).deleteTorrents(
                    [torrent.hash],
                    deleteFiles: deleteFiles,
                  );
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close sheet
                },
                style: FilledButton.styleFrom(
                  backgroundColor: context.colorScheme.error,
                ),
                child: const Text('Remove'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: context.textTheme.labelLarge?.copyWith(
        color: context.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value, {
    required double width,
    Color? color,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: context.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color = _getStatusColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        torrent.state.toUpperCase(),
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    if (torrent.status.hasError) return context.colorScheme.error;
    if (torrent.status == TorrentStatus.downloading) return Colors.blue;
    if (torrent.status == TorrentStatus.uploading) return Colors.green;
    if (torrent.status.isPaused) return Colors.orange;
    if (torrent.status == TorrentStatus.queuedDL ||
        torrent.status == TorrentStatus.queuedUP) {
      return context.colorScheme.secondary;
    }
    return context.colorScheme.primary;
  }

  String _formatDate(int timestamp) {
    // qBittorrent returns timestamp in seconds
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return formatDate(date);
  }
}
