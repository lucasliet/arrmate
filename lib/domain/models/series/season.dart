import 'package:equatable/equatable.dart';

/// Represents a season in a TV series.
class Season extends Equatable {
  final int seasonNumber;
  final bool monitored;
  final SeasonStatistics? statistics;

  const Season({
    required this.seasonNumber,
    required this.monitored,
    this.statistics,
  });

  int get id => seasonNumber;

  /// Returns a display label for the season (e.g., 'Season 1' or 'Specials').
  String get label {
    if (seasonNumber == 0) return 'Specials';
    return 'Season $seasonNumber';
  }

  int get episodeCount => statistics?.episodeCount ?? 0;
  int get episodeFileCount => statistics?.episodeFileCount ?? 0;
  double get percentOfEpisodes => statistics?.percentOfEpisodes ?? 0;
  int get sizeOnDisk => statistics?.sizeOnDisk ?? 0;

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      seasonNumber: json['seasonNumber'] as int,
      monitored: json['monitored'] as bool? ?? false,
      statistics: json['statistics'] != null
          ? SeasonStatistics.fromJson(
              json['statistics'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonNumber': seasonNumber,
      'monitored': monitored,
      if (statistics != null) 'statistics': statistics!.toJson(),
    };
  }

  Season copyWith({
    int? seasonNumber,
    bool? monitored,
    SeasonStatistics? statistics,
  }) {
    return Season(
      seasonNumber: seasonNumber ?? this.seasonNumber,
      monitored: monitored ?? this.monitored,
      statistics: statistics ?? this.statistics,
    );
  }

  @override
  List<Object?> get props => [seasonNumber, monitored, statistics];
}

/// Contains statistics about a season.
class SeasonStatistics extends Equatable {
  final int episodeCount;
  final int episodeFileCount;
  final int totalEpisodeCount;
  final double percentOfEpisodes;
  final int sizeOnDisk;

  const SeasonStatistics({
    required this.episodeCount,
    required this.episodeFileCount,
    required this.totalEpisodeCount,
    required this.percentOfEpisodes,
    required this.sizeOnDisk,
  });

  factory SeasonStatistics.fromJson(Map<String, dynamic> json) {
    return SeasonStatistics(
      episodeCount: json['episodeCount'] as int? ?? 0,
      episodeFileCount: json['episodeFileCount'] as int? ?? 0,
      totalEpisodeCount: json['totalEpisodeCount'] as int? ?? 0,
      percentOfEpisodes: (json['percentOfEpisodes'] as num?)?.toDouble() ?? 0.0,
      sizeOnDisk: json['sizeOnDisk'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'episodeCount': episodeCount,
      'episodeFileCount': episodeFileCount,
      'totalEpisodeCount': totalEpisodeCount,
      'percentOfEpisodes': percentOfEpisodes,
      'sizeOnDisk': sizeOnDisk,
    };
  }

  @override
  List<Object?> get props => [
    episodeCount,
    episodeFileCount,
    totalEpisodeCount,
    percentOfEpisodes,
    sizeOnDisk,
  ];
}
