import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/qbittorrent/qbittorrent_models.dart';

class TorrentPeerItem extends StatelessWidget {
  final TorrentPeer peer;

  const TorrentPeerItem({super.key, required this.peer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasCountry = peer.countryCode != null && peer.countryCode!.isNotEmpty;

    final metaParts = <String>[
      if (peer.country != null && peer.country!.isNotEmpty) peer.country!,
      if (peer.client != null && peer.client!.isNotEmpty) peer.client!,
      formatPercentage(peer.progress * 100),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: hasCountry
                ? Text(
                    countryFlagEmoji(peer.countryCode),
                    style: const TextStyle(fontSize: 24),
                  )
                : Icon(
                    Icons.public_outlined,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.address,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  metaParts.join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (peer.isDownloading)
                Text(
                  '↓ ${formatBytes(peer.dlSpeed)}/s',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (peer.isUploading)
                Text(
                  '↑ ${formatBytes(peer.upSpeed)}/s',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
