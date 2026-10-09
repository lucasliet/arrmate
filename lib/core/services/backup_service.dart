import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logger_service.dart';

/// Summary of what a restore changed on this device.
class BackupRestoreSummary {
  /// Number of preference keys written from the payload.
  final int restoredKeys;

  /// Number of stale preference keys removed because the payload did not
  /// contain them.
  final int removedKeys;

  /// Number of instances present in the restored payload.
  final int instanceCount;

  /// Creates a restore summary.
  const BackupRestoreSummary({
    required this.restoredKeys,
    required this.removedKeys,
    required this.instanceCount,
  });
}

/// Raised when a payload cannot be understood by this app version.
class BackupFormatException implements Exception {
  /// Human-readable description of what made the payload invalid.
  final String message;

  /// Creates a format exception with a user-readable [message].
  const BackupFormatException(this.message);

  @override
  String toString() => message;
}

/// A versioned snapshot of the app's SharedPreferences, including settings,
/// user preferences and configured instances.
class BackupPayload {
  /// Payload schema version; always 1.
  final int schema;

  /// App version that produced the payload.
  final String appVersion;

  /// Platform name ('android', 'ios', 'web', ...) that produced the payload.
  final String platform;

  /// UTC moment the payload was created.
  final DateTime createdAt;

  /// Snapshot of every backed-up preference keyed by its preference name.
  ///
  /// Each value is a typed entry map `{'t': 's' | 'i' | 'b' | 'l', 'v': ...}`
  /// where 'v' holds a String, int, bool or `List<String>` respectively.
  final Map<String, Object?> preferences;

  /// Creates a backup payload.
  const BackupPayload({
    required this.schema,
    required this.appVersion,
    required this.platform,
    required this.createdAt,
    required this.preferences,
  });

  /// Number of instances encoded in the 'instances' preference.
  ///
  /// Returns 0 when the entry is missing, not a string or not valid JSON.
  int get instanceCount {
    try {
      final entry = preferences['instances'];
      if (entry is! Map || entry['t'] != 's') return 0;
      final value = entry['v'];
      if (value is! String) return 0;
      final decoded = jsonDecode(value);
      return decoded is List ? decoded.length : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Serializes the payload to a compact JSON string.
  String toEncodedJson() {
    return jsonEncode({
      'schema': schema,
      'appVersion': appVersion,
      'platform': platform,
      'createdAt': createdAt.toIso8601String(),
      'preferences': preferences,
    });
  }

  /// Parses a payload produced by [toEncodedJson].
  ///
  /// Throws [BackupFormatException] when the source is not valid JSON, is not
  /// a JSON object, has a missing or unsupported schema, or lacks a
  /// preferences map. Individual malformed preference entries are dropped
  /// instead of failing the whole payload.
  factory BackupPayload.fromEncodedJson(String source) {
    final Object? parsed;
    try {
      parsed = jsonDecode(source);
    } catch (_) {
      throw const BackupFormatException('Backup file is not valid JSON.');
    }
    if (parsed is! Map) {
      throw const BackupFormatException(
        'Backup file does not contain a settings object.',
      );
    }
    final decoded = parsed;

    final schema = decoded['schema'];
    if (schema is! int || schema != 1) {
      throw BackupFormatException(
        schema == null
            ? 'Backup is missing its schema version.'
            : 'Backup schema version $schema is not supported by this app '
                  'version.',
      );
    }

    final rawPreferences = decoded['preferences'];
    if (rawPreferences is! Map) {
      throw const BackupFormatException(
        'Backup does not contain any preferences.',
      );
    }

    final preferences = <String, Object?>{};
    for (final entry in rawPreferences.entries) {
      final normalized = _normalizeEntry(entry.value);
      if (normalized == null) {
        logger.debug(
          '[BackupService] Dropping malformed backup entry: ${entry.key}',
        );
        continue;
      }
      preferences[entry.key as String] = normalized;
    }

    final appVersion = decoded['appVersion'];
    final platform = decoded['platform'];

    return BackupPayload(
      schema: schema,
      appVersion: appVersion is String ? appVersion : 'unknown',
      platform: platform is String ? platform : 'unknown',
      createdAt: _parseCreatedAt(decoded['createdAt']),
      preferences: preferences,
    );
  }

  static DateTime _parseCreatedAt(Object? raw) {
    if (raw is! String) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static Map<String, Object?>? _normalizeEntry(Object? raw) {
    if (raw is! Map) return null;
    final type = raw['t'];
    final value = raw['v'];
    return switch (type) {
      's' when value is String => {'t': 's', 'v': value},
      'i' when value is int => {'t': 'i', 'v': value},
      'b' when value is bool => {'t': 'b', 'v': value},
      'l' when value is List && value.every((item) => item is String) => {
        't': 'l',
        'v': List<String>.from(value),
      },
      _ => null,
    };
  }
}

/// Creates and restores versioned snapshots of the app's SharedPreferences.
class BackupService {
  static const _frameworkKeyPrefix = 'flutter.';
  static const _schemaVersion = 1;

  final Future<SharedPreferences> _preferences;
  final Future<PackageInfo> _packageInfo;

  /// Creates a backup service.
  ///
  /// [preferences] and [packageInfo] may be injected for tests; by default
  /// both resolve lazily from the platform.
  BackupService({SharedPreferences? preferences, PackageInfo? packageInfo})
    : _preferences = preferences != null
          ? Future.value(preferences)
          : SharedPreferences.getInstance(),
      _packageInfo = packageInfo != null
          ? Future.value(packageInfo)
          : PackageInfo.fromPlatform();

  /// Snapshots every non-framework preference into a [BackupPayload].
  Future<BackupPayload> createPayload() async {
    final prefs = await _preferences;
    final packageInfo = await _packageInfo;

    final preferences = <String, Object?>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_frameworkKeyPrefix)) continue;
      final entry = _encodeEntry(prefs.get(key));
      if (entry == null) continue;
      preferences[key] = entry;
    }

    final payload = BackupPayload(
      schema: _schemaVersion,
      appVersion: packageInfo.version,
      platform: _resolvePlatform(),
      createdAt: DateTime.now().toUtc(),
      preferences: preferences,
    );
    logger.info(
      '[BackupService] Created payload with ${preferences.length} '
      'preferences and ${payload.instanceCount} instances',
    );
    return payload;
  }

