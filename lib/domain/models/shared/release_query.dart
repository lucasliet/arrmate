import 'package:equatable/equatable.dart';
import 'package:arrmate/domain/models/shared/release.dart';

/// Defines the approval state used to filter releases.
enum ReleaseApprovalFilter { all, approved, rejected }

/// Defines the freeleech state used to filter releases.
enum ReleaseFreeleechFilter { all, only, excluded }

/// Defines whether episode releases or season packs are displayed.
enum ReleaseTypeFilter { all, seasonPacks, episodes }

/// Defines the field used to sort releases.
enum ReleaseSortOption {
  releaseWeight,
  qualityWeight,
  customFormatScore,
  seeders,
  age,
  size,
  indexer,
}

/// Holds the complete search, filter and sort configuration for releases.
class ReleaseQuery extends Equatable {
  final String search;
  final Set<String> protocols;
  final Set<String> indexers;
  final Set<String> qualities;
  final Set<String> languages;
  final Set<String> customFormats;
  final ReleaseApprovalFilter approval;
  final ReleaseFreeleechFilter freeleech;
  final ReleaseTypeFilter releaseType;
  final bool originalLanguageOnly;
  final ReleaseSortOption sortOption;
  final bool sortAscending;

  const ReleaseQuery({
    this.search = '',
    this.protocols = const {},
    this.indexers = const {},
    this.qualities = const {},
    this.languages = const {},
    this.customFormats = const {},
    this.approval = ReleaseApprovalFilter.all,
    this.freeleech = ReleaseFreeleechFilter.all,
    this.releaseType = ReleaseTypeFilter.all,
    this.originalLanguageOnly = false,
    this.sortOption = ReleaseSortOption.releaseWeight,
    this.sortAscending = false,
  });

  /// Whether at least one search or filter criterion is active.
  bool get hasActiveFilters =>
      search.trim().isNotEmpty ||
      protocols.isNotEmpty ||
      indexers.isNotEmpty ||
      qualities.isNotEmpty ||
      languages.isNotEmpty ||
      customFormats.isNotEmpty ||
      approval != ReleaseApprovalFilter.all ||
      freeleech != ReleaseFreeleechFilter.all ||
      releaseType != ReleaseTypeFilter.all ||
      originalLanguageOnly;

  /// Creates a copy with selected values replaced.
  ReleaseQuery copyWith({
    String? search,
    Set<String>? protocols,
    Set<String>? indexers,
    Set<String>? qualities,
    Set<String>? languages,
    Set<String>? customFormats,
    ReleaseApprovalFilter? approval,
    ReleaseFreeleechFilter? freeleech,
    ReleaseTypeFilter? releaseType,
    bool? originalLanguageOnly,
    ReleaseSortOption? sortOption,
    bool? sortAscending,
  }) {
    return ReleaseQuery(
      search: search ?? this.search,
      protocols: protocols ?? this.protocols,
      indexers: indexers ?? this.indexers,
      qualities: qualities ?? this.qualities,
      languages: languages ?? this.languages,
      customFormats: customFormats ?? this.customFormats,
      approval: approval ?? this.approval,
      freeleech: freeleech ?? this.freeleech,
      releaseType: releaseType ?? this.releaseType,
      originalLanguageOnly: originalLanguageOnly ?? this.originalLanguageOnly,
      sortOption: sortOption ?? this.sortOption,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  /// Clears search and filters while preserving the current sorting.
  ReleaseQuery clearFilters() {
    return ReleaseQuery(sortOption: sortOption, sortAscending: sortAscending);
  }

  /// Converts this configuration to a persistable JSON map.
  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'protocols': protocols.toList(),
      'indexers': indexers.toList(),
      'qualities': qualities.toList(),
      'languages': languages.toList(),
      'customFormats': customFormats.toList(),
      'approval': approval.name,
      'freeleech': freeleech.name,
      'releaseType': releaseType.name,
      'originalLanguageOnly': originalLanguageOnly,
      'sortOption': sortOption.name,
      'sortAscending': sortAscending,
    };
  }

