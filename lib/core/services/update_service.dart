import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'logger_service.dart';

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

final updateServiceProvider = Provider((ref) => UpdateService(Dio()));

class UpdateService {
  final Dio _dio;
  static const _lastCheckKey = 'last_update_check';
  static const _repoUrl =
      'https://api.github.com/repos/lucasliet/arrmate/releases/latest';

  UpdateService(this._dio);

  Future<AppUpdateInfo?> checkForUpdate({bool force = false}) async {
    logger.info('🔍 Starting update check (force: $force)');

    if (!force && !await _shouldCheckForUpdate()) {
      logger.info('⏸️ Skipping check - too soon since last check');
      return null;
    }

    try {
      logger.info('🌐 Fetching latest release from GitHub...');
      final response = await _dio.get(
        _repoUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
        ),
      );

      if (response.statusCode != 200) {
        logger.warning('❌ GitHub API returned status ${response.statusCode}');
        return null;
      }

      final data = response.data;
      final rawTagName = data['tag_name'] as String;
      logger.info('🏷️  GitHub latest release tag:  "$rawTagName"');

      final latestVersionStr = rawTagName.replaceAll('v', '');
      logger.info('🏷️  Latest version (parsed): "$latestVersionStr"');

      final changelog = data['body'] as String;
      final assets = data['assets'] as List;

      String? architecture;
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final abis = androidInfo.supportedAbis;
        logger.debug('📱 Supported ABIs: $abis');

        if (abis.contains('arm64-v8a')) {
          architecture = 'arm64-v8a';
        } else if (abis.contains('armeabi-v7a')) {
          architecture = 'armeabi-v7a';
        }
        logger.info('🏗️  Selected architecture: $architecture');
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
        logger.warning('❌ No matching APK asset found in release');
        return null;
      }

      logger.info(
        '📦 Selected APK: ${apkAsset['name']} for architecture: $architecture',
      );

      final downloadUrl = apkAsset['browser_download_url'] as String;
      final publishedAtStr = data['published_at'] as String?;
      final publishedAt = publishedAtStr != null
          ? DateTime.tryParse(publishedAtStr) ?? DateTime.now()
          : DateTime.now();

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = packageInfo.version;
      logger.info('📱 Current app version (raw): "$currentVersionStr"');

      final currentVersion = Version.parse(
        currentVersionStr.replaceAll('v', ''),
      );
      final latestVersion = Version.parse(latestVersionStr);

      logger.info('🔄 Version comparison:');
      logger.info('   Current: $currentVersion');
      logger.info('   Latest:  $latestVersion');
      logger.info('   Latest > Current? ${latestVersion > currentVersion}');

      await _updateLastCheckTime();

      if (latestVersion > currentVersion) {
        logger.info('✅ Update available!');
        return AppUpdateInfo(
          version: latestVersionStr,
          changelog: changelog,
          downloadUrl: downloadUrl,
          publishedAt: publishedAt,
        );
      } else {
        logger.info('ℹ️  No update needed - app is up to date');
      }
    } catch (e, stack) {
      logger.error('❌ Auto-check update failed', e, stack);
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
