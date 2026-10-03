import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logger_service.dart';

/// Contains information about a new application update.
class AppUpdateInfo {
  // ...
  final String version;
  final String changelog;
  final String downloadUrl;
  final DateTime publishedAt;

  /// Published asset name, used to choose the native installer.
  final String? assetName;

  /// SHA-256 supplied by GitHub for the published asset.
  final String? sha256Digest;

  /// Expected download size in bytes.
  final int? sizeBytes;

  AppUpdateInfo({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
    required this.publishedAt,
    this.assetName,
    this.sha256Digest,
    this.sizeBytes,
  });
}

/// Summary of a single published release, used by the version history screen.
class AppReleaseInfo {
  final String version;
  final String changelog;
  final DateTime publishedAt;
  final bool isCurrentVersion;

  const AppReleaseInfo({
    required this.version,
    required this.changelog,
    required this.publishedAt,
    required this.isCurrentVersion,
  });
}

final updateServiceProvider = Provider((ref) => UpdateService(Dio()));

/// Service for checking and retrieving application updates from GitHub Releases.
class UpdateService {
  final Dio _dio;
  final TargetPlatform? _targetPlatform;
  final Future<List<String>> Function()? _androidAbis;
  static const _lastCheckKey = 'last_update_check';
  static const _seenVersionKey = 'last_seen_version';
  static const _repoUrl =
      'https://api.github.com/repos/lucasliet/arrmate/releases/latest';
  static const _releasesUrl =
      'https://api.github.com/repos/lucasliet/arrmate/releases?per_page=30';

  UpdateService(
    this._dio, {
    TargetPlatform? targetPlatform,
    Future<List<String>> Function()? androidAbis,
  }) : _targetPlatform = targetPlatform,
       _androidAbis = androidAbis;

  /// Strips a single leading `v` or `V` from a version tag (e.g. `v1.2.3`
  /// -> `1.2.3`), preserving any other `v` characters inside the version
  /// string itself.
  static String stripVersionPrefix(String version) {
    if (version.isEmpty) return version;
    final first = version[0];
    if (first == 'v' || first == 'V') return version.substring(1);
    return version;
  }

  /// Checks if a new update is available.
  ///
  /// [force] - If true, bypasses the daily check limit.
  /// Returns [AppUpdateInfo] if an update is available, null otherwise.
  Future<AppUpdateInfo?> checkForUpdate({bool force = false}) async {
    logger.debug('[UpdateService] Starting update check (force: $force)');
    final platform = _targetPlatform ?? defaultTargetPlatform;
    if (kIsWeb ||
        platform == TargetPlatform.iOS ||
        platform == TargetPlatform.fuchsia) {
      return null;
    }

    if (!force && !await _shouldCheckForUpdate()) {
      logger.debug(
        '[UpdateService] Skipping check - too soon since last check',
      );
      return null;
    }

    try {
      logger.debug('[UpdateService] Fetching latest release from GitHub...');
      final response = await _dio.get(
        _repoUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: kIsWeb
              ? null
              : {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
        ),
      );

      if (response.statusCode != 200) {
        logger.warning(
          '[UpdateService] GitHub API returned status ${response.statusCode}',
        );
        throw StateError(
          'GitHub returned ${response.statusCode} while checking for updates.',
        );
      }

      final data = response.data;
      final rawTagName = data['tag_name'] as String;
      logger.debug('[UpdateService] GitHub latest release tag: "$rawTagName"');

      final latestVersionStr = stripVersionPrefix(rawTagName);
      logger.debug(
        '[UpdateService] Latest version (parsed): "$latestVersionStr"',
      );

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(
        stripVersionPrefix(packageInfo.version),
      );
      final latestVersion = Version.parse(latestVersionStr);
      if (latestVersion <= currentVersion) {
        await _updateLastCheckTime();
        return null;
      }
      final changelog = data['body'] as String? ?? '';
      final assets = data['assets'] as List;

      String? architecture;
      if (platform == TargetPlatform.android) {
        final abis = _androidAbis != null
            ? await _androidAbis()
            : (await DeviceInfoPlugin().androidInfo).supportedAbis;
        logger.debug('[UpdateService] Supported ABIs: $abis');

        if (abis.contains('arm64-v8a')) {
          architecture = 'arm64-v8a';
        } else if (abis.contains('armeabi-v7a')) {
          architecture = 'armeabi-v7a';
        }
        logger.debug('[UpdateService] Selected architecture: $architecture');
      }

      final desktopName = switch (platform) {
        TargetPlatform.windows => 'arrmate-windows-x64.zip',
        TargetPlatform.linux => 'arrmate-linux-x64.AppImage',
        TargetPlatform.macOS => 'arrmate-macos.zip',
        _ => null,
      };
      final asset = assets.firstWhereOrNull((asset) {
        if (desktopName != null) return asset['name'] == desktopName;
        final name = (asset['name'] as String).toLowerCase();
        if (!name.endsWith('.apk')) return false;
        if (architecture != null) {
          return name.contains(architecture);
        }
        return true;
      });

      if (asset == null) {
        throw StateError(
          'This release has no update package for ${platform.name}.',
        );
      }

      logger.info('[UpdateService] Selected package: ${asset['name']}');

      final downloadUrl = asset['browser_download_url'] as String;
      final digest = asset['digest'] as String?;
      final checksum =
          digest != null && RegExp(r'^sha256:[a-fA-F0-9]{64}$').hasMatch(digest)
          ? digest.substring(7).toLowerCase()
          : null;
      if (desktopName != null && checksum == null) {
        throw StateError('The desktop update package has no SHA-256 checksum.');
      }
      final publishedAtStr = data['published_at'] as String?;
      final publishedAt = publishedAtStr != null
          ? DateTime.tryParse(publishedAtStr) ?? DateTime.now()
          : DateTime.now();

      logger.debug(
        '[UpdateService] Version comparison: Current: $currentVersion | Latest: $latestVersion',
      );

      await _updateLastCheckTime();

      logger.info('[UpdateService] Update available!');
      return AppUpdateInfo(
        version: latestVersionStr,
        changelog: changelog,
        downloadUrl: downloadUrl,
        publishedAt: publishedAt,
        assetName: asset['name'] as String,
        sha256Digest: checksum,
        sizeBytes: asset['size'] as int?,
      );
    } catch (e, stack) {
      logger.error('[UpdateService] Auto-check update failed', e, stack);
      rethrow;
    }
  }

