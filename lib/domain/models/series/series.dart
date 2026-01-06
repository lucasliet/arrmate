import 'package:equatable/equatable.dart';

import '../shared/shared.dart';
import 'season.dart';

/// Represents an episode in a TV series.
class Episode extends Equatable {
  final int id;
  final String? instanceId;
  final int seriesId;
  final int? tvdbId;
  final int seasonNumber;
  final int episodeNumber;
  final String? title;
  final String? overview;
  final DateTime? airDate;
  final DateTime? airDateUtc;
  final int runtime;
  final bool hasFile;
  final bool monitored;
  final int? episodeFileId;
  final MediaFile? episodeFile;
  final Series? series;

  const Episode({
    required this.id,
    this.instanceId,
    required this.seriesId,
    this.tvdbId,
    required this.seasonNumber,
    required this.episodeNumber,
    this.title,
    this.overview,
    this.airDate,
    this.airDateUtc,
    this.runtime = 0,
    this.hasFile = false,
    this.monitored = false,
    this.episodeFileId,
    this.episodeFile,
    this.series,
  });

  /// Formats the episode number as SxxExx.
  String get episodeLabel =>
      'S${seasonNumber.toString().padLeft(2, '0')}E${episodeNumber.toString().padLeft(2, '0')}';

  /// Returns a full label including episode number and title.
  String get fullLabel => '$episodeLabel - ${title ?? 'TBA'}';

  /// Checks if the episode file is present.
  bool get isDownloaded => hasFile || episodeFile != null;

  /// Checks if the episode has already aired.
  bool get isAired {
    if (airDateUtc == null) return false;
    return airDateUtc!.isBefore(DateTime.now());
  }

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as int,
      seriesId: json['seriesId'] as int,
      tvdbId: json['tvdbId'] as int?,
      seasonNumber: json['seasonNumber'] as int,
      episodeNumber: json['episodeNumber'] as int,
      title: json['title'] as String?,
      overview: json['overview'] as String?,
      airDate: json['airDate'] != null
          ? DateTime.tryParse(json['airDate'] as String)
          : null,
      airDateUtc: json['airDateUtc'] != null
          ? DateTime.parse(json['airDateUtc'] as String)
          : null,
      runtime: json['runtime'] as int? ?? 0,
      hasFile: json['hasFile'] as bool? ?? false,
      monitored: json['monitored'] as bool? ?? false,
      episodeFileId: json['episodeFileId'] as int?,
      episodeFile: json['episodeFile'] != null
          ? MediaFile.fromJson(json['episodeFile'] as Map<String, dynamic>)
          : null,
      series: json['series'] != null
          ? Series.fromJson(json['series'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seriesId': seriesId,
      if (tvdbId != null) 'tvdbId': tvdbId,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      if (title != null) 'title': title,
      if (overview != null) 'overview': overview,
      if (airDate != null) 'airDate': airDate!.toIso8601String(),
      if (airDateUtc != null) 'airDateUtc': airDateUtc!.toIso8601String(),
      'runtime': runtime,
      'hasFile': hasFile,
      'monitored': monitored,
      if (episodeFileId != null) 'episodeFileId': episodeFileId,
      if (episodeFile != null) 'episodeFile': episodeFile!.toJson(),
    };
  }

  Episode copyWith({
    int? id,
    String? instanceId,
    int? seriesId,
    int? tvdbId,
    int? seasonNumber,
    int? episodeNumber,
    String? title,
    String? overview,
    DateTime? airDate,
    DateTime? airDateUtc,
    int? runtime,
    bool? hasFile,
    bool? monitored,
    int? episodeFileId,
    MediaFile? episodeFile,
    Series? series,
  }) {
    return Episode(
      id: id ?? this.id,
      instanceId: instanceId ?? this.instanceId,
      seriesId: seriesId ?? this.seriesId,
      tvdbId: tvdbId ?? this.tvdbId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      airDate: airDate ?? this.airDate,
      airDateUtc: airDateUtc ?? this.airDateUtc,
      runtime: runtime ?? this.runtime,
      hasFile: hasFile ?? this.hasFile,
      monitored: monitored ?? this.monitored,
      episodeFileId: episodeFileId ?? this.episodeFileId,
      episodeFile: episodeFile ?? this.episodeFile,
      series: series ?? this.series,
    );
  }

