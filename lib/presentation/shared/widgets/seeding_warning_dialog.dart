import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
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

/// Requests deletion approval for every detected cross-seed torrent.
///
/// Returns the normalized hashes of torrents explicitly approved for deletion.
Future<Set<String>> resolveCrossSeedApprovals({
  required BuildContext context,
  required List<Torrent> crossSeedCandidates,
}) async {
  final approvedHashes = <String>{};
  final seenHashes = <String>{};

  for (final torrent in crossSeedCandidates) {
    final hash = torrent.hash.toLowerCase();
    if (!seenHashes.add(hash) || !context.mounted) continue;

    final shouldDelete = await showCrossSeedConfirmationDialog(
      context: context,
      torrent: torrent,
    );
    if (shouldDelete == true) approvedHashes.add(hash);
  }

  return approvedHashes;
}

/// Shows the details of a detected cross-seed torrent before deletion.
///
/// Returns `true` only when the user explicitly confirms deletion.
Future<bool?> showCrossSeedConfirmationDialog({
  required BuildContext context,
  required Torrent torrent,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: Text(context.l10n.purgeCrossSeedFoundTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.purgeCrossSeedFoundContent),
              const SizedBox(height: 16),
              CrossSeedTorrentDetails(torrent: torrent),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.purgeKeepTorrent),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.purgeDeleteTorrent),
          ),
        ],
      );
    },
  );
}

/// Shows a confirmation dialog when some torrents being purged have seeded for
/// less than the configured minimum.
///
/// The dialog only governs which torrents are removed from qBittorrent.
/// [footnote] explains what happens regardless of the choice; it defaults to
/// the localized library purge wording, where the catalog and media files are
/// always purged. Returns the user's [SeedingAction], or `null` if the dialog was
/// dismissed.
Future<SeedingAction?> showSeedingWarningDialog({
  required BuildContext context,
  required List<Torrent> belowThreshold,
  required int minimumSeedingDays,
  String? footnote,
}) {
  return showDialog<SeedingAction>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(context.l10n.purgeTorrentsStillSeeding),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.purgeTorrentsBelowMinimum(
                  belowThreshold.length,
                  minimumSeedingDays,
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...belowThreshold.map((t) => TorrentSeedingTile(torrent: t)),
              const SizedBox(height: 12),
              Text(
                footnote ?? context.l10n.purgeTitleRemovedEitherWay,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, SeedingAction.cancel),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton.tonal(
            onPressed: () =>
                Navigator.pop(context, SeedingAction.keepBelowThreshold),
            child: Text(context.l10n.purgeKeepSeeding),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, SeedingAction.deleteAll),
            child: Text(context.l10n.purgeDeleteAll),
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
        title: Text(context.l10n.purgeTorrentStillSeeding),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.purgeTorrentBelowMinimum(minimumSeedingDays),
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
            child: Text(context.l10n.purgeKeepTorrent),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.purgeDeleteAnyway),
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
                  context.l10n.purgeSeededFor(
                    formatDurationSeconds(torrent.seedingTime),
                  ),
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

/// Displays the identifying details of a cross-seed candidate.
class CrossSeedTorrentDetails extends StatelessWidget {
  /// Torrent proposed for cross-seed deletion.
  final Torrent torrent;

  /// Creates a details view for a cross-seed torrent.
  const CrossSeedTorrentDetails({super.key, required this.torrent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final tags = torrent.tags.isEmpty
        ? l10n.purgeNoTags
        : torrent.tags.join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(torrent.name, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _DetailRow(label: l10n.purgeHash, value: torrent.hash),
        _DetailRow(label: l10n.commonSize, value: formatBytes(torrent.size)),
        _DetailRow(label: l10n.purgeSavePath, value: torrent.savePath),
        _DetailRow(label: l10n.commonTags, value: tags),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
