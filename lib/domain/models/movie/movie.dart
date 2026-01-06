import 'package:equatable/equatable.dart';

import '../shared/shared.dart';

/// Defines the release status of a movie.
enum MovieStatus {
  tba,
  announced,
  inCinemas,
  released,
  deleted;

  String get label {
    switch (this) {
      case MovieStatus.tba:
        return 'Unannounced';
      case MovieStatus.announced:
        return 'Announced';
      case MovieStatus.inCinemas:
        return 'In Cinemas';
      case MovieStatus.released:
        return 'Released';
      case MovieStatus.deleted:
        return 'Deleted';
    }
  }
}

/// Represents a rating value and vote count.
class MovieRating extends Equatable {
  final int votes;
  final double value;

  const MovieRating({required this.votes, required this.value});

  factory MovieRating.fromJson(Map<String, dynamic> json) {
    return MovieRating(
      votes: json['votes'] as int? ?? 0,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [votes, value];
}

/// Aggregates ratings from various sources.
class MovieRatings extends Equatable {
  final MovieRating? imdb;
  final MovieRating? tmdb;
  final MovieRating? metacritic;
  final MovieRating? rottenTomatoes;

  const MovieRatings({
    this.imdb,
    this.tmdb,
    this.metacritic,
    this.rottenTomatoes,
  });

  factory MovieRatings.fromJson(Map<String, dynamic> json) {
    return MovieRatings(
      imdb: json['imdb'] != null
          ? MovieRating.fromJson(json['imdb'] as Map<String, dynamic>)
          : null,
      tmdb: json['tmdb'] != null
          ? MovieRating.fromJson(json['tmdb'] as Map<String, dynamic>)
          : null,
      metacritic: json['metacritic'] != null
          ? MovieRating.fromJson(json['metacritic'] as Map<String, dynamic>)
          : null,
      rottenTomatoes: json['rottenTomatoes'] != null
          ? MovieRating.fromJson(json['rottenTomatoes'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [imdb, tmdb, metacritic, rottenTomatoes];
}

/// Represents a Movie entity in Radarr.
class Movie extends Equatable {
  /// Radarr internal ID.
  final int? guid;
  final String? instanceId;
  final int tmdbId;
  final String? imdbId;
  final String title;
  final String sortTitle;
  final String? studio;
  final int year;

  /// Runtime in minutes.
  final int runtime;
  final String? overview;
  final String? certification;
  final String? youTubeTrailerId;
  final MediaLanguage? originalLanguage;
  final List<MediaAlternateTitle> alternateTitles;
  final List<String> genres;
  final MovieRatings? ratings;
  final double? popularity;
  final MovieStatus status;

  /// Whether the movie is considered available for download.
  final bool isAvailable;
  final MovieStatus minimumAvailability;

  /// Whether the movie is monitored by Radarr.
  final bool monitored;
  final int qualityProfileId;
  final int? sizeOnDisk;
  final bool? hasFile;
  final String? path;
  final String? relativePath;
  final String? folderName;
  final String? rootFolderPath;
  final DateTime added;
  final DateTime? inCinemas;
  final DateTime? physicalRelease;
  final DateTime? digitalRelease;
  final List<int> tags;
  final List<MediaImage> images;
  final MediaFile? movieFile;

  const Movie({
    this.guid,
    this.instanceId,
    required this.tmdbId,
    this.imdbId,
    required this.title,
    required this.sortTitle,
    this.studio,
    required this.year,
    required this.runtime,
    this.overview,
    this.certification,
    this.youTubeTrailerId,
    this.originalLanguage,
    this.alternateTitles = const [],
    this.genres = const [],
    this.ratings,
    this.popularity,
    required this.status,
    required this.isAvailable,
    required this.minimumAvailability,
    required this.monitored,
    required this.qualityProfileId,
    this.sizeOnDisk,
    this.hasFile,
    this.path,
    this.relativePath,
    this.folderName,
    this.rootFolderPath,
    required this.added,
    this.inCinemas,
    this.physicalRelease,
    this.digitalRelease,
    this.tags = const [],
    this.images = const [],
    this.movieFile,
  });

  /// Returns the internal ID, using [guid] or falling back to [tmdbId].
  int get id => guid ?? (tmdbId + 100000);

  /// Checks if the movie exists in the database.
  bool get exists => guid != null;

  /// Checks if a movie file is present.
  bool get isDownloaded => movieFile != null;

  /// Checks if the movie is waiting for release.
  bool get isWaiting {
    switch (status) {
      case MovieStatus.tba:
      case MovieStatus.announced:
        return true;
      case MovieStatus.inCinemas:
        return minimumAvailability == MovieStatus.released;
      case MovieStatus.released:
      case MovieStatus.deleted:
        return false;
    }
  }

  /// Computes a label for the current movie state.
  String get stateLabel {
    if (isDownloaded) return 'Downloaded';
    if (isWaiting) {
      if (status == MovieStatus.tba || status == MovieStatus.announced) {
        return 'Unreleased';
      }
      return 'Waiting';
    }
    if (monitored && isAvailable) return 'Missing';
    return 'Unwanted';
  }

  /// Returns the year as a string or 'TBA'.
  String get yearLabel => year > 0 ? '$year' : 'TBA';

  /// Retrieves the URL of the first poster image.
  String? get remotePoster {
    final poster = images.where((i) => i.isPoster).firstOrNull;
    return poster?.remoteURL;
  }

  /// Calculates a weighted rating score.
  double get ratingScore {
    final imdbVal = ratings?.imdb?.value;
    final rtVal = ratings?.rottenTomatoes?.value;

    if (imdbVal != null && rtVal != null) {
      return (imdbVal + (rtVal / 10)) / 2;
    }
    if (imdbVal != null) return imdbVal;
    if (rtVal != null) return rtVal / 10;
    return 0;
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      guid: json['id'] as int?,
      tmdbId: json['tmdbId'] as int,
      imdbId: json['imdbId'] as String?,
      title: json['title'] as String,
      sortTitle: json['sortTitle'] as String? ?? json['title'] as String,
      studio: json['studio'] as String?,
      year: json['year'] as int? ?? 0,
      runtime: json['runtime'] as int? ?? 0,
      overview: json['overview'] as String?,
      certification: json['certification'] as String?,
      youTubeTrailerId: json['youTubeTrailerId'] as String?,
      originalLanguage: json['originalLanguage'] != null
          ? MediaLanguage.fromJson(
              json['originalLanguage'] as Map<String, dynamic>,
            )
          : null,
      alternateTitles:
          (json['alternateTitles'] as List<dynamic>?)
              ?.map(
                (e) => MediaAlternateTitle.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      ratings: json['ratings'] != null
          ? MovieRatings.fromJson(json['ratings'] as Map<String, dynamic>)
          : null,
      popularity: (json['popularity'] as num?)?.toDouble(),
      status: MovieStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MovieStatus.released,
      ),
      isAvailable: json['isAvailable'] as bool? ?? false,
      minimumAvailability: MovieStatus.values.firstWhere(
        (e) => e.name == json['minimumAvailability'],
        orElse: () => MovieStatus.released,
      ),
      monitored: json['monitored'] as bool? ?? false,
      qualityProfileId: json['qualityProfileId'] as int? ?? 0,
      sizeOnDisk: json['sizeOnDisk'] as int?,
      hasFile: json['hasFile'] as bool?,
      path: json['path'] as String?,
      folderName: json['folderName'] as String?,
      rootFolderPath: json['rootFolderPath'] as String?,
      added: DateTime.parse(json['added'] as String),
      inCinemas: json['inCinemas'] != null
          ? DateTime.parse(json['inCinemas'] as String)
          : null,
      physicalRelease: json['physicalRelease'] != null
          ? DateTime.parse(json['physicalRelease'] as String)
          : null,
      digitalRelease: json['digitalRelease'] != null
          ? DateTime.parse(json['digitalRelease'] as String)
          : null,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => MediaImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      movieFile: json['movieFile'] != null
          ? MediaFile.fromJson(json['movieFile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (guid != null) 'id': guid,
      'tmdbId': tmdbId,
      if (imdbId != null) 'imdbId': imdbId,
      'title': title,
      'sortTitle': sortTitle,
      if (studio != null) 'studio': studio,
      'year': year,
      'runtime': runtime,
      if (overview != null) 'overview': overview,
      if (certification != null) 'certification': certification,
      if (youTubeTrailerId != null) 'youTubeTrailerId': youTubeTrailerId,
      if (originalLanguage != null)
        'originalLanguage': originalLanguage!.toJson(),
      'alternateTitles': alternateTitles.map((e) => e.toJson()).toList(),
      'genres': genres,
      'status': status.name,
      'isAvailable': isAvailable,
      'minimumAvailability': minimumAvailability.name,
      'monitored': monitored,
      'qualityProfileId': qualityProfileId,
      if (sizeOnDisk != null) 'sizeOnDisk': sizeOnDisk,
      if (hasFile != null) 'hasFile': hasFile,
      if (path != null) 'path': path,
      if (folderName != null) 'folderName': folderName,
      if (rootFolderPath != null) 'rootFolderPath': rootFolderPath,
      'added': added.toIso8601String(),
      if (inCinemas != null) 'inCinemas': inCinemas!.toIso8601String(),
      if (physicalRelease != null)
        'physicalRelease': physicalRelease!.toIso8601String(),
      if (digitalRelease != null)
        'digitalRelease': digitalRelease!.toIso8601String(),
      'tags': tags,
      'images': images.map((e) => e.toJson()).toList(),
      if (movieFile != null) 'movieFile': movieFile!.toJson(),
    };
  }

  Movie copyWith({
    int? guid,
    String? instanceId,
    int? tmdbId,
    String? imdbId,
    String? title,
    String? sortTitle,
    String? studio,
    int? year,
    int? runtime,
    String? overview,
    String? certification,
    String? youTubeTrailerId,
    MediaLanguage? originalLanguage,
    List<MediaAlternateTitle>? alternateTitles,
    List<String>? genres,
    MovieRatings? ratings,
    double? popularity,
    MovieStatus? status,
    bool? isAvailable,
    MovieStatus? minimumAvailability,
    bool? monitored,
    int? qualityProfileId,
    int? sizeOnDisk,
    bool? hasFile,
    String? path,
    String? relativePath,
    String? folderName,
    String? rootFolderPath,
    DateTime? added,
    DateTime? inCinemas,
    DateTime? physicalRelease,
    DateTime? digitalRelease,
    List<int>? tags,
    List<MediaImage>? images,
    MediaFile? movieFile,
  }) {
    return Movie(
      guid: guid ?? this.guid,
      instanceId: instanceId ?? this.instanceId,
      tmdbId: tmdbId ?? this.tmdbId,
      imdbId: imdbId ?? this.imdbId,
      title: title ?? this.title,
      sortTitle: sortTitle ?? this.sortTitle,
      studio: studio ?? this.studio,
      year: year ?? this.year,
      runtime: runtime ?? this.runtime,
      overview: overview ?? this.overview,
      certification: certification ?? this.certification,
      youTubeTrailerId: youTubeTrailerId ?? this.youTubeTrailerId,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      alternateTitles: alternateTitles ?? this.alternateTitles,
      genres: genres ?? this.genres,
      ratings: ratings ?? this.ratings,
      popularity: popularity ?? this.popularity,
      status: status ?? this.status,
      isAvailable: isAvailable ?? this.isAvailable,
      minimumAvailability: minimumAvailability ?? this.minimumAvailability,
      monitored: monitored ?? this.monitored,
      qualityProfileId: qualityProfileId ?? this.qualityProfileId,
      sizeOnDisk: sizeOnDisk ?? this.sizeOnDisk,
      hasFile: hasFile ?? this.hasFile,
      path: path ?? this.path,
      relativePath: relativePath ?? this.relativePath,
      folderName: folderName ?? this.folderName,
      rootFolderPath: rootFolderPath ?? this.rootFolderPath,
      added: added ?? this.added,
      inCinemas: inCinemas ?? this.inCinemas,
      physicalRelease: physicalRelease ?? this.physicalRelease,
      digitalRelease: digitalRelease ?? this.digitalRelease,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      movieFile: movieFile ?? this.movieFile,
    );
  }

  @override
  List<Object?> get props => [
    guid,
    instanceId,
    tmdbId,
    imdbId,
    title,
    sortTitle,
    studio,
    year,
    runtime,
    overview,
    certification,
    youTubeTrailerId,
    originalLanguage,
    alternateTitles,
    genres,
    ratings,
    popularity,
    status,
    isAvailable,
    minimumAvailability,
    monitored,
    qualityProfileId,
    sizeOnDisk,
    hasFile,
    path,
    relativePath,
    folderName,
    rootFolderPath,
    added,
    inCinemas,
    physicalRelease,
    digitalRelease,
    tags,
    images,
    movieFile,
  ];
}