  @override
  List<Object?> get props => [
    id,
    instanceId,
    seriesId,
    tvdbId,
    seasonNumber,
    episodeNumber,
    title,
    overview,
    airDate,
    airDateUtc,
    runtime,
    hasFile,
    monitored,
    episodeFileId,
    episodeFile,
  ];
}

/// Represents a TV Series in Sonarr.
class Series extends Equatable {
  /// Sonarr internal ID.
  final int? guid;
  final String? instanceId;
  final String title;
  final String? titleSlug;
  final String sortTitle;
  final int tvdbId;
  final int? tvRageId;
  final int? tvMazeId;
  final String? imdbId;
  final int? tmdbId;
  final SeriesStatus status;
  final SeriesType seriesType;
  final String? path;
  final String? folder;
  final int? qualityProfileId;
  final String? rootFolderPath;
  final String? certification;
  final int year;
  final int runtime;
  final String? airTime;
  final bool ended;
  final bool seasonFolder;
  final bool useSceneNumbering;
  final DateTime added;
  final DateTime? firstAired;
  final DateTime? lastAired;
  final DateTime? nextAiring;
  final DateTime? previousAiring;
  final bool monitored;
  final SeriesMonitorNewItems? monitorNewItems;
  final String? overview;
  final String? network;
  final MediaLanguage? originalLanguage;
  final List<MediaAlternateTitle>? alternateTitles;
  final List<Season> seasons;
  final List<int> tags;
  final List<String> genres;
  final List<MediaImage> images;
  final SeriesRatings? ratings;
  final SeriesStatistics? statistics;
  final SeriesAddOptions? addOptions;

  const Series({
    this.guid,
    this.instanceId,
    required this.title,
    this.titleSlug,
    required this.sortTitle,
    required this.tvdbId,
    this.tvRageId,
    this.tvMazeId,
    this.imdbId,
    this.tmdbId,
    required this.status,
    required this.seriesType,
    this.path,
    this.folder,
    this.qualityProfileId,
    this.rootFolderPath,
    this.certification,
    required this.year,
    this.runtime = 0,
    this.airTime,
    this.ended = false,
    this.seasonFolder = true,
    this.useSceneNumbering = false,
    required this.added,
    this.firstAired,
    this.lastAired,
    this.nextAiring,
    this.previousAiring,
    this.monitored = false,
    this.monitorNewItems,
    this.overview,
    this.network,
    this.originalLanguage,
    this.alternateTitles,
    this.seasons = const [],
    this.tags = const [],
    this.genres = const [],
    this.images = const [],
    this.ratings,
    this.statistics,
    this.addOptions,
  });

  /// Returns the internal ID, using [guid] or falling back to [tvdbId].
  int get id => guid ?? (tvdbId + 100000);

  /// Checks if the series exists in the database.
  bool get exists => guid != null;

  /// Checks if all episodes are downloaded.
  bool get isDownloaded => (statistics?.percentOfEpisodes ?? 0) >= 100;

  /// Checks if the series is upcoming or waiting for episodes.
  bool get isWaiting {
    if (firstAired != null && firstAired!.isAfter(DateTime.now())) return true;
    return status == SeriesStatus.upcoming || year == 0 || seasons.isEmpty;
  }

  /// Returns the year as a string or 'TBA'.
  String get yearLabel => year > 0 ? '$year' : 'TBA';

  /// Retrieves the URL of the first poster image.
  String? get remotePoster {
    final poster = images.where((i) => i.isPoster).firstOrNull;
    return poster?.remoteURL;
  }

