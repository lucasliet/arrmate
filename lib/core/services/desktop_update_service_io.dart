import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'desktop_update_failure.dart';
import 'desktop_update_scripts.dart';
import 'logger_service.dart';
import 'update_service.dart';

/// An update fully verified and staged beside the installed application.
class PreparedDesktopUpdate {
  /// Creates the installation plan without modifying the running application.
  const PreparedDesktopUpdate({
    required this.targetPath,
    required this.stagedPath,
    required this.workDirectory,
    required this.platform,
  });

  /// Installed AppImage, application directory, or macOS bundle to replace.
  final String targetPath;

  /// Verified replacement on the same filesystem as the installed application.
  final String stagedPath;

  /// Private staging directory containing the backup and installation log.
  final Directory workDirectory;

  /// Platform whose detached installer will apply the update.
  final TargetPlatform platform;
}

/// Downloads verified release packages and replaces native desktop applications.
class DesktopUpdateService {
  /// Creates the installer; runtime overrides allow isolated filesystem tests.
  DesktopUpdateService({
    Dio? dio,
    TargetPlatform? targetPlatform,
    String? executablePath,
    Map<String, String>? environment,
  }) : _dio = dio ?? Dio(),
       _platform = targetPlatform ?? defaultTargetPlatform,
       _executablePath = executablePath ?? Platform.resolvedExecutable,
       _environment = environment ?? Platform.environment;

  final Dio _dio;
  final TargetPlatform _platform;
  final String _executablePath;
  final Map<String, String> _environment;

