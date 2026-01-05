import 'package:equatable/equatable.dart';

// Usually Quality is a shared nested object like { "quality": { "id": 1, "name": "..." }, "revision": ... }
// I'll check if we already have a generic Quality model or if I should just map it dynamically or define it here.
// Checking `media_file.dart` or similar might give a hint, but I'll define a simple one here or reuse if existing.
// I'll assume Quality Model needs to be robust.

class Release extends Equatable {
  final String guid;
  final String title;
  final int size;
  final String link;
  final String indexer;
  final String indexerId; // Sometimes null or string
  final int seeders;
  final int leechers;
  final String protocol; // 'torrent' or 'usenet'
  final bool rejected;
  final List<String> rejections;
  final int age;
  final List<String> indexerFlags; // Sometimes used for scoring
  final String? infoUrl;
  final String? downloadUrl;
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
    required this.quality,
  });

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
      rejections:
          (json['rejections'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      age: json['age'] as int? ?? 0,
      indexerFlags:
          (json['indexerFlags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      infoUrl: json['infoUrl'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      quality: ReleaseQuality.fromJson(json['quality'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [guid, title, size, indexer, seeders, rejected];
}

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
