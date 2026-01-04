import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

class AppUpdateInfo {
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

final updateServiceProvider = Provider((ref) => UpdateService(Dio()));

class UpdateService {
  final Dio _dio;
  static const _lastCheckKey = 'last_update_check';
  static const _repoUrl = 'https://api.github.com/repos/lucasliet/arrmate/releases/latest';

  UpdateService(this._dio);

  /// Checks if a new update is available on GitHub.
  /// 
  /// Returns [AppUpdateInfo] if a newer version exists, null otherwise.
  /// [force] bypasses the daily check limit.
  Future<AppUpdateInfo?> checkForUpdate({bool force = false}) async {
    if (!force && !await _shouldCheckForUpdate()) {
      return null;
    }

    try {
      final response = await _dio.get(
        _repoUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.statusCode != 200) return null;

      final data = response.data;
      final latestVersionStr = (data['tag_name'] as String).replaceAll('v', '');
      final changelog = data['body'] as String;
      final assets = data['assets'] as List;
      
      // Look for an APK asset
      final apkAsset = assets.firstWhereOrNull(
        (asset) => (asset['name'] as String).endsWith('.apk'),
      );

      if (apkAsset == null) return null;

      final downloadUrl = apkAsset['browser_download_url'] as String;
      final publishedAtStr = data['published_at'] as String?;
      final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) ?? DateTime.now() : DateTime.now();

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);
      final latestVersion = Version.parse(latestVersionStr);

      await _updateLastCheckTime();

      if (latestVersion > currentVersion) {
        return AppUpdateInfo(
          version: latestVersionStr,
          changelog: changelog,
          downloadUrl: downloadUrl,
          publishedAt: publishedAt,
        );
      }
    } catch (e) {
      // Log error or handle silently for auto-check
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
}
