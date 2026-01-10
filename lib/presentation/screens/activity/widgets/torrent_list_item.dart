import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/models.dart';

class TorrentListItem extends StatelessWidget {
  final Torrent torrent;
  final VoidCallback? onTap;

  const TorrentListItem({super.key, required this.torrent, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      elevation: 0,
      color: context.colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusIcon(context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          torrent.name,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusBadge(context),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${formatBytes(torrent.size)} • ${torrent.ratio.toStringAsFixed(2)}',
                                style: context.textTheme.labelMedium?.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: torrent.progress,
                  backgroundColor: context.colorScheme.surfaceDim,
                  valueColor: AlwaysStoppedAnimation(_getStatusColor(context)),
                  minHeight: 4,
                ),
              ),

              const SizedBox(height: 8),

              // Details (Speed / ETA / Progress)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${formatPercentage(torrent.progress)} done',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (torrent.status.isActive) ...[
                    if (torrent.status == TorrentStatus.downloading)
                      Text(
                        '↓ ${formatBytes(torrent.dlspeed)}/s',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (torrent.status == TorrentStatus.uploading)
                      Text(
                        '↑ ${formatBytes(torrent.upspeed)}/s',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (torrent.eta > 0 &&
                        torrent.eta < 8640000) // Avoid huge numbers
                      Text(
                        formatRuntime(
                          torrent.eta ~/ 60,
                        ), // Runtime format assumes minutes usually
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ] else ...[
                    Text(
                      torrent.status.label,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (torrent.status) {
      case TorrentStatus.downloading:
        icon = Icons.downloading;
        color = Colors.blue;
        break;
      case TorrentStatus.uploading:
        icon = Icons.upload;
        color = Colors.green;
        break;
      case TorrentStatus.pausedDL:
      case TorrentStatus.pausedUP:
        icon = Icons.pause_circle_outline;
        color = Colors.orange;
        break;
      case TorrentStatus.error:
      case TorrentStatus.missingFiles:
        icon = Icons.error_outline;
        color = context.colorScheme.error;
        break;
      case TorrentStatus.checkingDL:
      case TorrentStatus.checkingUP:
      case TorrentStatus.checkingResumeData:
        icon = Icons.sync;
        color = Colors.purple;
        break;
      case TorrentStatus.queuedDL:
      case TorrentStatus.queuedUP:
        icon = Icons.hourglass_empty;
        color = context.colorScheme.secondary;
        break;
      case TorrentStatus.stalledDL:
        icon = Icons.downloading;
        color = Colors.grey;
        break;
      case TorrentStatus.stalledUP:
        icon = Icons.upload;
        color = Colors.grey;
        break;
      case TorrentStatus.unknown:
        icon = Icons.question_mark;
        color = context.colorScheme.outline;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color = _getStatusColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        torrent.state.toUpperCase(),
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
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
}
