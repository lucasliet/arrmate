import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/qbittorrent/qbittorrent_models.dart';

import '../providers/torrent_file_providers.dart';

class TorrentFileItem extends ConsumerWidget {
  final String torrentHash;
  final TorrentFile file;

  const TorrentFileItem({
    super.key,
    required this.torrentHash,
    required this.file,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isDownloading = file.priority.isDownloading;

    return InkWell(
      onTap: () => _showPriorityMenu(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Checkbox for basic "Download / Don't Download" toggle
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: isDownloading,
                activeColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (value) {
                  final newPriority = (value ?? false)
                      ? FilePriority.normal
                      : FilePriority.doNotDownload;
                  ref
                      .read(torrentActionProvider.notifier)
                      .setSingleFilePriority(
                        torrentHash,
                        file.index,
                        newPriority,
                      );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: isDownloading
                          ? null
                          : TextDecoration.lineThrough,
                      color: isDownloading
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatBytes(file.size),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '·',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatPercentage(file.progress * 100),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (file.priority != FilePriority.normal && isDownloading)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(
                              file.priority,
                              isDark,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getPriorityColor(
                                file.priority,
                                isDark,
                              ).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                file.priority.icon,
                                size: 12,
                                color: _getPriorityColor(file.priority, isDark),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                file.priority.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: _getPriorityColor(
                                    file.priority,
                                    isDark,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: () => _showPriorityMenu(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(FilePriority priority, bool isDark) {
    switch (priority) {
      case FilePriority.high:
      case FilePriority.maximal:
        return Colors.amber;
      case FilePriority.low:
        return Colors.blue;
      case FilePriority.doNotDownload:
        return Colors.grey;
      case FilePriority.normal:
        return isDark ? Colors.white70 : Colors.black54;
    }
  }

  void _showPriorityMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _PrioritySelectionSheet(
        currentPriority: file.priority,
        onSelect: (newPriority) {
          Navigator.pop(context);
          ref
              .read(torrentActionProvider.notifier)
              .setSingleFilePriority(torrentHash, file.index, newPriority);
        },
      ),
    );
  }
}

class _PrioritySelectionSheet extends StatelessWidget {
  final FilePriority currentPriority;
  final ValueChanged<FilePriority> onSelect;

  const _PrioritySelectionSheet({
    required this.currentPriority,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Set Priority',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          ...[
            FilePriority.high,
            FilePriority.normal,
            FilePriority.low,
            FilePriority.doNotDownload,
          ].map(
            (priority) => ListTile(
              leading: Icon(
                priority.icon,
                color: priority == currentPriority
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                priority.label,
                style: TextStyle(
                  fontWeight: priority == currentPriority
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: priority == currentPriority
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              trailing: priority == currentPriority
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => onSelect(priority),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