  int get seasonCount => seasons.where((s) => s.seasonNumber != 0).length;
  int get episodeCount => statistics?.episodeCount ?? 0;
  int get episodeFileCount => statistics?.episodeFileCount ?? 0;
  double get percentOfEpisodes => statistics?.percentOfEpisodes ?? 0;

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      guid: json['id'] as int?,
      title: json['title'] as String,
      titleSlug: json['titleSlug'] as String?,
      sortTitle: json['sortTitle'] as String? ?? json['title'] as String,
      tvdbId: json['tvdbId'] as int,
      tvRageId: json['tvRageId'] as int?,
      tvMazeId: json['tvMazeId'] as int?,
      imdbId: json['imdbId'] as String?,
      tmdbId: json['tmdbId'] as int?,
      status: SeriesStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SeriesStatus.continuing,
      ),
      seriesType: SeriesType.values.firstWhere(
        (e) => e.name == json['seriesType'],
        orElse: () => SeriesType.standard,
      ),
      path: json['path'] as String?,
      folder: json['folder'] as String?,
      qualityProfileId: json['qualityProfileId'] as int?,
      rootFolderPath: json['rootFolderPath'] as String?,
      certification: json['certification'] as String?,
      year: json['year'] as int? ?? 0,
      runtime: json['runtime'] as int? ?? 0,
      airTime: json['airTime'] as String?,
      ended: json['ended'] as bool? ?? false,
      seasonFolder: json['seasonFolder'] as bool? ?? true,
      useSceneNumbering: json['useSceneNumbering'] as bool? ?? false,
      added: DateTime.parse(json['added'] as String),
      firstAired: json['firstAired'] != null
          ? DateTime.tryParse(json['firstAired'] as String)
          : null,
      lastAired: json['lastAired'] != null
          ? DateTime.tryParse(json['lastAired'] as String)
          : null,
      nextAiring: json['nextAiring'] != null
          ? DateTime.tryParse(json['nextAiring'] as String)
          : null,
      previousAiring: json['previousAiring'] != null
          ? DateTime.tryParse(json['previousAiring'] as String)
          : null,
      monitored: json['monitored'] as bool? ?? false,
      monitorNewItems: json['monitorNewItems'] != null
          ? SeriesMonitorNewItems.values.firstWhere(
              (e) => e.name == json['monitorNewItems'],
              orElse: () => SeriesMonitorNewItems.none,
            )
          : null,
      overview: json['overview'] as String?,
      network: json['network'] as String?,
      originalLanguage: json['originalLanguage'] != null
          ? MediaLanguage.fromJson(
              json['originalLanguage'] as Map<String, dynamic>,
            )
          : null,
      alternateTitles: (json['alternateTitles'] as List<dynamic>?)
          ?.map((e) => MediaAlternateTitle.fromJson(e as Map<String, dynamic>))
          .toList(),
      seasons:
          (json['seasons'] as List<dynamic>?)
              ?.map((e) => Season.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => MediaImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ratings: json['ratings'] != null
          ? SeriesRatings.fromJson(json['ratings'] as Map<String, dynamic>)
          : null,
      statistics: json['statistics'] != null
          ? SeriesStatistics.fromJson(
              json['statistics'] as Map<String, dynamic>,
            )
          : null,
      addOptions: json['addOptions'] != null
          ? SeriesAddOptions.fromJson(
              json['addOptions'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (guid != null) 'id': guid,
      'title': title,
      if (titleSlug != null) 'titleSlug': titleSlug,
      'sortTitle': sortTitle,
      'tvdbId': tvdbId,
      if (tvRageId != null) 'tvRageId': tvRageId,
      if (tvMazeId != null) 'tvMazeId': tvMazeId,
      if (imdbId != null) 'imdbId': imdbId,
      if (tmdbId != null) 'tmdbId': tmdbId,
      'status': status.name,
      'seriesType': seriesType.name,
      if (path != null) 'path': path,
      if (folder != null) 'folder': folder,
      if (qualityProfileId != null) 'qualityProfileId': qualityProfileId,
      if (rootFolderPath != null) 'rootFolderPath': rootFolderPath,
      if (certification != null) 'certification': certification,
      'year': year,
      'runtime': runtime,
      if (airTime != null) 'airTime': airTime,
      'ended': ended,
      'seasonFolder': seasonFolder,
      'useSceneNumbering': useSceneNumbering,
      'added': added.toIso8601String(),
      if (firstAired != null) 'firstAired': firstAired!.toIso8601String(),
      if (lastAired != null) 'lastAired': lastAired!.toIso8601String(),
      if (nextAiring != null) 'nextAiring': nextAiring!.toIso8601String(),
      if (previousAiring != null)
        'previousAiring': previousAiring!.toIso8601String(),
      'monitored': monitored,
      if (monitorNewItems != null) 'monitorNewItems': monitorNewItems!.name,
      if (overview != null) 'overview': overview,
      if (network != null) 'network': network,
      if (originalLanguage != null)
        'originalLanguage': originalLanguage!.toJson(),
      if (alternateTitles != null)
        'alternateTitles': alternateTitles!.map((e) => e.toJson()).toList(),
      'seasons': seasons.map((e) => e.toJson()).toList(),
      'tags': tags,
      'genres': genres,
      'images': images.map((e) => e.toJson()).toList(),
      if (ratings != null) 'ratings': ratings!.toJson(),
      if (statistics != null) 'statistics': statistics!.toJson(),
      if (addOptions != null) 'addOptions': addOptions!.toJson(),
      'languageProfileId': 1,
    };
  }

  Series copyWith({
    int? guid,
    String? instanceId,
    String? title,
    String? titleSlug,
    String? sortTitle,
    int? tvdbId,
    int? tvRageId,
    int? tvMazeId,
    String? imdbId,
    int? tmdbId,
    SeriesStatus? status,
    SeriesType? seriesType,
    String? path,
    String? folder,
    int? qualityProfileId,
    String? rootFolderPath,
    String? certification,
    int? year,
    int? runtime,
    String? airTime,
    bool? ended,
    bool? seasonFolder,
    bool? useSceneNumbering,
    DateTime? added,
    DateTime? firstAired,
    DateTime? lastAired,
    DateTime? nextAiring,
    DateTime? previousAiring,
    bool? monitored,
    SeriesMonitorNewItems? monitorNewItems,
    String? overview,
    String? network,
    MediaLanguage? originalLanguage,
    List<MediaAlternateTitle>? alternateTitles,
    List<Season>? seasons,
    List<int>? tags,
    List<String>? genres,
    List<MediaImage>? images,
    SeriesRatings? ratings,
    SeriesStatistics? statistics,
    SeriesAddOptions? addOptions,
  }) {
    return Series(
      guid: guid ?? this.guid,
      instanceId: instanceId ?? this.instanceId,
      title: title ?? this.title,
      titleSlug: titleSlug ?? this.titleSlug,
      sortTitle: sortTitle ?? this.sortTitle,
      tvdbId: tvdbId ?? this.tvdbId,
      tvRageId: tvRageId ?? this.tvRageId,
      tvMazeId: tvMazeId ?? this.tvMazeId,
      imdbId: imdbId ?? this.imdbId,
      tmdbId: tmdbId ?? this.tmdbId,
      status: status ?? this.status,
      seriesType: seriesType ?? this.seriesType,
      path: path ?? this.path,
      folder: folder ?? this.folder,
      qualityProfileId: qualityProfileId ?? this.qualityProfileId,
      rootFolderPath: rootFolderPath ?? this.rootFolderPath,
      certification: certification ?? this.certification,
      year: year ?? this.year,
      runtime: runtime ?? this.runtime,
      airTime: airTime ?? this.airTime,
      ended: ended ?? this.ended,
      seasonFolder: seasonFolder ?? this.seasonFolder,
      useSceneNumbering: useSceneNumbering ?? this.useSceneNumbering,
      added: added ?? this.added,
      firstAired: firstAired ?? this.firstAired,
      lastAired: lastAired ?? this.lastAired,
      nextAiring: nextAiring ?? this.nextAiring,
      previousAiring: previousAiring ?? this.previousAiring,
      monitored: monitored ?? this.monitored,
      monitorNewItems: monitorNewItems ?? this.monitorNewItems,
      overview: overview ?? this.overview,
      network: network ?? this.network,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      alternateTitles: alternateTitles ?? this.alternateTitles,
      seasons: seasons ?? this.seasons,
      tags: tags ?? this.tags,
      genres: genres ?? this.genres,
      images: images ?? this.images,
      ratings: ratings ?? this.ratings,
      statistics: statistics ?? this.statistics,
      addOptions: addOptions ?? this.addOptions,
    );
  }

  @override
  List<Object?> get props => [
    guid,
    instanceId,
    title,
    titleSlug,
    sortTitle,
    tvdbId,
    tvRageId,
    tvMazeId,
    imdbId,
    tmdbId,
    status,
    seriesType,
    path,
    folder,
    qualityProfileId,
    rootFolderPath,
    certification,
    year,
    runtime,
    airTime,
    ended,
    seasonFolder,
    useSceneNumbering,
    added,
    firstAired,
    lastAired,
    nextAiring,
    previousAiring,
    monitored,
    monitorNewItems,
    overview,
    network,
    originalLanguage,
    alternateTitles,
    seasons,
    tags,
    genres,
    images,
    ratings,
    statistics,
    addOptions,
  ];
}

