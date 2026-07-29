import 'package:equatable/equatable.dart';

import 'queue.dart';

/// Defines the field used to sort queue items.
enum QueueSortField {
  /// Sorts queue items by their display title.
  title,

  /// Sorts queue items by the date they were added.
  added,
}

/// Describes the filters and ordering applied to the activity queue.
class QueueQuery extends Equatable {
  /// Limits results to a configured instance identifier.
  final String? instanceId;

  /// Limits results to a download protocol.
  final String? protocol;

  /// Limits results to a download client.
  final String? downloadClient;

  /// Limits results to queue items that need attention.
  final bool issuesOnly;

  /// Selects the field used to order results.
  final QueueSortField sortField;

  /// Controls whether results use ascending order.
  final bool ascending;

  /// Creates a queue query.
  const QueueQuery({
    this.instanceId,
    this.protocol,
    this.downloadClient,
    this.issuesOnly = false,
    this.sortField = QueueSortField.added,
    this.ascending = false,
  });

  /// Indicates whether any queue filter is active.
  bool get hasFilters =>
      instanceId != null ||
      protocol != null ||
      downloadClient != null ||
      issuesOnly;

  @override
  List<Object?> get props => [
    instanceId,
    protocol,
    downloadClient,
    issuesOnly,
    sortField,
    ascending,
  ];
}

/// Contains grouped queue items and their unique problem count.
class QueueViewResult extends Equatable {
  /// Queue items after grouping, filtering, and sorting.
  final List<QueueItem> items;

  /// Number of grouped tasks that need attention before filtering.
  final int problemCount;

  /// Creates a queue view result.
  const QueueViewResult({required this.items, required this.problemCount});

  @override
  List<Object?> get props => [items, problemCount];
}

/// Builds the queue representation displayed by the activity screen.
QueueViewResult buildQueueView(Iterable<QueueItem> source, QueueQuery query) {
  final groupedItems = _groupQueueItems(source);
  final problemCount = groupedItems.where((item) => item.hasIssue).length;
  final filteredItems = groupedItems.where(
    (item) => _matchesQuery(item, query),
  );
  final sortedItems = filteredItems.toList()
    ..sort((left, right) => _compareItems(left, right, query));

  return QueueViewResult(items: sortedItems, problemCount: problemCount);
}

List<QueueItem> _groupQueueItems(Iterable<QueueItem> source) {
  final groups = <_QueueTaskKey, List<QueueItem>>{};
  var index = 0;

  for (final item in source) {
    final key = _taskKey(item, index);
    groups.putIfAbsent(key, () => []).add(item);
    index++;
  }

  return groups.values.map(_groupRepresentative).toList(growable: false);
}

QueueItem _groupRepresentative(List<QueueItem> group) {
  final representative = group.firstWhere(
    (item) => item.hasIssue,
    orElse: () => group.first,
  );
  return representative.copyWith(taskGroupCount: group.length);
}

_QueueTaskKey _taskKey(QueueItem item, int index) {
  final instanceId = item.instanceId;
  final origin = instanceId == null
      ? 'unscoped:$index:${item.id}'
      : '${item.instanceType?.name ?? 'unknown'}:$instanceId';

  return (
    origin: origin,
    downloadId: item.downloadId ?? '',
    title: item.title.trim().toLowerCase(),
    mediaScope: item.seasonNumber ?? item.id,
    size: item.size ?? 0,
  );
}

bool _matchesQuery(QueueItem item, QueueQuery query) {
  if (query.instanceId != null && item.instanceId != query.instanceId) {
    return false;
  }
  if (!_matchesText(item.protocol, query.protocol)) return false;
  if (!_matchesText(item.downloadClient, query.downloadClient)) return false;
  return !query.issuesOnly || item.hasIssue;
}

bool _matchesText(String? value, String? filter) {
  if (filter == null) return true;
  return value?.trim().toLowerCase() == filter.trim().toLowerCase();
}

int _compareItems(QueueItem left, QueueItem right, QueueQuery query) {
  final comparison = switch (query.sortField) {
    QueueSortField.title => left.displayTitle.toLowerCase().compareTo(
      right.displayTitle.toLowerCase(),
    ),
    QueueSortField.added => _compareDates(left.added, right.added),
  };
  final directedComparison = query.ascending ? comparison : -comparison;

  if (comparison != 0) {
    if (query.sortField == QueueSortField.added &&
        (left.added == null || right.added == null)) {
      return comparison;
    }
    return directedComparison;
  }

  return _stableIdentity(left).compareTo(_stableIdentity(right));
}

int _compareDates(DateTime? left, DateTime? right) {
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;
  return left.compareTo(right);
}

String _stableIdentity(QueueItem item) {
  return '${item.instanceType?.name}:${item.instanceId}:${item.id}';
}

typedef _QueueTaskKey = ({
  String origin,
  String downloadId,
  String title,
  int mediaScope,
  int size,
});
