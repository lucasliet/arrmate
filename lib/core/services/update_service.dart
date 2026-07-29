import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'logger_service.dart';

/// Contains information about a new application update.
class AppUpdateInfo {
  // ...
  final String version;
  final String changelog;
  final String downloadUrl;
  final DateTime publishedAt;

  AppUpdateInfo({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
    required this.publishedAt,
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
  static const _lastCheckKey = 'last_update_check';
  static const _seenVersionKey = 'last_seen_version';
  static const _repoUrl =
      'https://api.github.com/repos/lucasliet/arrmate/releases/latest';
  static const _releasesUrl =
      'https://api.github.com/repos/lucasliet/arrmate/releases?per_page=30';

  UpdateService(this._dio);

  /// Checks if a new update is available.
  ///
  /// [force] - If true, bypasses the daily check limit.
  /// Returns [AppUpdateInfo] if an update is available, null otherwise.
  Future<AppUpdateInfo?> checkForUpdate({bool force = false}) async {
    logger.debug('[UpdateService] Starting update check (force: $force)');

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
          headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
        ),
      );

      if (response.statusCode != 200) {
        logger.warning(
          '[UpdateService] GitHub API returned status ${response.statusCode}',
        );
        return null;
      }

      final data = response.data;
      final rawTagName = data['tag_name'] as String;
      logger.debug('[UpdateService] GitHub latest release tag: "$rawTagName"');

      final latestVersionStr = rawTagName.replaceAll('v', '');
      logger.debug(
        '[UpdateService] Latest version (parsed): "$latestVersionStr"',
      );

      final changelog = data['body'] as String;
      final assets = data['assets'] as List;

      String? architecture;
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final abis = androidInfo.supportedAbis;
        logger.debug('[UpdateService] Supported ABIs: $abis');

        if (abis.contains('arm64-v8a')) {
          architecture = 'arm64-v8a';
        } else if (abis.contains('armeabi-v7a')) {
          architecture = 'armeabi-v7a';
        }
        logger.debug('[UpdateService] Selected architecture: $architecture');
      }

      // Look for a matching APK asset
      final apkAsset =
          assets.firstWhereOrNull((asset) {
            final name = (asset['name'] as String).toLowerCase();
            if (!name.endsWith('.apk')) return false;

            // If we detected an architecture, try to find a match in the filename
            if (architecture != null) {
              return name.contains(architecture);
            }
            return true;
          }) ??
          assets.firstWhereOrNull(
            (asset) => (asset['name'] as String).endsWith('.apk'),
          );

      if (apkAsset == null) {
        logger.warning(
          '[UpdateService] No matching APK asset found in release',
        );
        return null;
      }

      logger.info(
        '[UpdateService] Selected APK: ${apkAsset['name']} for architecture: $architecture',
      );

      final downloadUrl = apkAsset['browser_download_url'] as String;
      final publishedAtStr = data['published_at'] as String?;
      final publishedAt = publishedAtStr != null
          ? DateTime.tryParse(publishedAtStr) ?? DateTime.now()
          : DateTime.now();

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = packageInfo.version;
      logger.debug(
        '[UpdateService] Current app version (raw): "$currentVersionStr"',
      );

      final currentVersion = Version.parse(
        currentVersionStr.replaceAll('v', ''),
      );
      final latestVersion = Version.parse(latestVersionStr);

      logger.debug(
        '[UpdateService] Version comparison: Current: $currentVersion | Latest: $latestVersion',
      );

      await _updateLastCheckTime();

      if (latestVersion > currentVersion) {
        logger.info('[UpdateService] Update available!');
        return AppUpdateInfo(
          version: latestVersionStr,
          changelog: changelog,
          downloadUrl: downloadUrl,
          publishedAt: publishedAt,
        );
      } else {
        logger.info('[UpdateService] No update needed - app is up to date');
      }
    } catch (e, stack) {
      logger.error('[UpdateService] Auto-check update failed', e, stack);
    }

    return null;
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
    final currentVersion = packageInfo.version.replaceAll('v', '');

    try {
      final response = await _dio.get<dynamic>(
        _releasesUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
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
        final version =
            (release['tag_name'] as String?)?.replaceAll('v', '') ?? '';
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
    final currentVersion = packageInfo.version.replaceAll('v', '');
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
