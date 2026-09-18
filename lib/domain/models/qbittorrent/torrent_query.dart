import 'package:equatable/equatable.dart';

import 'torrent.dart';
import 'torrent_link.dart';
import 'torrent_status.dart';

/// Defines the download status used to filter torrents.
enum TorrentStatusFilter {
  all,
  downloading,
  seeding,
  paused,
  error;

  /// Human-readable label shown in the filter sheet.
  String get label {
    return switch (this) {
      TorrentStatusFilter.all => 'All',
      TorrentStatusFilter.downloading => 'Downloading',
      TorrentStatusFilter.seeding => 'Seeding',
      TorrentStatusFilter.paused => 'Paused',
      TorrentStatusFilter.error => 'Error',
    };
  }
}

/// Defines the library relation used to filter torrents.
enum TorrentLinkFilter {
  all,
  orphan,
  fileMissing,
  linked,
  external;

  /// Human-readable label shown in the filter sheet.
  String get label {
    final resolvedStatus = status;
    if (resolvedStatus == null) return 'All';
    return resolvedStatus.label;
  }

  /// The link status this filter matches, or null when no filter is applied.
  TorrentLinkStatus? get status {
    return switch (this) {
      TorrentLinkFilter.all => null,
      TorrentLinkFilter.orphan => TorrentLinkStatus.orphan,
      TorrentLinkFilter.fileMissing => TorrentLinkStatus.fileMissing,
      TorrentLinkFilter.linked => TorrentLinkStatus.linked,
      TorrentLinkFilter.external => TorrentLinkStatus.external,
    };
  }
}

/// Defines the field used to sort torrents.
enum TorrentSortOption {
  activity,
  addedDate,
  progress,
  size,
  downloadSpeed,
  ratio,
  name;

  /// Human-readable label shown in the sort menu.
  String get label {
    return switch (this) {
      TorrentSortOption.activity => 'Activity',
      TorrentSortOption.addedDate => 'Added date',
      TorrentSortOption.progress => 'Progress',
      TorrentSortOption.size => 'Size',
      TorrentSortOption.downloadSpeed => 'Download speed',
      TorrentSortOption.ratio => 'Ratio',
      TorrentSortOption.name => 'Name',
    };
  }
}

/// Holds the complete search, filter and sort configuration for torrents.
class TorrentQuery extends Equatable {
  final String search;
  final TorrentStatusFilter status;
  final TorrentLinkFilter linkFilter;
  final TorrentSortOption sortOption;
  final bool sortAscending;

  const TorrentQuery({
    this.search = '',
    this.status = TorrentStatusFilter.all,
    this.linkFilter = TorrentLinkFilter.all,
    this.sortOption = TorrentSortOption.activity,
    this.sortAscending = false,
  });

  /// Whether at least one search or filter criterion is active.
  bool get hasActiveFilters =>
      search.trim().isNotEmpty ||
      status != TorrentStatusFilter.all ||
      linkFilter != TorrentLinkFilter.all;

  /// Creates a copy with selected values replaced.
  TorrentQuery copyWith({
    String? search,
    TorrentStatusFilter? status,
    TorrentLinkFilter? linkFilter,
    TorrentSortOption? sortOption,
    bool? sortAscending,
  }) {
    return TorrentQuery(
      search: search ?? this.search,
      status: status ?? this.status,
      linkFilter: linkFilter ?? this.linkFilter,
      sortOption: sortOption ?? this.sortOption,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  /// Clears search and filters while preserving the current sorting.
  TorrentQuery clearFilters() {
    return TorrentQuery(sortOption: sortOption, sortAscending: sortAscending);
  }

  /// Converts this configuration to a persistable JSON map.
  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'status': status.name,
      'linkFilter': linkFilter.name,
      'sortOption': sortOption.name,
      'sortAscending': sortAscending,
    };
  }

  /// Creates a torrent configuration from persisted JSON.
  factory TorrentQuery.fromJson(Map<String, dynamic> json) {
    return TorrentQuery(
      search: json['search'] as String? ?? '',
      status: _parseEnum(
        TorrentStatusFilter.values,
        json['status'],
        TorrentStatusFilter.all,
      ),
      linkFilter: _parseEnum(
        TorrentLinkFilter.values,
        json['linkFilter'],
        TorrentLinkFilter.all,
      ),
      sortOption: _parseEnum(
        TorrentSortOption.values,
        json['sortOption'],
        TorrentSortOption.activity,
      ),
      sortAscending: json['sortAscending'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    search,
    status,
    linkFilter,
    sortOption,
    sortAscending,
  ];
}

/// Filters and sorts torrents according to [query].
///
/// When [linkResolver] is null the library filter is skipped, mirroring the
/// behaviour of a list without Radarr/Sonarr instances, where a leftover
/// selection must not hide every torrent.
List<Torrent> applyTorrentQuery(
  Iterable<Torrent> torrents,
  TorrentQuery query, {
  TorrentLinkStatus? Function(Torrent torrent)? linkResolver,
}) {
  final filtered = torrents.where(
    (torrent) => _matchesTorrent(torrent, query, linkResolver: linkResolver),
  );
  final sorted = filtered.toList();
  sorted.sort((first, second) {
    final comparison = _compareTorrents(first, second, query.sortOption);
    final directed = query.sortAscending ? comparison : -comparison;
    if (directed != 0) return directed;
    return first.name.toLowerCase().compareTo(second.name.toLowerCase());
  });
  return sorted;
}

bool _matchesTorrent(
  Torrent torrent,
  TorrentQuery query, {
  required TorrentLinkStatus? Function(Torrent torrent)? linkResolver,
}) {
  if (!_matchesStatus(torrent, query.status)) return false;
  final expectedLinkStatus = query.linkFilter.status;
  if (expectedLinkStatus != null && linkResolver != null) {
    if (linkResolver(torrent) != expectedLinkStatus) return false;
  }
  final search = query.search.trim().toLowerCase();
  if (search.isNotEmpty && !torrent.name.toLowerCase().contains(search)) {
    return false;
  }
  return true;
}

bool _matchesStatus(Torrent torrent, TorrentStatusFilter filter) {
  return switch (filter) {
    TorrentStatusFilter.all => true,
    TorrentStatusFilter.downloading =>
      torrent.status.isActive && !torrent.status.isPaused,
    TorrentStatusFilter.seeding =>
      torrent.status == TorrentStatus.uploading ||
          torrent.status == TorrentStatus.stalledUP,
    TorrentStatusFilter.paused => torrent.status.isPaused,
    TorrentStatusFilter.error => torrent.status.hasError,
  };
}

int _compareTorrents(Torrent first, Torrent second, TorrentSortOption option) {
  return switch (option) {
    TorrentSortOption.activity => _activityRank(
      first,
    ).compareTo(_activityRank(second)),
    TorrentSortOption.addedDate => first.addedOn.compareTo(second.addedOn),
    TorrentSortOption.progress => first.progress.compareTo(second.progress),
    TorrentSortOption.size => first.size.compareTo(second.size),
    TorrentSortOption.downloadSpeed => first.dlspeed.compareTo(second.dlspeed),
    TorrentSortOption.ratio => first.ratio.compareTo(second.ratio),
    TorrentSortOption.name => first.name.toLowerCase().compareTo(
      second.name.toLowerCase(),
    ),
  };
}

int _activityRank(Torrent torrent) {
  return torrent.status.isActive && !torrent.status.isPaused ? 1 : 0;
}

T _parseEnum<T extends Enum>(List<T> values, Object? value, T fallback) {
  for (final item in values) {
    if (item.name == value) return item;
  }
  return fallback;
}
