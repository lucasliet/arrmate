import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/models.dart';

class TorrentListItem extends StatelessWidget {
  final Torrent torrent;

  /// Relation between this torrent and the media library, when known.
  final TorrentLink? link;

  final VoidCallback? onTap;

  /// Outer spacing of the card.
  ///
  /// Defaults to the activity list inset; screens that already pad their content
  /// horizontally pass a vertical-only margin so the insets do not stack.
  final EdgeInsetsGeometry margin;

  const TorrentListItem({
    super.key,
    required this.torrent,
    this.link,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 12, left: 16, right: 16),
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = link?.status.isCritical ?? false;

    return Card(
      margin: margin,
      elevation: 0,
      color: isCritical
          ? context.colorScheme.errorContainer.withValues(alpha: 0.35)
          : context.colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCritical
            ? BorderSide(color: context.colorScheme.error, width: 1.5)
            : BorderSide.none,
      ),
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (torrent.hasCategory) ...[
                              Text(
                                torrent.category!,
                                style: context.textTheme.labelMedium?.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  '·',
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(
                                        color: context
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${torrent.totalPeers} peers',
                              style: context.textTheme.labelMedium?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
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
                        if (_showsLinkBadge) ...[
                          const SizedBox(height: 4),
                          _buildLinkBadge(context),
                        ],
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
                  valueColor: AlwaysStoppedAnimation(torrent.status.color),
                  minHeight: 4,
                ),
              ),

              const SizedBox(height: 8),

              // Details (Speed / ETA / Seed time / Progress)
              //
              // Every entry is flexible: the row holds up to three of them and
              // must survive narrow screens and large text scales.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetail(
                    context,
                    '${formatPercentage(torrent.progress * 100)} done',
                  ),
                  if (torrent.hasSeedingTime) _buildSeedTime(context),
                  if (torrent.status.isActive) ...[
                    if (torrent.status == TorrentStatus.downloading)
                      _buildDetail(
                        context,
                        '↓ ${formatBytes(torrent.dlspeed)}/s',
                        color: Colors.blue,
                        bold: true,
                      ),
                    if (torrent.status == TorrentStatus.uploading)
                      _buildDetail(
                        context,
                        '↑ ${formatBytes(torrent.upspeed)}/s',
                        color: Colors.green,
                        bold: true,
                      ),
                    if (torrent.eta > 0 &&
                        torrent.eta < 8640000) // Avoid huge numbers
                      _buildDetail(
                        context,
                        // Runtime format assumes minutes usually
                        formatRuntime(torrent.eta ~/ 60),
                      ),
                  ] else ...[
                    _buildDetail(context, torrent.status.label),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One entry of the details row, ellipsized instead of overflowing.
  Widget _buildDetail(
    BuildContext context,
    String text, {
    Color? color,
    bool bold = false,
  }) {
    return Flexible(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodySmall?.copyWith(
          color: color ?? context.colorScheme.onSurfaceVariant,
          fontWeight: bold ? FontWeight.bold : null,
        ),
      ),
    );
  }

  /// Elapsed seeding time, so the card shows how long the torrent has been
  /// giving back before the user considers removing it.
  Widget _buildSeedTime(BuildContext context) {
    return Flexible(
      child: Row(
        key: const ValueKey('torrent-seed-time'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 12,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              formatDurationSeconds(torrent.seedingTime),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    IconData icon;
    switch (torrent.status) {
      case TorrentStatus.downloading:
        icon = Icons.downloading;
        break;
      case TorrentStatus.uploading:
        icon = Icons.upload;
        break;
      case TorrentStatus.pausedDL:
      case TorrentStatus.pausedUP:
        icon = Icons.pause_circle_outline;
        break;
      case TorrentStatus.error:
      case TorrentStatus.missingFiles:
        icon = Icons.error_outline;
        break;
      case TorrentStatus.checkingDL:
      case TorrentStatus.checkingUP:
      case TorrentStatus.checkingResumeData:
        icon = Icons.sync;
        break;
      case TorrentStatus.queuedDL:
      case TorrentStatus.queuedUP:
        icon = Icons.hourglass_empty;
        break;
      case TorrentStatus.stalledDL:
        icon = Icons.downloading;
        break;
      case TorrentStatus.stalledUP:
        icon = Icons.upload;
        break;
      case TorrentStatus.unknown:
        icon = Icons.question_mark;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: torrent.status.color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: torrent.status.color, size: 20),
    );
  }

  /// Whether the library relation is known well enough to be worth showing.
  bool get _showsLinkBadge =>
      link != null && link!.status != TorrentLinkStatus.unknown;

  /// Badge telling whether the torrent backs something in the media library.
  ///
  /// A relation inherited from a cross-seed sibling gets a second badge, so the
  /// user can tell why a torrent Radarr/Sonarr never referenced is still linked.
  Widget _buildLinkBadge(BuildContext context) {
    final status = link!.status;
    final color = status.color(context.colorScheme);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _buildBadgeChip(
          context,
          key: const ValueKey('torrent-link-badge'),
          icon: status.icon,
          label: link!.displayLabel,
          color: color,
        ),
        if (link!.isCrossSeed)
          _buildBadgeChip(
            context,
            key: const ValueKey('torrent-cross-seed-badge'),
            icon: Icons.content_copy,
            label: 'Cross-seed',
            color: color,
          ),
      ],
    );
  }

  /// Compact icon + label chip shared by the library badges.
  Widget _buildBadgeChip(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: torrent.status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        torrent.state.toUpperCase(),
        style: context.textTheme.labelSmall?.copyWith(
          color: torrent.status.color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
