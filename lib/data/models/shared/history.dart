import 'package:equatable/equatable.dart';

import 'shared.dart';

class HistoryPage extends Equatable {
  final int page;
  final int pageSize;
  final int totalRecords;
  final List<HistoryEvent> records;

  const HistoryPage({
    required this.page,
    required this.pageSize,
    required this.totalRecords,
    required this.records,
  });

  bool get hasMore => totalRecords > page * pageSize;

  factory HistoryPage.fromJson(Map<String, dynamic> json, {String? instanceId}) {
    return HistoryPage(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalRecords: json['totalRecords'] as int,
      records: (json['records'] as List<dynamic>)
          .map((e) => HistoryEvent.fromJson(e as Map<String, dynamic>, instanceId: instanceId))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [page, pageSize, totalRecords, records];
}

class HistoryEvent extends Equatable {
  final int id;
  final HistoryEventType eventType;
  final DateTime date;
  final String? sourceTitle;
  final String? instanceId;

  final int? movieId;
  final int? seriesId;
  final int? episodeId;

  final MediaQuality quality;
  final List<MediaLanguage>? languages;
  final List<MediaCustomFormat>? customFormats;
  final int? customFormatScore;

  final Map<String, String?>? data;

  const HistoryEvent({
    required this.id,
    required this.eventType,
    required this.date,
    this.sourceTitle,
    this.instanceId,
    this.movieId,
    this.seriesId,
    this.episodeId,
    required this.quality,
    this.languages,
    this.customFormats,
    this.customFormatScore,
    this.data,
  });

  bool get isMovie => movieId != null;
  bool get isEpisode => episodeId != null;

  String get languageLabel {
    if (languages == null || languages!.isEmpty) return 'Unknown';
    return languages!.map((l) => l.name).join(', ');
  }

  String? get scoreLabel {
    if (customFormats == null || customFormats!.isEmpty) return null;
    final score = customFormatScore ?? 0;
    return score >= 0 ? '+$score' : '$score';
  }

  String? get indexer => _getData('indexer');
  String? get downloadClient => _getData('downloadClient');
  String? get message => _getData('message');
  String? get releaseSource => _getData('releaseSource');

  String? _getData(String key) {
    if (data == null) return null;
    return data![key];
  }

  String get description {
    final mediaNoun = isMovie ? 'Movie' : 'Episode';
    final indexerName = indexer ?? 'indexer';
    final clientName = downloadClient ?? 'download client';

    switch (eventType) {
      case HistoryEventType.grabbed:
        return '$mediaNoun grabbed from $indexerName and sent to $clientName.';
      case HistoryEventType.imported:
        return '$mediaNoun downloaded successfully and imported from $clientName.';
      case HistoryEventType.failed:
        return message ?? 'Download failed.';
      case HistoryEventType.ignored:
        return message ?? 'Download ignored.';
      case HistoryEventType.renamed:
        return '$mediaNoun file was renamed.';
      case HistoryEventType.deleted:
        final reason = _getData('reason');
        if (reason == 'Manual') {
          return 'File was deleted manually or by a client through the API.';
        } else if (reason == 'MissingFromDisk') {
          return 'File was not found on disk so it was unlinked from the database.';
        } else if (reason == 'Upgrade') {
          return 'File was deleted to import an upgrade.';
        }
        return 'File was deleted.';
      case HistoryEventType.unknown:
        return 'Unknown event.';
    }
  }

  factory HistoryEvent.fromJson(Map<String, dynamic> json, {String? instanceId}) {
    return HistoryEvent(
      id: json['id'] as int,
      eventType: HistoryEventType.fromString(json['eventType'] as String?),
      date: DateTime.parse(json['date'] as String),
      sourceTitle: json['sourceTitle'] as String?,
      instanceId: instanceId,
      movieId: json['movieId'] as int?,
      seriesId: json['seriesId'] as int?,
      episodeId: json['episodeId'] as int?,
      quality: MediaQuality.fromJson(json['quality'] as Map<String, dynamic>),
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => MediaLanguage.fromJson(e as Map<String, dynamic>))
          .toList(),
      customFormats: (json['customFormats'] as List<dynamic>?)
          ?.map((e) => MediaCustomFormat.fromJson(e as Map<String, dynamic>))
          .toList(),
      customFormatScore: json['customFormatScore'] as int?,
      data: (json['data'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v?.toString()),
      ),
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventType,
        date,
        sourceTitle,
        instanceId,
        movieId,
        seriesId,
        episodeId,
        quality,
        languages,
        customFormats,
        customFormatScore,
        data,
      ];
}

enum HistoryEventType {
  unknown,
  grabbed,
  imported,
  failed,
  deleted,
  renamed,
  ignored;

  static HistoryEventType fromString(String? value) {
    switch (value) {
      case 'grabbed':
        return HistoryEventType.grabbed;
      case 'downloadFolderImported':
      case 'movieFolderImported':
      case 'seriesFolderImported':
        return HistoryEventType.imported;
      case 'downloadFailed':
        return HistoryEventType.failed;
      case 'downloadIgnored':
        return HistoryEventType.ignored;
      case 'movieFileRenamed':
      case 'episodeFileRenamed':
        return HistoryEventType.renamed;
      case 'movieFileDeleted':
      case 'episodeFileDeleted':
        return HistoryEventType.deleted;
      default:
        return HistoryEventType.unknown;
    }
  }

  String get label {
    switch (this) {
      case HistoryEventType.grabbed:
        return 'Grabbed';
      case HistoryEventType.imported:
        return 'Imported';
      case HistoryEventType.failed:
        return 'Failed';
      case HistoryEventType.ignored:
        return 'Ignored';
      case HistoryEventType.renamed:
        return 'Renamed';
      case HistoryEventType.deleted:
        return 'Deleted';
      case HistoryEventType.unknown:
        return 'Unknown';
    }
  }

  String get title {
    switch (this) {
      case HistoryEventType.grabbed:
        return 'Release Grabbed';
      case HistoryEventType.imported:
        return 'Folder Imported';
      case HistoryEventType.failed:
        return 'Download Failed';
      case HistoryEventType.ignored:
        return 'Download Ignored';
      case HistoryEventType.renamed:
        return 'File Renamed';
      case HistoryEventType.deleted:
        return 'File Deleted';
      case HistoryEventType.unknown:
        return 'Unknown Event';
    }
  }

  int? toRadarrEventType() {
    switch (this) {
      case HistoryEventType.grabbed:
        return 1;
      case HistoryEventType.imported:
        return 3;
      case HistoryEventType.failed:
        return 4;
      case HistoryEventType.deleted:
        return 6;
      case HistoryEventType.renamed:
        return 8;
      case HistoryEventType.ignored:
        return 9;
      default:
        return null;
    }
  }

  int? toSonarrEventType() {
    switch (this) {
      case HistoryEventType.grabbed:
        return 1;
      case HistoryEventType.imported:
        return 3;
      case HistoryEventType.failed:
        return 4;
      case HistoryEventType.deleted:
        return 5;
      case HistoryEventType.renamed:
        return 6;
      case HistoryEventType.ignored:
        return 7;
      default:
        return null;
    }
  }
}