  Future<bool> _shouldCheckForUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckMillis = prefs.getInt(_lastCheckKey) ?? 0;
    final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMillis);
    final now = DateTime.now();

    return now.difference(lastCheck).inDays >= 1;
  }

  Future<void> _updateLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Fetches the published release history, ordered from newest to oldest.
  Future<List<AppReleaseInfo>> fetchReleases() async {
    logger.debug('[UpdateService] Fetching release history from GitHub');

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = stripVersionPrefix(packageInfo.version);

    try {
      final response = await _dio.get<dynamic>(
        _releasesUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: kIsWeb
              ? null
              : {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
        ),
      );

      if (response.statusCode != 200 || response.data is! List) {
        logger.warning(
          '[UpdateService] Release history returned status ${response.statusCode}',
        );
        return [];
      }

      final releases = response.data as List;
      return releases.whereType<Map<String, dynamic>>().map((release) {
        final version = stripVersionPrefix(
          (release['tag_name'] as String?) ?? '',
        );
        final publishedAtStr = release['published_at'] as String?;
        return AppReleaseInfo(
          version: version,
          changelog: (release['body'] as String?)?.trim() ?? '',
          publishedAt: publishedAtStr != null
              ? DateTime.tryParse(publishedAtStr) ?? DateTime.now()
              : DateTime.now(),
          isCurrentVersion: version == currentVersion,
        );
      }).toList();
    } catch (e, stack) {
      logger.error('[UpdateService] Failed to fetch release history', e, stack);
      return [];
    }
  }

  /// Returns the last version whose changelog was shown to the user, or null
  /// when no "What's New" has been displayed yet.
  Future<String?> lastSeenVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_seenVersionKey);
  }

  /// Persists [version] as the most recently shown version.
  Future<void> markVersionSeen(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seenVersionKey, version);
  }

  /// Returns the "What's New" changelog for the running version when the user
  /// has not seen it yet, or null when it was already presented.
  Future<AppReleaseInfo?> whatsNewForCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = stripVersionPrefix(packageInfo.version);
    final seenVersion = await lastSeenVersion();

    if (seenVersion == currentVersion) {
      return null;
    }

    final releases = await fetchReleases();
    final currentRelease = releases.firstWhereOrNull(
      (release) => release.version == currentVersion,
    );

    return currentRelease?.copyWith(isCurrentVersion: true);
  }
}

extension on AppReleaseInfo {
  AppReleaseInfo copyWith({bool? isCurrentVersion}) {
    return AppReleaseInfo(
      version: version,
      changelog: changelog,
      publishedAt: publishedAt,
      isCurrentVersion: isCurrentVersion ?? this.isCurrentVersion,
    );
  }
}
