import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../screens/activity/widgets/torrent_details_sheet.dart';
import '../../screens/activity/widgets/torrent_list_item.dart';
import '../../widgets/common_widgets.dart';
import '../providers/media_torrents_provider.dart';

/// Lists the download-client torrents backing a library item and opens the
/// torrent details sheet for each.
///
/// The reverse of the "Open in library" shortcut offered by
/// [TorrentDetailsSheet]: that button walks from a torrent to its media, this
/// section walks from the media back to its torrents.
class MediaTorrentsSection extends ConsumerWidget {
  /// Provider resolving the torrents of the media item being shown.
  final AutoDisposeFutureProvider<MediaTorrents> provider;

  /// Restricts the list to torrents grabbed for this episode.
  ///
  /// A season pack covers several episodes and therefore shows up under each of
  /// them. `null` lists every torrent of the media item.
  final int? episodeId;

  const MediaTorrentsSection({
    super.key,
    required this.provider,
    this.episodeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    final theme = Theme.of(context);

    // Without a download client there is nothing to link to, and an empty list
    // would wrongly read as "this media has no torrents".
    if (state.valueOrNull?.qbittorrentSkipped ?? false) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Torrents',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        state.when(
          data: (media) {
            final torrents = _filter(media.torrents);
            if (torrents.isEmpty) {
              return _buildEmptyState(
                context,
                Icons.cloud_download_outlined,
                'No torrents in the download client',
              );
            }
            return Column(
              children: [
                for (final linked in torrents)
                  TorrentListItem(
                    torrent: linked.torrent,
                    link: linked.link,
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => TorrentDetailsSheet(
                        torrent: linked.torrent,
                        link: linked.link,
                        showOpenInLibrary: false,
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(paddingMd),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => ErrorDisplay(
            message: 'Failed to load torrents',
            onRetry: () => ref.invalidate(provider),
          ),
        ),
      ],
    );
  }

  /// Narrows [torrents] to the requested episode, when one was given.
  List<LinkedTorrent> _filter(List<LinkedTorrent> torrents) {
    final episodeId = this.episodeId;
    if (episodeId == null) return torrents;
    return torrents
        .where((linked) => linked.episodeIds.contains(episodeId))
        .toList();
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String message) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(paddingLg),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
