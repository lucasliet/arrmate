import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/models.dart';
import '../providers/instances_provider.dart';
import '../providers/queue_lookup_provider.dart';

/// A compact badge shown on media cards when the item is currently queued.
///
/// The lookup is scoped by origin instance so two different servers exposing
/// the same internal id no longer cross-report status. When [instanceType]
/// and [instanceId] are omitted, the badge resolves the currently selected
/// instance for the media kind (Radarr for movies, Sonarr for series) so the
/// default movie/series card contexts keep correct scoping without callers
/// having to thread the instance through. The calendar passes the event's
/// instance explicitly since an episode may belong to any Sonarr instance.
class QueueStatusIndicator extends ConsumerWidget {
  final InstanceType? instanceType;
  final String? instanceId;
  final int? movieId;
  final int? seriesId;

  const QueueStatusIndicator({
    super.key,
    this.instanceType,
    this.instanceId,
    this.movieId,
    this.seriesId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookupAsync = ref.watch(queueMediaLookupProvider);
    final lookup = lookupAsync.valueOrNull;
    if (lookup == null) return const SizedBox.shrink();

    final (type, id) = _resolveOrigin(ref);
    final status =
        lookup.statusForMovie(type, id, movieId) ??
        lookup.statusForSeries(type, id, seriesId);
    if (status == null) return const SizedBox.shrink();

    final appearance = _appearanceFor(status);
    return Tooltip(
      message: _labelFor(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: appearance.color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(appearance.icon, size: 12, color: Colors.white),
      ),
    );
  }

  (InstanceType?, String?) _resolveOrigin(WidgetRef ref) {
    if (instanceType != null && instanceId != null) {
      return (instanceType, instanceId);
    }
    if (movieId != null) {
      final instance = ref.watch(currentRadarrInstanceProvider);
      return (instance?.type, instance?.id);
    }
    if (seriesId != null) {
      final instance = ref.watch(currentSonarrInstanceProvider);
      return (instance?.type, instance?.id);
    }
    return (instanceType, instanceId);
  }

  static _QueueStatusAppearance _appearanceFor(QueueStatus status) {
    switch (status) {
      case QueueStatus.failed:
        return const _QueueStatusAppearance(Icons.error, Colors.red);
      case QueueStatus.warning:
        return const _QueueStatusAppearance(Icons.warning, Colors.orange);
      case QueueStatus.paused:
        return const _QueueStatusAppearance(Icons.pause_circle, Colors.grey);
      case QueueStatus.delay:
        return const _QueueStatusAppearance(Icons.schedule, Colors.amber);
      case QueueStatus.queued:
      case QueueStatus.downloading:
        return const _QueueStatusAppearance(Icons.downloading, Colors.blue);
      case QueueStatus.completed:
        return const _QueueStatusAppearance(Icons.check_circle, Colors.green);
      case QueueStatus.unknown:
        return const _QueueStatusAppearance(Icons.help, Colors.blueGrey);
    }
  }

  static String _labelFor(QueueStatus status) {
    switch (status) {
      case QueueStatus.failed:
        return 'Download failed';
      case QueueStatus.warning:
        return 'Download warning';
      case QueueStatus.paused:
        return 'Download paused';
      case QueueStatus.delay:
        return 'Download pending';
      case QueueStatus.queued:
        return 'Queued';
      case QueueStatus.downloading:
        return 'Downloading';
      case QueueStatus.completed:
        return 'Completed';
      case QueueStatus.unknown:
        return 'Status unknown';
    }
  }
}

class _QueueStatusAppearance {
  final IconData icon;
  final Color color;

  const _QueueStatusAppearance(this.icon, this.color);
}