/// Defines the status of a series.
enum SeriesStatus {
  continuing,
  ended,
  upcoming,
  deleted;

  String get label {
    switch (this) {
      case SeriesStatus.continuing:
        return 'Continuing';
      case SeriesStatus.ended:
        return 'Ended';
      case SeriesStatus.upcoming:
        return 'Upcoming';
      case SeriesStatus.deleted:
        return 'Deleted';
    }
  }
}

/// Defines the type of series (Standard, Daily, Anime).
enum SeriesType {
  standard,
  daily,
  anime;

  String get label {
    switch (this) {
      case SeriesType.standard:
        return 'Standard';
      case SeriesType.daily:
        return 'Daily';
      case SeriesType.anime:
        return 'Anime';
    }
  }
}

/// Options for monitoring new items.
enum SeriesMonitorNewItems { all, none }

/// Defines the monitoring strategy for a series.
enum SeriesMonitorType {
  unknown,
  all,
  future,
  missing,
  existing,
  firstSeason,
  lastSeason,
  pilot,
  recent,
  monitorSpecials,
  unmonitorSpecials,
  none,
  skip;

  String get label {
    switch (this) {
      case SeriesMonitorType.unknown:
        return 'Unknown';
      case SeriesMonitorType.all:
        return 'All Episodes';
      case SeriesMonitorType.future:
        return 'Future Episodes';
      case SeriesMonitorType.missing:
        return 'Missing Episodes';
      case SeriesMonitorType.existing:
        return 'Existing Episodes';
      case SeriesMonitorType.recent:
        return 'Recent Episodes';
      case SeriesMonitorType.pilot:
        return 'Pilot Episode';
      case SeriesMonitorType.firstSeason:
        return 'First Season';
      case SeriesMonitorType.lastSeason:
        return 'Last Season';
      case SeriesMonitorType.monitorSpecials:
        return 'Monitor Specials';
      case SeriesMonitorType.unmonitorSpecials:
        return 'Unmonitor Specials';
      case SeriesMonitorType.none:
        return 'None';
      case SeriesMonitorType.skip:
        return '';
    }
  }
}

