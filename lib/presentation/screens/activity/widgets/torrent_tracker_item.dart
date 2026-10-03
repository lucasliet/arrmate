import 'package:flutter/material.dart';

import '../../../../domain/models/qbittorrent/qbittorrent_models.dart';

/// One tracker row: host, status, peer counts, and the announce URL.
class TorrentTrackerItem extends StatelessWidget {
  /// Tracker returned by qBittorrent.
  final TorrentTracker tracker;

  const TorrentTrackerItem({super.key, required this.tracker});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tracker.isSpecial ? Icons.hub_outlined : Icons.podcasts_outlined,
            size: 22,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tracker.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tracker.status.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _metaLine(tracker),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!tracker.isSpecial && tracker.url.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SelectableText(
                    tracker.url,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (tracker.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tracker.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tracker.status == TorrentTrackerStatus.notWorking
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (tracker.status) {
      case TorrentTrackerStatus.working:
        return Colors.green;
      case TorrentTrackerStatus.updating:
        return Colors.blue;
      case TorrentTrackerStatus.notWorking:
        return colorScheme.error;
      case TorrentTrackerStatus.notContacted:
      case TorrentTrackerStatus.disabled:
      case TorrentTrackerStatus.unknown:
        return colorScheme.onSurfaceVariant;
    }
  }
}

String _metaLine(TorrentTracker tracker) {
  final parts = <String>[
    _count(tracker.numSeeds, 'seed', 'seeds'),
    _count(tracker.numLeeches, 'leecher', 'leechers'),
    _count(tracker.numPeers, 'peer', 'peers'),
  ];
  if (tracker.numDownloaded > 0) {
    parts.add(_count(tracker.numDownloaded, 'download', 'downloads'));
  }
  if (!tracker.isSpecial && tracker.tier > 0) {
    parts.add('Tier ${tracker.tier}');
  }
  return parts.join(' · ');
}

String _count(int value, String singular, String plural) {
  return '$value ${value == 1 ? singular : plural}';
}
