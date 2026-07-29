import 'package:equatable/equatable.dart';
import 'package:arrmate/domain/models/shared/media_custom_format.dart';
import 'package:arrmate/domain/models/shared/media_language.dart';

/// Represents a release found by an indexer.
class Release extends Equatable {
  final String guid;
  final String title;
  final int size;
  final String link;
  final String indexer;
  final String indexerId;
  final int seeders;
  final int leechers;
  final String protocol;
  final bool rejected;
  final List<String> rejections;
  final int age;
  final List<String> indexerFlags;
  final String? infoUrl;
  final String? downloadUrl;
  final int customFormatScore;
  final int qualityWeight;
  final int releaseWeight;
  final List<MediaLanguage> languages;
  final List<MediaCustomFormat> customFormats;
  final List<int> mappedEpisodeNumbers;
  final bool fullSeason;
  final bool episodeRequested;
  final ReleaseQuality quality;

  const Release({
    required this.guid,
    required this.title,
    required this.size,
    required this.link,
    required this.indexer,
    required this.indexerId,
    this.seeders = 0,
    this.leechers = 0,
    required this.protocol,
    this.rejected = false,
    this.rejections = const [],
    required this.age,
    this.indexerFlags = const [],
    this.infoUrl,
    this.downloadUrl,
    int customFormatScore = 0,
    int? score,
    this.qualityWeight = 0,
    this.releaseWeight = 0,
    this.languages = const [],
    this.customFormats = const [],
    this.mappedEpisodeNumbers = const [],
    this.fullSeason = false,
    this.episodeRequested = false,
    required this.quality,
  }) : customFormatScore = score ?? customFormatScore;

  factory Release.fromJson(Map<String, dynamic> json) {
    return Release(
      guid: json['guid'] as String,
      title: json['title'] as String,
      size: json['size'] as int? ?? 0,
      link: json['link'] as String? ?? '', // Often internal link
      indexer: json['indexer'] as String? ?? 'Unknown',
      indexerId: json['indexerId']?.toString() ?? '',
      seeders: json['seeders'] as int? ?? 0,
      leechers: json['leechers'] as int? ?? 0,
      protocol: json['protocol'] as String? ?? 'torrent',
      rejected: json['rejected'] as bool? ?? false,
      rejections: (json['rejections'] is List)
          ? (json['rejections'] as List).map((e) => e.toString()).toList()
          : [],
      age: json['age'] as int? ?? 0,
      indexerFlags: (json['indexerFlags'] is List)
          ? _parseStringList(json['indexerFlags'])
          : _parseIndexerFlagBitmask(json['indexerFlags']),
      infoUrl: json['infoUrl'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      customFormatScore: _parseInt(json['customFormatScore']),
      qualityWeight: _parseInt(json['qualityWeight']),
      releaseWeight: _parseInt(json['releaseWeight']),
      languages: _parseModelList(json['languages'], MediaLanguage.fromJson),
      customFormats: _parseModelList(
        json['customFormats'],
        MediaCustomFormat.fromJson,
      ),
      mappedEpisodeNumbers: _parseIntList(json['mappedEpisodeNumbers']),
      fullSeason: json['fullSeason'] as bool? ?? false,
      episodeRequested: json['episodeRequested'] as bool? ?? false,
      quality: ReleaseQuality.fromJson(json['quality'] as Map<String, dynamic>),
    );
  }

  int get score => customFormatScore;

  bool get isFreeleech {
    return indexerFlags.any((flag) {
      final normalized = flag.split('_').last.toLowerCase();
      return normalized == 'freeleech';
    });
  }

  @override
  List<Object?> get props => [
    guid,
    title,
    size,
    link,
    indexer,
    indexerId,
    seeders,
    leechers,
    protocol,
    rejected,
    rejections,
    age,
    indexerFlags,
    infoUrl,
    downloadUrl,
    customFormatScore,
    qualityWeight,
    releaseWeight,
    languages,
    customFormats,
    mappedEpisodeNumbers,
    fullSeason,
    episodeRequested,
    quality,
  ];
}

const _indexerFlagNames = <int, String>{
  1: 'Freeleech',
  2: 'Halfleech',
  4: 'DoubleUpload',
  8: 'Internal',
  16: 'Scene',
  32: 'Freeleech75',
  64: 'Freeleech25',
  128: 'Nuked',
};

int _parseInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

List<int> _parseIntList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<num>().map((item) => item.toInt()).toList();
}

List<String> _parseStringList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}

List<String> _parseIndexerFlagBitmask(Object? value) {
  final bitmask = _parseInt(value);
  if (bitmask <= 0) return const [];
  return _indexerFlagNames.entries
      .where((entry) => bitmask & entry.key != 0)
      .map((entry) => entry.value)
      .toList();
}

List<T> _parseModelList<T>(
  Object? value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().map(fromJson).toList();
}

/// Describes the quality of a release.
class ReleaseQuality extends Equatable {
  final ReleaseQualityItem quality;
  final ReleaseQualityRevision revision;

  const ReleaseQuality({required this.quality, required this.revision});

  factory ReleaseQuality.fromJson(Map<String, dynamic> json) {
    return ReleaseQuality(
      quality: ReleaseQualityItem.fromJson(
        json['quality'] as Map<String, dynamic>,
      ),
      revision: ReleaseQualityRevision.fromJson(
        json['revision'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  List<Object?> get props => [quality, revision];

  String get name =>
      '${quality.name} ${revision.version > 1 ? "v${revision.version}" : ""}';
}

/// Details about the quality profile item of a release.
class ReleaseQualityItem extends Equatable {
  final int id;
  final String name;
  final String? source;
  final int resolution;

  const ReleaseQualityItem({
    required this.id,
    required this.name,
    this.source,
    this.resolution = 0,
  });

  factory ReleaseQualityItem.fromJson(Map<String, dynamic> json) {
    return ReleaseQualityItem(
      id: json['id'] as int,
      name: json['name'] as String,
      source: json['source'] as String?,
      resolution: json['resolution'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name];
}

/// Details about the version/revision of a release quality.
class ReleaseQualityRevision extends Equatable {
  final int version;
  final int real;
  final bool isRepack;

  const ReleaseQualityRevision({
    this.version = 1,
    this.real = 0,
    this.isRepack = false,
  });

  factory ReleaseQualityRevision.fromJson(Map<String, dynamic> json) {
    return ReleaseQualityRevision(
      version: json['version'] as int? ?? 1,
      real: json['real'] as int? ?? 0,
      isRepack: json['isRepack'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [version, real, isRepack];
}