  /// Prepares and starts installation, then closes the current application.
  Future<void> installUpdate(
    AppUpdateInfo info, {
    required void Function(int received, int total) onProgress,
    required void Function() onInstalling,
  }) async {
    final plan = await prepareUpdate(info, onProgress: onProgress);
    onInstalling();
    final isWindows = _platform == TargetPlatform.windows;
    final helper = File(
      path.join(
        plan.workDirectory.path,
        isWindows ? 'install.ps1' : 'install.sh',
      ),
    );
    await helper.writeAsString(desktopUpdateScript(_platform), flush: true);
    final cleanEnvironment = Map<String, String>.from(_environment)
      ..remove('APPIMAGE')
      ..remove('APPDIR')
      ..remove('ARGV0')
      ..remove('LD_LIBRARY_PATH')
      ..remove('LD_PRELOAD');
    try {
      await Process.start(
        isWindows ? 'powershell.exe' : '/bin/sh',
        [
          if (isWindows) ...[
            '-NoProfile',
            '-NonInteractive',
            '-WindowStyle',
            'Hidden',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
          ],
          helper.path,
          plan.targetPath,
          plan.stagedPath,
          plan.workDirectory.path,
          '$pid',
          _platform.name,
        ],
        workingDirectory: plan.workDirectory.parent.path,
        environment: cleanEnvironment,
        includeParentEnvironment: false,
        mode: ProcessStartMode.detached,
      );
      final ready = File(path.join(plan.workDirectory.path, 'ready'));
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (!await ready.exists()) {
        if (DateTime.now().isAfter(deadline)) {
          throw DesktopUpdateException(
            DesktopUpdateFailure.installerNotStarted,
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      logger.info(
        '[DesktopUpdate] Installer ready; closing for update ${info.version}',
      );
      exit(0);
    } catch (error, stack) {
      logger.error(
        '[DesktopUpdate] Could not start the installer',
        error,
        stack,
      );
      await File(
        path.join(plan.workDirectory.path, 'cancel'),
      ).writeAsString('cancel');
      // Keep the helper files for diagnosis; the installed application is intact.
      rethrow;
    }
  }

  /// Downloads, verifies, and stages a package without closing or replacing the app.
  Future<PreparedDesktopUpdate> prepareUpdate(
    AppUpdateInfo info, {
    required void Function(int received, int total) onProgress,
  }) async {
    final expectedName = switch (_platform) {
      TargetPlatform.windows => 'arrmate-windows-x64.zip',
      TargetPlatform.linux => 'arrmate-linux-x64.AppImage',
      TargetPlatform.macOS => 'arrmate-macos.zip',
      _ => throw UnsupportedError('This platform has no desktop installer.'),
    };
    final uri = Uri.parse(info.downloadUrl);
    if (info.assetName != expectedName ||
        uri.scheme != 'https' ||
        uri.host != 'github.com' ||
        uri.userInfo.isNotEmpty ||
        uri.path !=
            '/lucasliet/arrmate/releases/download/v${info.version}/$expectedName' ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.port != 443 ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(info.sha256Digest ?? '') ||
        (info.sizeBytes ?? 0) <= 0) {
      throw DesktopUpdateException(DesktopUpdateFailure.unverifiedPackage);
    }
    final target = await _installationPath();
    final parent = Directory(path.dirname(target));
    final Directory work;
    try {
      work = await parent.createTemp('.arrmate-update-');
    } on FileSystemException {
      throw DesktopUpdateException(DesktopUpdateFailure.readOnlyFolder);
    }
    try {
      final download = File(path.join(work.path, expectedName));
      await _dio.download(
        info.downloadUrl,
        download.path,
        onReceiveProgress: onProgress,
        options: Options(receiveTimeout: const Duration(minutes: 10)),
      );
      if (await download.length() != info.sizeBytes ||
          (await sha256.bind(download.openRead()).first).toString() !=
              info.sha256Digest!.toLowerCase()) {
        throw DesktopUpdateException(DesktopUpdateFailure.verificationFailed);
      }
      String staged;
      if (_platform == TargetPlatform.linux) {
        final stream = await download.open();
        final header = await stream.read(20);
        await stream.close();
        if (header.length != 20 ||
            header[0] != 0x7f ||
            header[1] != 0x45 ||
            header[2] != 0x4c ||
            header[3] != 0x46 ||
            header[8] != 0x41 ||
            header[9] != 0x49 ||
            header[10] != 2 ||
            header[18] != 0x3e) {
          throw DesktopUpdateException(DesktopUpdateFailure.notAppImage);
        }
        await _run('chmod', ['755', download.path]);
        staged = download.path;
      } else {
        final input = InputFileStream(download.path);
        try {
          validateDesktopArchive(ZipDecoder().decodeStream(input), _platform);
        } finally {
          await input.close();
        }
        final extracted = await Directory(
          path.join(work.path, 'extracted'),
        ).create();
        if (_platform == TargetPlatform.macOS) {
          await _run('/usr/bin/ditto', [
            '-x',
            '-k',
            download.path,
            extracted.path,
          ]);
          staged = path.join(extracted.path, 'Arrmate.app');
          final result = await _run('/usr/bin/plutil', [
            '-extract',
            'CFBundleShortVersionString',
            'raw',
            '-o',
            '-',
            path.join(staged, 'Contents', 'Info.plist'),
          ]);
          if (result.stdout.toString().trim() != info.version) {
            throw DesktopUpdateException(DesktopUpdateFailure.versionMismatch);
          }
        } else {
          await _run('powershell.exe', [
            '-NoProfile',
            '-NonInteractive',
            '-Command',
            'Expand-Archive -LiteralPath ${_powershellQuote(download.path)} -DestinationPath ${_powershellQuote(extracted.path)}',
          ]);
          staged = extracted.path;
          final version = await _run('powershell.exe', [
            '-NoProfile',
            '-NonInteractive',
            '-Command',
            '(Get-Item -LiteralPath ${_powershellQuote(path.join(staged, 'arrmate.exe'))}).VersionInfo.ProductVersion',
          ]);
          if (version.stdout.toString().trim().split('+').first !=
              info.version) {
            throw DesktopUpdateException(DesktopUpdateFailure.versionMismatch);
          }
        }
      }
      return PreparedDesktopUpdate(
        targetPath: target,
        stagedPath: staged,
        workDirectory: work,
        platform: _platform,
      );
    } catch (error, stack) {
      logger.error('[DesktopUpdate] Package preparation failed', error, stack);
      await work.delete(recursive: true);
      rethrow;
    }
  }

  Future<String> _installationPath() async {
    if (_platform == TargetPlatform.linux) {
      final appImage = _environment['APPIMAGE'];
      if (appImage == null || appImage.isEmpty || !path.isAbsolute(appImage)) {
        throw DesktopUpdateException(
          DesktopUpdateFailure.linuxRequiresAppImage,
        );
      }
      return File(appImage).resolveSymbolicLinks();
    }
    if (_platform == TargetPlatform.windows) {
      final directory = path.dirname(_executablePath);
      if (path.basename(_executablePath).toLowerCase() != 'arrmate.exe' ||
          !await File(path.join(directory, 'flutter_windows.dll')).exists() ||
          !await Directory(
            path.join(directory, 'data', 'flutter_assets'),
          ).exists()) {
        throw DesktopUpdateException(DesktopUpdateFailure.windowsIncomplete);
      }
      return directory;
    }
    final directory = path.dirname(path.dirname(path.dirname(_executablePath)));
    if (!directory.endsWith('.app') ||
        !await File(path.join(directory, 'Contents', 'Info.plist')).exists()) {
      throw DesktopUpdateException(DesktopUpdateFailure.macBundleRequired);
    }
    return directory;
  }

  Future<ProcessResult> _run(String executable, List<String> arguments) async {
    final result = await Process.run(executable, arguments);
    if (result.exitCode != 0) {
      throw DesktopUpdateException(
        DesktopUpdateFailure.prepareFailed,
        executable,
      );
    }
    return result;
  }
}

String _powershellQuote(String value) => "'${value.replaceAll("'", "''")}'";

/// Rejects archive paths and symlinks that could write outside the staging folder.
void validateDesktopArchive(Archive archive, TargetPlatform platform) {
  final names = <String>{};
  final links = <String>{};
  var size = 0;
  for (final file in archive) {
    final name = file.name.replaceAll('\\', '/');
    final normalized = path.posix.normalize(name);
    if (name.startsWith('/') ||
        name.contains(':') ||
        name.contains('\u0000') ||
        name.split('/').contains('..') ||
        (platform == TargetPlatform.windows &&
            name
                .split('/')
                .any(
                  (part) => part.isNotEmpty && RegExp(r'[. ]$').hasMatch(part),
                )) ||
        normalized == '..' ||
        normalized.startsWith('../')) {
      throw DesktopUpdateException(DesktopUpdateFailure.archiveUnsafePath);
    }
    names.add(normalized);
    size += file.size;
    if (size > 2 * 1024 * 1024 * 1024 || archive.length > 50000) {
      throw DesktopUpdateException(DesktopUpdateFailure.archiveTooLarge);
    }
    if (file.isSymbolicLink) {
      final destination = file.symbolicLink!.replaceAll('\\', '/');
      final resolved = path.posix.normalize(
        path.posix.join(path.posix.dirname(normalized), destination),
      );
      if (platform == TargetPlatform.windows ||
          destination.startsWith('/') ||
          destination.contains(':') ||
          resolved == '..' ||
          resolved.startsWith('../')) {
        throw DesktopUpdateException(DesktopUpdateFailure.archiveUnsafeLink);
      }
      links.add(normalized);
    }
  }
  for (final name in names) {
    var parent = path.posix.dirname(name);
    while (parent != '.') {
      if (links.contains(parent)) {
        throw DesktopUpdateException(
          DesktopUpdateFailure.archiveWritesThroughLink,
        );
      }
      parent = path.posix.dirname(parent);
    }
  }
  final requiredFiles = platform == TargetPlatform.windows
      ? [
          'arrmate.exe',
          'flutter_windows.dll',
          'data/flutter_assets/AssetManifest.bin',
        ]
      : [
          'Arrmate.app/Contents/Info.plist',
          'Arrmate.app/Contents/MacOS/Arrmate',
        ];
  if (!requiredFiles.every(names.contains)) {
    throw DesktopUpdateException(DesktopUpdateFailure.archiveMissingFiles);
  }
}
