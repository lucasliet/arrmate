import 'package:flutter/material.dart';

import '../../../core/services/purge_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/models.dart';

/// Resolves the [SeedingAction] to apply for a purge, showing the warning
/// dialog only when there are below-threshold torrents.
///
/// Runs the [preview] (a non-mutating [PurgePreview] fetcher), reads the
/// configured [minimumSeedingDays], and:
/// - Returns [SeedingAction.deleteAll] immediately when nothing is below the
///   threshold (or qBittorrent is skipped).
/// - Shows [showSeedingWarningDialog] otherwise and returns the user's choice.
/// - Returns `null` when the user cancels or dismisses the dialog, signaling
///   the caller to abort the whole purge.
Future<SeedingAction?> resolveSeedingAction({
  required BuildContext context,
  required Future<PurgePreview> Function(int minimumSeedingSeconds) preview,
  required int minimumSeedingDays,
}) async {
  final minimumSeconds = minimumSeedingDays * 86400;
  final purgePreview = await preview(minimumSeconds);

  if (purgePreview.qbittorrentSkipped || purgePreview.belowThreshold.isEmpty) {
    return SeedingAction.deleteAll;
  }

  if (!context.mounted) return SeedingAction.cancel;

  return showSeedingWarningDialog(
    context: context,
    belowThreshold: purgePreview.belowThreshold,
    minimumSeedingDays: minimumSeedingDays,
  );
}

/// Shows a confirmation dialog when some torrents being purged have seeded for
/// less than the configured minimum.
///
/// The catalog and media files are always purged; this dialog only governs
/// which torrents are removed from qBittorrent. Returns the user's
/// [SeedingAction], or `null` if the dialog was dismissed.
Future<SeedingAction?> showSeedingWarningDialog({
  required BuildContext context,
  required List<Torrent> belowThreshold,
  required int minimumSeedingDays,
}) {
  return showDialog<SeedingAction>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Torrents still seeding'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The following ${belowThreshold.length} torrent'
                '${belowThreshold.length == 1 ? '' : 's'} seeded for less '
                'than the minimum of $minimumSeedingDays '
                'day${minimumSeedingDays == 1 ? '' : 's'}:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...belowThreshold.map((t) => TorrentSeedingTile(torrent: t)),
              const SizedBox(height: 12),
              Text(
                'The title will still be removed from the library and its '
                'files deleted either way.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, SeedingAction.cancel),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () =>
                Navigator.pop(context, SeedingAction.keepBelowThreshold),
            child: const Text('Keep seeding'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, SeedingAction.deleteAll),
            child: const Text('Delete all'),
          ),
        ],
      );
    },
  );
}

/// Shows a warning dialog when a single torrent being deleted has seeded for
/// less than the configured minimum.
///
/// Unlike [showSeedingWarningDialog], this is a binary confirm/cancel flow
/// used by the qBittorrent torrent delete. Returns `true` when the user
/// confirms deletion, `false` (or `null` on dismiss) when aborting.
Future<bool?> showSingleTorrentSeedingWarning({
  required BuildContext context,
  required Torrent torrent,
  required int minimumSeedingDays,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Torrent still seeding'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This torrent seeded for less than the minimum of '
                '$minimumSeedingDays '
                'day${minimumSeedingDays == 1 ? '' : 's'}:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TorrentSeedingTile(torrent: torrent),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep torrent'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete anyway'),
          ),
        ],
      );
    },
  );
}

class TorrentSeedingTile extends StatelessWidget {
  final Torrent torrent;

  const TorrentSeedingTile({super.key, required this.torrent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  torrent.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Seeded ${formatDurationSeconds(torrent.seedingTime)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