  /// Creates a release configuration from persisted JSON.
  factory ReleaseQuery.fromJson(Map<String, dynamic> json) {
    return ReleaseQuery(
      search: json['search'] as String? ?? '',
      protocols: _parseSet(json['protocols']),
      indexers: _parseSet(json['indexers']),
      qualities: _parseSet(json['qualities']),
      languages: _parseSet(json['languages']),
      customFormats: _parseSet(json['customFormats']),
      approval: _parseEnum(
        ReleaseApprovalFilter.values,
        json['approval'],
        ReleaseApprovalFilter.all,
      ),
      freeleech: _parseEnum(
        ReleaseFreeleechFilter.values,
        json['freeleech'],
        ReleaseFreeleechFilter.all,
      ),
      releaseType: _parseEnum(
        ReleaseTypeFilter.values,
        json['releaseType'],
        ReleaseTypeFilter.all,
      ),
      originalLanguageOnly: json['originalLanguageOnly'] as bool? ?? false,
      sortOption: _parseEnum(
        ReleaseSortOption.values,
        json['sortOption'],
        ReleaseSortOption.releaseWeight,
      ),
      sortAscending: json['sortAscending'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    search,
    protocols,
    indexers,
    qualities,
    languages,
    customFormats,
    approval,
    freeleech,
    releaseType,
    originalLanguageOnly,
    sortOption,
    sortAscending,
  ];
}

/// Filters and sorts releases according to [query].
List<Release> applyReleaseQuery(
  Iterable<Release> releases,
  ReleaseQuery query, {
  String? originalLanguage,
}) {
  final filtered = releases.where(
    (release) =>
        _matchesRelease(release, query, originalLanguage: originalLanguage),
  );
  final sorted = filtered.toList();
  sorted.sort((first, second) {
    if (first.rejected != second.rejected) {
      return first.rejected ? 1 : -1;
    }

    final comparison = switch (query.sortOption) {
      ReleaseSortOption.releaseWeight => first.releaseWeight.compareTo(
        second.releaseWeight,
      ),
      ReleaseSortOption.qualityWeight => first.qualityWeight.compareTo(
        second.qualityWeight,
      ),
      ReleaseSortOption.customFormatScore => first.customFormatScore.compareTo(
        second.customFormatScore,
      ),
      ReleaseSortOption.seeders => first.seeders.compareTo(second.seeders),
      ReleaseSortOption.age => first.age.compareTo(second.age),
      ReleaseSortOption.size => first.size.compareTo(second.size),
      ReleaseSortOption.indexer => first.indexer.toLowerCase().compareTo(
        second.indexer.toLowerCase(),
      ),
    };
    return query.sortAscending ? comparison : -comparison;
  });
  return sorted;
}

bool _matchesRelease(
  Release release,
  ReleaseQuery query, {
  required String? originalLanguage,
}) {
  final search = query.search.trim().toLowerCase();
  final languageNames = release.languages
      .map((language) => language.name ?? '')
      .where((name) => name.isNotEmpty)
      .toList();
  final customFormatNames = release.customFormats
      .map((format) => format.name)
      .toList();
  final searchableText = [
    release.title,
    release.indexer,
    release.protocol,
    release.quality.quality.name,
    ...languageNames,
    ...customFormatNames,
  ].join(' ').toLowerCase();

  if (search.isNotEmpty && !searchableText.contains(search)) return false;
  if (!_matchesValue(query.protocols, release.protocol)) return false;
  if (!_matchesValue(query.indexers, release.indexer)) return false;
  if (!_matchesValue(query.qualities, release.quality.quality.name)) {
    return false;
  }
  if (!_matchesCollection(query.languages, languageNames)) return false;
  if (!_matchesCollection(query.customFormats, customFormatNames)) {
    return false;
  }
  if (query.approval == ReleaseApprovalFilter.approved && release.rejected) {
    return false;
  }
  if (query.approval == ReleaseApprovalFilter.rejected && !release.rejected) {
    return false;
  }
  if (query.freeleech == ReleaseFreeleechFilter.only && !release.isFreeleech) {
    return false;
  }
  if (query.freeleech == ReleaseFreeleechFilter.excluded &&
      release.isFreeleech) {
    return false;
  }
  if (query.releaseType == ReleaseTypeFilter.seasonPacks &&
      !release.fullSeason) {
    return false;
  }
  if (query.releaseType == ReleaseTypeFilter.episodes && release.fullSeason) {
    return false;
  }
  if (query.originalLanguageOnly && originalLanguage != null) {
    final normalizedOriginalLanguage = originalLanguage.trim().toLowerCase();
    if (normalizedOriginalLanguage.isNotEmpty &&
        !languageNames.any(
          (language) =>
              language.trim().toLowerCase() == normalizedOriginalLanguage,
        )) {
      return false;
    }
  }
  return true;
}

bool _matchesValue(Set<String> selected, String value) {
  if (selected.isEmpty) return true;
  final normalizedValue = value.toLowerCase();
  return selected.any((item) => item.toLowerCase() == normalizedValue);
}

bool _matchesCollection(Set<String> selected, Iterable<String> values) {
  if (selected.isEmpty) return true;
  final normalizedValues = values.map((value) => value.toLowerCase()).toSet();
  return selected.any((item) => normalizedValues.contains(item.toLowerCase()));
}

Set<String> _parseSet(Object? value) {
  if (value is! List) return const {};
  return value.map((item) => item.toString()).toSet();
}

T _parseEnum<T extends Enum>(List<T> values, Object? value, T fallback) {
  for (final item in values) {
    if (item.name == value) return item;
  }
  return fallback;
}