/// Represents series ratings.
class SeriesRatings extends Equatable {
  final int votes;
  final double value;

  const SeriesRatings({required this.votes, required this.value});

  factory SeriesRatings.fromJson(Map<String, dynamic> json) {
    return SeriesRatings(
      votes: json['votes'] as int? ?? 0,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'votes': votes, 'value': value};
  }

  @override
  List<Object?> get props => [votes, value];
}

/// Contains statistics about a series.
class SeriesStatistics extends Equatable {
  final int sizeOnDisk;
  final int seasonCount;
  final int episodeCount;
  final int episodeFileCount;
  final int totalEpisodeCount;
  final double percentOfEpisodes;

  const SeriesStatistics({
    required this.sizeOnDisk,
    required this.seasonCount,
    required this.episodeCount,
    required this.episodeFileCount,
    required this.totalEpisodeCount,
    required this.percentOfEpisodes,
  });

  factory SeriesStatistics.fromJson(Map<String, dynamic> json) {
    return SeriesStatistics(
      sizeOnDisk: json['sizeOnDisk'] as int? ?? 0,
      seasonCount: json['seasonCount'] as int? ?? 0,
      episodeCount: json['episodeCount'] as int? ?? 0,
      episodeFileCount: json['episodeFileCount'] as int? ?? 0,
      totalEpisodeCount: json['totalEpisodeCount'] as int? ?? 0,
      percentOfEpisodes: (json['percentOfEpisodes'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sizeOnDisk': sizeOnDisk,
      'seasonCount': seasonCount,
      'episodeCount': episodeCount,
      'episodeFileCount': episodeFileCount,
      'totalEpisodeCount': totalEpisodeCount,
      'percentOfEpisodes': percentOfEpisodes,
    };
  }

  @override
  List<Object?> get props => [
    sizeOnDisk,
    seasonCount,
    episodeCount,
    episodeFileCount,
    totalEpisodeCount,
    percentOfEpisodes,
  ];
}

/// Options used when adding a new series.
class SeriesAddOptions extends Equatable {
  final SeriesMonitorType monitor;

  const SeriesAddOptions({required this.monitor});

  factory SeriesAddOptions.fromJson(Map<String, dynamic> json) {
    return SeriesAddOptions(
      monitor: SeriesMonitorType.values.firstWhere(
        (e) => e.name == json['monitor'],
        orElse: () => SeriesMonitorType.all,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'monitor': monitor.name};
  }

  @override
  List<Object?> get props => [monitor];
}
