import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/qbittorrent/qbittorrent_models.dart';
import '../../../widgets/common_widgets.dart';
import '../providers/torrent_file_providers.dart';
import '../widgets/torrent_tracker_item.dart';

/// Lists the announce trackers and DHT/PeX/LSD rows for one torrent.
class TorrentTrackersSheet extends ConsumerWidget {
  /// Torrent whose trackers are loaded.
  final Torrent torrent;

  const TorrentTrackersSheet({super.key, required this.torrent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackersAsync = ref.watch(torrentTrackersProvider(torrent.hash));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: trackersAsync.when(
                  data: (trackers) {
                    if (trackers.isEmpty) {
                      return const EmptyState(
                        icon: Icons.podcasts_outlined,
                        title: 'No trackers',
                        subtitle:
                            'Announce URLs appear here once qBittorrent has them',
                      );
                    }
                    final sorted = List<TorrentTracker>.from(trackers)
                      ..sort(TorrentTracker.compare);
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: sorted.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          TorrentTrackerItem(tracker: sorted[index]),
                    );
                  },
                  loading: () =>
                      const LoadingIndicator(message: 'Loading trackers...'),
                  error: (error, stack) => ErrorDisplay(
                    message: 'Failed to load trackers',
                    onRetry: () =>
                        ref.invalidate(torrentTrackersProvider(torrent.hash)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.podcasts_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trackers',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      torrent.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
