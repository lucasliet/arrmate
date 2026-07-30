import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/models.dart';
import '../screens/activity/providers/activity_provider.dart';

/// The kind of media a queue item targets.
enum _MediaKind { movie, series }

/// A composite key that uniquely identifies a queued media item by its origin
/// instance and Arr internal id, so the same id on two different servers no
/// longer collides.
class _LookupKey {
  final InstanceType instanceType;
  final String instanceId;
  final _MediaKind kind;
  final int mediaId;

  const _LookupKey({
    required this.instanceType,
    required this.instanceId,
    required this.kind,
    required this.mediaId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LookupKey &&
          runtimeType == other.runtimeType &&
          instanceType == other.instanceType &&
          instanceId == other.instanceId &&
          kind == other.kind &&
          mediaId == other.mediaId;

  @override
  int get hashCode => Object.hash(instanceType, instanceId, kind, mediaId);
}

/// Lookup that exposes the queue status of movie and series identifiers,
/// derived from the aggregated [queueProvider] and scoped by origin instance.
///
/// Identifiers are the Arr internal ids: [QueueItem.movieId] maps to
/// [Movie.guid] and [QueueItem.seriesId] maps to [Series.id]. When multiple
/// queue items reference the same media, the most attention-worthy status
/// wins (failed > warning > paused > downloading > completed).
class QueueMediaLookup {
  final Map<_LookupKey, QueueStatus> _statuses;

  const QueueMediaLookup._(this._statuses);

  static const QueueMediaLookup empty = QueueMediaLookup._({});

  QueueStatus? statusForMovie(
    InstanceType? instanceType,
    String? instanceId,
    int? movieId,
  ) {
    if (instanceType == null || instanceId == null || movieId == null) {
      return null;
    }
    return _statuses[_LookupKey(
      instanceType: instanceType,
      instanceId: instanceId,
      kind: _MediaKind.movie,
      mediaId: movieId,
    )];
  }

  QueueStatus? statusForSeries(
    InstanceType? instanceType,
    String? instanceId,
    int? seriesId,
  ) {
    if (instanceType == null || instanceId == null || seriesId == null) {
      return null;
    }
    return _statuses[_LookupKey(
      instanceType: instanceType,
      instanceId: instanceId,
      kind: _MediaKind.series,
      mediaId: seriesId,
    )];
  }
}

/// Priority ranking for [QueueStatus] when several queue items reference the
/// same media. Lower number = higher attention.
int _statusPriority(QueueStatus status) {
  switch (status) {
    case QueueStatus.failed:
      return 1;
    case QueueStatus.warning:
      return 2;
    case QueueStatus.paused:
      return 3;
    case QueueStatus.delay:
      return 4;
    case QueueStatus.queued:
      return 5;
    case QueueStatus.downloading:
      return 6;
    case QueueStatus.completed:
      return 7;
    case QueueStatus.unknown:
      return 8;
  }
}

final queueMediaLookupProvider = Provider<AsyncValue<QueueMediaLookup>>((ref) {
  final queueAsync = ref.watch(queueProvider);
  return queueAsync.whenData((items) {
    final statuses = <_LookupKey, QueueStatus>{};
    for (final item in items) {
      final instanceType = item.instanceType;
      final instanceId = item.instanceId;
      if (instanceType == null || instanceId == null) continue;
      final status = _effectiveStatus(item);

      final movieId = item.movieId ?? item.movie?.guid;
      if (movieId != null) {
        _accumulate(
          statuses,
          _LookupKey(
            instanceType: instanceType,
            instanceId: instanceId,
            kind: _MediaKind.movie,
            mediaId: movieId,
          ),
          status,
        );
        continue;
      }
      final seriesId = item.seriesId ?? item.series?.id;
      if (seriesId != null) {
        _accumulate(
          statuses,
          _LookupKey(
            instanceType: instanceType,
            instanceId: instanceId,
            kind: _MediaKind.series,
            mediaId: seriesId,
          ),
          status,
        );
      }
    }
    return QueueMediaLookup._(statuses);
  });
});

QueueStatus _effectiveStatus(QueueItem item) {
  if (item.hasError) {
    return QueueStatus.failed;
  }
  if (item.hasWarning) {
    return QueueStatus.warning;
  }
  return item.status;
}

void _accumulate(
  Map<_LookupKey, QueueStatus> statuses,
  _LookupKey key,
  QueueStatus status,
) {
  final existing = statuses[key];
  if (existing == null || _statusPriority(status) < _statusPriority(existing)) {
    statuses[key] = status;
  }
}
