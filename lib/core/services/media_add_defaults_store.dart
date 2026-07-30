import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/models.dart';
import 'logger_service.dart';

/// Persisted defaults for adding movies to one Radarr instance.
class MovieAddDefaults {
  /// Monitoring strategy last selected by the user.
  final MovieMonitorType monitor;

  /// Minimum availability last selected by the user.
  final MovieStatus minimumAvailability;

  /// Quality profile last selected by the user.
  final int? qualityProfileId;

  /// Root folder last selected by the user.
  final String? rootFolderPath;

  /// Tag IDs last selected by the user.
  final List<int> tags;

  /// Creates movie addition defaults.
  const MovieAddDefaults({
    this.monitor = MovieMonitorType.movieOnly,
    this.minimumAvailability = MovieStatus.announced,
    this.qualityProfileId,
    this.rootFolderPath,
    this.tags = const [],
  });

  /// Creates defaults from persisted JSON.
  factory MovieAddDefaults.fromJson(Map<String, dynamic> json) {
    return MovieAddDefaults(
      monitor: MovieMonitorType.values.firstWhere(
        (value) => value.name == json['monitor'],
        orElse: () => MovieMonitorType.movieOnly,
      ),
      minimumAvailability: MovieStatus.values.firstWhere(
        (value) => value.name == json['minimumAvailability'],
        orElse: () => MovieStatus.announced,
      ),
      qualityProfileId: json['qualityProfileId'] as int?,
      rootFolderPath: json['rootFolderPath'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.whereType<int>().toList() ??
          const [],
    );
  }

  /// Converts the defaults to JSON for persistence.
  Map<String, dynamic> toJson() {
    return {
      'monitor': monitor.name,
      'minimumAvailability': minimumAvailability.name,
      'qualityProfileId': qualityProfileId,
      'rootFolderPath': rootFolderPath,
      'tags': tags,
    };
  }
}

/// Persisted defaults for adding series to one Sonarr instance.
class SeriesAddDefaults {
  /// Episode monitoring strategy last selected by the user.
  final SeriesMonitorType monitor;

  /// Whether newly added seasons should be monitored.
  final SeriesMonitorNewItems monitorNewItems;

  /// Series type last selected by the user.
  final SeriesType seriesType;

  /// Whether season folders should be created.
  final bool seasonFolder;

  /// Quality profile last selected by the user.
  final int? qualityProfileId;

  /// Root folder last selected by the user.
  final String? rootFolderPath;

  /// Tag IDs last selected by the user.
  final List<int> tags;

  /// Creates series addition defaults.
  const SeriesAddDefaults({
    this.monitor = SeriesMonitorType.none,
    this.monitorNewItems = SeriesMonitorNewItems.none,
    this.seriesType = SeriesType.standard,
    this.seasonFolder = true,
    this.qualityProfileId,
    this.rootFolderPath,
    this.tags = const [],
  });

  /// Creates defaults from persisted JSON.
  factory SeriesAddDefaults.fromJson(Map<String, dynamic> json) {
    return SeriesAddDefaults(
      monitor: SeriesMonitorType.values.firstWhere(
        (value) => value.name == json['monitor'],
        orElse: () => SeriesMonitorType.none,
      ),
      monitorNewItems: SeriesMonitorNewItems.values.firstWhere(
        (value) => value.name == json['monitorNewItems'],
        orElse: () => SeriesMonitorNewItems.none,
      ),
      seriesType: SeriesType.values.firstWhere(
        (value) => value.name == json['seriesType'],
        orElse: () => SeriesType.standard,
      ),
      seasonFolder: json['seasonFolder'] as bool? ?? true,
      qualityProfileId: json['qualityProfileId'] as int?,
      rootFolderPath: json['rootFolderPath'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.whereType<int>().toList() ??
          const [],
    );
  }

  /// Converts the defaults to JSON for persistence.
  Map<String, dynamic> toJson() {
    return {
      'monitor': monitor.name,
      'monitorNewItems': monitorNewItems.name,
      'seriesType': seriesType.name,
      'seasonFolder': seasonFolder,
      'qualityProfileId': qualityProfileId,
      'rootFolderPath': rootFolderPath,
      'tags': tags,
    };
  }
}

/// Persists media addition defaults independently for every instance.
class MediaAddDefaultsStore {
  static const _moviePrefix = 'movie_add_defaults_';
  static const _seriesPrefix = 'series_add_defaults_';

  /// Loads the movie addition defaults for [instanceId].
  Future<MovieAddDefaults> loadMovie(String instanceId) async {
    final json = await _read('$_moviePrefix$instanceId');
    return json == null
        ? const MovieAddDefaults()
        : MovieAddDefaults.fromJson(json);
  }

  /// Saves movie addition [defaults] for [instanceId].
  Future<void> saveMovie(String instanceId, MovieAddDefaults defaults) async {
    await _write('$_moviePrefix$instanceId', defaults.toJson());
  }

  /// Loads the series addition defaults for [instanceId].
  Future<SeriesAddDefaults> loadSeries(String instanceId) async {
    final json = await _read('$_seriesPrefix$instanceId');
    return json == null
        ? const SeriesAddDefaults()
        : SeriesAddDefaults.fromJson(json);
  }

  /// Saves series addition [defaults] for [instanceId].
  Future<void> saveSeries(String instanceId, SeriesAddDefaults defaults) async {
    await _write('$_seriesPrefix$instanceId', defaults.toJson());
  }

  Future<Map<String, dynamic>?> _read(String key) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString(key);
      if (value == null) return null;
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (error, stackTrace) {
      logger.error(
        '[MediaAddDefaultsStore] Failed to load defaults',
        error,
        stackTrace,
      );
      return null;
    }
  }

  Future<void> _write(String key, Map<String, dynamic> value) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(key, jsonEncode(value));
    if (!saved) {
      throw StateError('Unable to persist media addition defaults');
    }
  }
}
