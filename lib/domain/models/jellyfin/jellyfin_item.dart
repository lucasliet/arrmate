import 'package:equatable/equatable.dart';

import 'jellyfin_media_stream.dart';

/// A Jellyfin library item: movie, series, season, episode, or bare video.
class JellyfinItem extends Equatable {
  /// Jellyfin item id (GUID string).
  final String id;

  /// Display name of the item.
  final String? name;

  /// Jellyfin item type (`Movie`, `Series`, `Season`, `Episode`, `Folder`,
  /// `Video`).
  final String? type;

  /// Absolute server-side file system path, when the item is file-backed.
  final String? path;

  /// Parent series name for episode items.
  final String? seriesName;

  /// Season number for episode items.
  final int? parentIndexNumber;

  /// Episode number for episode items.
  final int? indexNumber;

  /// External provider ids with normalized lowercase keys (`tmdb`, `imdb`,
  /// `tvdb`).
  final Map<String, String> providerIds;

  /// Release year.
  final int? productionYear;

  /// Runtime expressed in Jellyfin ticks (100 ns).
  final int? runTimeTicks;

  /// Resume position in Jellyfin ticks (100 ns), read from `UserData`.
  final int? playbackPositionTicks;

  /// Whether the item is marked as played, read from `UserData`.
  final bool? played;

  /// File container (e.g. `mkv`, `mp4`).
  final String? container;

  /// Playable media sources attached to this item.
  final List<JellyfinMediaSource> mediaSources;

  /// Creates a Jellyfin item description.
  const JellyfinItem({
    required this.id,
    this.name,
    this.type,
    this.path,
    this.seriesName,
    this.parentIndexNumber,
    this.indexNumber,
    this.providerIds = const {},
    this.productionYear,
    this.runTimeTicks,
    this.playbackPositionTicks,
    this.played,
    this.container,
    this.mediaSources = const [],
  });

  /// Builds an item from a Jellyfin `BaseItemDto` JSON object.
  ///
  /// Provider id keys are lowercased and stripped of trailing dots so plugins
  /// that register prefixed names (`tmdb.`) still normalize to `tmdb`.
  factory JellyfinItem.fromJson(Map<String, dynamic> json) {
    return JellyfinItem(
      id: json['Id']?.toString() ?? '',
      name: json['Name'] as String?,
      type: json['Type'] as String?,
      path: json['Path'] as String?,
      seriesName: json['SeriesName'] as String?,
      parentIndexNumber: (json['ParentIndexNumber'] as num?)?.toInt(),
      indexNumber: (json['IndexNumber'] as num?)?.toInt(),
      providerIds: _parseProviderIds(json['ProviderIds']),
      productionYear: (json['ProductionYear'] as num?)?.toInt(),
      runTimeTicks: (json['RunTimeTicks'] as num?)?.toInt(),
      playbackPositionTicks: _parseUserDataTick(
        json['UserData'],
        'PlaybackPositionTicks',
      ),
      played: _parseUserDataPlayed(json['UserData']),
      container: json['Container'] as String?,
      mediaSources: _parseMediaSources(json['MediaSources']),
    );
  }

  /// Serializes the item back to a Jellyfin-compatible JSON object.
  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      if (name != null) 'Name': name,
      if (type != null) 'Type': type,
      if (path != null) 'Path': path,
      if (seriesName != null) 'SeriesName': seriesName,
      if (parentIndexNumber != null) 'ParentIndexNumber': parentIndexNumber,
      if (indexNumber != null) 'IndexNumber': indexNumber,
      'ProviderIds': providerIds,
      if (productionYear != null) 'ProductionYear': productionYear,
      if (runTimeTicks != null) 'RunTimeTicks': runTimeTicks,
      if (playbackPositionTicks != null || played != null)
        'UserData': {
          if (playbackPositionTicks != null)
            'PlaybackPositionTicks': playbackPositionTicks,
          if (played != null) 'Played': played,
        },
      if (container != null) 'Container': container,
      'MediaSources': mediaSources.map((source) => source.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    path,
    seriesName,
    parentIndexNumber,
    indexNumber,
    providerIds,
    productionYear,
    runTimeTicks,
    playbackPositionTicks,
    played,
    container,
    mediaSources,
  ];

  /// Normalizes raw `ProviderIds` entries to lowercase bare keys.
  static Map<String, String> _parseProviderIds(dynamic raw) {
    final providerIds = <String, String>{};
    if (raw is! Map) return providerIds;
    for (final entry in raw.entries) {
      final key = entry.key?.toString() ?? '';
      final value = entry.value?.toString();
      if (key.isEmpty || value == null || value.isEmpty) continue;
      providerIds[key.toLowerCase().replaceFirst(RegExp(r'\.+$'), '')] = value;
    }
    return providerIds;
  }

  static int? _parseUserDataTick(dynamic userData, String field) {
    if (userData is! Map) return null;
    return (userData[field] as num?)?.toInt();
  }

  static bool? _parseUserDataPlayed(dynamic userData) {
    if (userData is! Map) return null;
    return userData['Played'] as bool?;
  }

  static List<JellyfinMediaSource> _parseMediaSources(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map)
          JellyfinMediaSource.fromJson(Map<String, dynamic>.from(entry)),
    ];
  }
}

/// A playable representation of a [JellyfinItem] on the server file system.
class JellyfinMediaSource extends Equatable {
  /// Jellyfin media source id.
  final String id;

  /// File container (e.g. `mkv`, `mp4`).
  final String? container;

  /// Absolute server-side path of the media file.
  final String? path;

  /// File size in bytes, when reported.
  final int? size;

  /// Audio, video, and subtitle streams inside this source.
  final List<JellyfinMediaStream> mediaStreams;

  /// Creates a media source description.
  const JellyfinMediaSource({
    required this.id,
    this.container,
    this.path,
    this.size,
    this.mediaStreams = const [],
  });

  /// Builds a media source from a Jellyfin `MediaSourceInfo` JSON object.
  factory JellyfinMediaSource.fromJson(Map<String, dynamic> json) {
    final rawStreams = json['MediaStreams'];
    return JellyfinMediaSource(
      id: json['Id']?.toString() ?? '',
      container: json['Container'] as String?,
      path: json['Path'] as String?,
      size: (json['Size'] as num?)?.toInt(),
      mediaStreams: rawStreams is List
          ? [
              for (final entry in rawStreams)
                if (entry is Map)
                  JellyfinMediaStream.fromJson(
                    Map<String, dynamic>.from(entry),
                  ),
            ]
          : const [],
    );
  }

  /// Serializes the source back to a Jellyfin-compatible JSON object.
  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      if (container != null) 'Container': container,
      if (path != null) 'Path': path,
      if (size != null) 'Size': size,
      'MediaStreams': mediaStreams.map((stream) => stream.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, container, path, size, mediaStreams];
}