  /// Restores [payload] with replace semantics.
  ///
  /// Current keys absent from the payload are removed, and every well-formed
  /// payload entry is written back, returning a [BackupRestoreSummary].
  Future<BackupRestoreSummary> restore(BackupPayload payload) async {
    final prefs = await _preferences;

    var removedKeys = 0;
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_frameworkKeyPrefix)) continue;
      if (payload.preferences.containsKey(key)) continue;
      await prefs.remove(key);
      removedKeys++;
    }

    var restoredKeys = 0;
    for (final entry in payload.preferences.entries) {
      if (!await _writeEntry(prefs, entry.key, entry.value)) continue;
      restoredKeys++;
    }

    final summary = BackupRestoreSummary(
      restoredKeys: restoredKeys,
      removedKeys: removedKeys,
      instanceCount: payload.instanceCount,
    );
    logger.info(
      '[BackupService] Restored ${summary.restoredKeys} preferences, '
      'removed ${summary.removedKeys} stale keys, '
      '${summary.instanceCount} instances',
    );
    return summary;
  }

  /// Parses [encodedJson] so callers can preview a backup before restoring.
  Future<BackupPayload?> loadBackupPreview(String encodedJson) async {
    return BackupPayload.fromEncodedJson(encodedJson);
  }

  Map<String, Object?>? _encodeEntry(Object? value) {
    if (value is String) return {'t': 's', 'v': value};
    if (value is int) return {'t': 'i', 'v': value};
    if (value is bool) return {'t': 'b', 'v': value};
    if (value is List && value.every((item) => item is String)) {
      return {'t': 'l', 'v': List<String>.from(value)};
    }
    logger.debug(
      '[BackupService] Skipping unsupported preference type '
      '${value.runtimeType}',
    );
    return null;
  }

  Future<bool> _writeEntry(
    SharedPreferences prefs,
    String key,
    Object? entry,
  ) async {
    if (entry is! Map) return false;
    final type = entry['t'];
    final value = entry['v'];
    switch (type) {
      case 's':
        return value is String && await prefs.setString(key, value);
      case 'i':
        return value is int && await prefs.setInt(key, value);
      case 'b':
        return value is bool && await prefs.setBool(key, value);
      case 'l':
        if (value is! List || !value.every((item) => item is String)) {
          return false;
        }
        return await prefs.setStringList(key, List<String>.from(value));
      default:
        return false;
    }
  }

  String _resolvePlatform() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.fuchsia => 'fuchsia',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.linux => 'linux',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
    };
  }
}
