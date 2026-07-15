import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/qbittorrent/qbittorrent_models.dart';
import '../../../widgets/common_widgets.dart';
import '../providers/torrent_file_providers.dart';
import '../widgets/torrent_peer_item.dart';

class TorrentPeersSheet extends ConsumerWidget {
  final Torrent torrent;

  const TorrentPeersSheet({super.key, required this.torrent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peersAsync = ref.watch(torrentPeersProvider(torrent.hash));

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
                child: peersAsync.when(
                  data: (peers) {
                    if (peers.isEmpty) {
                      return const EmptyState(
                        icon: Icons.people_outline,
                        title: 'No peers connected',
                        subtitle:
                            'Peers will appear when the torrent is active',
                      );
                    }
                    final sorted = List<TorrentPeer>.from(peers)
                      ..sort((a, b) {
                        final dlCmp = b.dlSpeed.compareTo(a.dlSpeed);
                        if (dlCmp != 0) return dlCmp;
                        return b.upSpeed.compareTo(a.upSpeed);
                      });
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: sorted.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          TorrentPeerItem(peer: sorted[index]),
                    );
                  },
                  loading: () =>
                      const LoadingIndicator(message: 'Loading peers...'),
                  error: (error, stack) => ErrorDisplay(
                    message: 'Failed to load peers',
                    onRetry: () =>
                        ref.invalidate(torrentPeersProvider(torrent.hash)),
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
              Icon(Icons.people_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peers',
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
