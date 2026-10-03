import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:arrmate/core/services/desktop_update_scripts.dart';
import 'package:arrmate/core/services/desktop_update_service_io.dart';
import 'package:arrmate/core/services/update_service.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

class _DownloadAdapter implements HttpClientAdapter {
  _DownloadAdapter(this.bytes);
  final List<int> bytes;
  int requests = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentLengthHeader: ['${bytes.length}'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('arrmate update ');
    root = Directory(await root.resolveSymbolicLinks());
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  group('verified AppImage preparation', () {
    final bytes = List<int>.filled(64, 0)
      ..setRange(0, 4, [0x7f, 0x45, 0x4c, 0x46])
      ..setRange(8, 11, [0x41, 0x49, 2])
      ..setRange(18, 20, [0x3e, 0]);
    AppUpdateInfo info({
      String? digest,
      String? url,
      String? name,
    }) => AppUpdateInfo(
      version: '2.1.0',
      changelog: 'Notes',
      publishedAt: DateTime(2026),
      assetName: name ?? 'arrmate-linux-x64.AppImage',
      downloadUrl:
          url ??
          'https://github.com/lucasliet/arrmate/releases/download/v2.1.0/arrmate-linux-x64.AppImage',
      sizeBytes: bytes.length,
      sha256Digest: digest ?? sha256.convert(bytes).toString(),
    );
    test(
      'stages beside the actual AppImage and preserves the installed file',
      () async {
        final installed = File(
          path.join(root.path, "old ' \$ Arrmate.AppImage"),
        );
        await installed.writeAsString('previous version');
        final adapter = _DownloadAdapter(bytes);
        final dio = Dio()..httpClientAdapter = adapter;
        final service = DesktopUpdateService(
          dio: dio,
          targetPlatform: TargetPlatform.linux,
          executablePath: '/tmp/.mount_123/usr/bin/arrmate',
          environment: {'APPIMAGE': installed.path},
        );
        var received = 0;
        final plan = await service.prepareUpdate(
          info(),
          onProgress: (count, total) => received = count,
        );
        expect(plan.targetPath, installed.path);
        expect(plan.workDirectory.parent.path, root.path);
        expect(await installed.readAsString(), 'previous version');
        expect(await File(plan.stagedPath).readAsBytes(), bytes);
        expect((await File(plan.stagedPath).stat()).mode & 0x49, 0x49);
        expect(received, bytes.length);
        expect(adapter.requests, 1);
      },
      skip: Platform.isWindows,
    );
    test(
      'checksum failure cleans staging and leaves the app untouched',
      () async {
        final installed = File(path.join(root.path, 'Arrmate.AppImage'));
        await installed.writeAsString('previous version');
        final service = DesktopUpdateService(
          dio: Dio()..httpClientAdapter = _DownloadAdapter(bytes),
          targetPlatform: TargetPlatform.linux,
          environment: {'APPIMAGE': installed.path},
        );
        await expectLater(
          service.prepareUpdate(
            info(digest: '0' * 64),
            onProgress: (_, total) {},
          ),
          throwsStateError,
        );
        expect(await installed.readAsString(), 'previous version');
        expect(await root.list().length, 1);
      },
    );
    test('rejects a foreign download host before making a request', () async {
      final adapter = _DownloadAdapter(bytes);
      final service = DesktopUpdateService(
        dio: Dio()..httpClientAdapter = adapter,
        targetPlatform: TargetPlatform.linux,
      );
      await expectLater(
        service.prepareUpdate(
          info(url: 'https://example.org/package'),
          onProgress: (_, total) {},
        ),
        throwsStateError,
      );
      expect(adapter.requests, 0);
    });
    test(
      'rejects a bare Linux bundle instead of replacing its temporary executable',
      () async {
        final adapter = _DownloadAdapter(bytes);
        final service = DesktopUpdateService(
          dio: Dio()..httpClientAdapter = adapter,
          targetPlatform: TargetPlatform.linux,
          executablePath: '/tmp/bundle/arrmate',
          environment: {},
        );
        await expectLater(
          service.prepareUpdate(info(), onProgress: (_, total) {}),
          throwsStateError,
        );
        expect(adapter.requests, 0);
      },
    );
  });

  group('safe bundle archives', () {
    Archive windowsArchive() => Archive()
      ..add(ArchiveFile.string('arrmate.exe', 'MZ'))
      ..add(ArchiveFile.string('flutter_windows.dll', 'MZ'))
      ..add(
        ArchiveFile.string('data/flutter_assets/AssetManifest.bin', 'manifest'),
      );
    test('accepts a complete Windows bundle', () {
      validateDesktopArchive(windowsArchive(), TargetPlatform.windows);
    });
    for (final name in [
      '../outside',
      '/absolute',
      r'C:\outside',
      r'data\..\..\outside',
      'data/file:stream',
    ]) {
      test('rejects escaping path $name', () {
        final archive = windowsArchive()..add(ArchiveFile.string(name, 'bad'));
        expect(
          () => validateDesktopArchive(archive, TargetPlatform.windows),
          throwsStateError,
        );
      });
    }
    test('rejects incomplete bundles', () {
      expect(
        () => validateDesktopArchive(
          Archive()..add(ArchiveFile.string('arrmate.exe', 'MZ')),
          TargetPlatform.windows,
        ),
        throwsStateError,
      );
    });
    test('accepts internal macOS framework links', () {
      final archive = Archive()
        ..add(ArchiveFile.string('Arrmate.app/Contents/Info.plist', 'plist'))
        ..add(ArchiveFile.string('Arrmate.app/Contents/MacOS/Arrmate', 'app'))
        ..add(
          ArchiveFile.string(
            'Arrmate.app/Contents/Frameworks/F.framework/Versions/A/F',
            'framework',
          ),
        )
        ..add(
          ArchiveFile.symlink(
            'Arrmate.app/Contents/Frameworks/F.framework/Versions/Current',
            'A',
          ),
        );
      validateDesktopArchive(archive, TargetPlatform.macOS);
      archive.add(
        ArchiveFile.string(
          'Arrmate.app/Contents/Frameworks/F.framework/Versions/Current/injected',
          'bad',
        ),
      );
      expect(
        () => validateDesktopArchive(archive, TargetPlatform.macOS),
        throwsStateError,
      );
    });
    test('rejects escaping symlinks', () {
      final archive = windowsArchive()
        ..add(ArchiveFile.symlink('data/link', '../../../outside'));
      expect(
        () => validateDesktopArchive(archive, TargetPlatform.macOS),
        throwsStateError,
      );
    });
  });

  test(
    'native ZIP extraction verifies metadata and stages a complete bundle',
    () async {
      final platform = Platform.isWindows
          ? TargetPlatform.windows
          : TargetPlatform.macOS;
      final name = Platform.isWindows
          ? 'arrmate-windows-x64.zip'
          : 'arrmate-macos.zip';
      final archive = Archive();
      final installed = await Directory(
        path.join(root.path, "installed ' usuário"),
      ).create();
      final String executable;
      if (Platform.isWindows) {
        final source = File(path.join(root.path, 'version_fixture.cs'));
        final binary = File(path.join(root.path, 'version_fixture.exe'));
        await source.writeAsString(
          'using System.Reflection; [assembly: AssemblyInformationalVersion("2.1.0+71")] public class Fixture { public static void Main() {} }',
        );
        final compiled = await Process.run('powershell.exe', [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          "Add-Type -Path '${source.path.replaceAll("'", "''")}' -OutputAssembly '${binary.path.replaceAll("'", "''")}' -OutputType ConsoleApplication",
        ]);
        expect(compiled.exitCode, 0, reason: '${compiled.stderr}');
        archive.add(
          ArchiveFile.bytes('arrmate.exe', await binary.readAsBytes()),
        );
        archive.add(ArchiveFile.string('flutter_windows.dll', 'MZ'));
        archive.add(
          ArchiveFile.string(
            'data/flutter_assets/AssetManifest.bin',
            'manifest',
          ),
        );
        await Directory(
          path.join(installed.path, 'data', 'flutter_assets'),
        ).create(recursive: true);
        await File(
          path.join(installed.path, 'flutter_windows.dll'),
        ).writeAsString('old library');
        executable = path.join(installed.path, 'arrmate.exe');
      } else {
        archive.add(
          ArchiveFile.string(
            'Arrmate.app/Contents/Info.plist',
            '<?xml version="1.0"?><plist version="1.0"><dict><key>CFBundleShortVersionString</key><string>2.1.0</string></dict></plist>',
          ),
        );
        archive.add(
          ArchiveFile.string(
            'Arrmate.app/Contents/MacOS/Arrmate',
            'new application',
          ),
        );
        executable = path.join(
          installed.path,
          'Arrmate.app',
          'Contents',
          'MacOS',
          'Arrmate',
        );
        await File(executable).parent.create(recursive: true);
        await File(
          path.join(installed.path, 'Arrmate.app', 'Contents', 'Info.plist'),
        ).writeAsString('old plist');
      }
      await File(executable).writeAsString('previous application');
      final bytes = ZipEncoder().encode(archive);
      final service = DesktopUpdateService(
        dio: Dio()..httpClientAdapter = _DownloadAdapter(bytes),
        targetPlatform: platform,
        executablePath: executable,
      );
      final info = AppUpdateInfo(
        version: '2.1.0',
        changelog: 'Notes',
        publishedAt: DateTime(2026),
        downloadUrl:
            'https://github.com/lucasliet/arrmate/releases/download/v2.1.0/$name',
        assetName: name,
        sizeBytes: bytes.length,
        sha256Digest: sha256.convert(bytes).toString(),
      );
      final plan = await service.prepareUpdate(info, onProgress: (_, total) {});
      expect(await File(executable).readAsString(), 'previous application');
      expect(
        await FileSystemEntity.type(plan.stagedPath),
        FileSystemEntityType.directory,
      );
      expect(plan.workDirectory.parent.path, path.dirname(plan.targetPath));
      final wrongVersion = AppUpdateInfo(
        version: '2.2.0',
        changelog: info.changelog,
        publishedAt: info.publishedAt,
        downloadUrl: info.downloadUrl.replaceFirst('/v2.1.0/', '/v2.2.0/'),
        assetName: info.assetName,
        sizeBytes: info.sizeBytes,
        sha256Digest: info.sha256Digest,
      );
      await expectLater(
        service.prepareUpdate(wrongVersion, onProgress: (_, total) {}),
        throwsStateError,
      );
      expect(await File(executable).readAsString(), 'previous application');
    },
    skip: Platform.isLinux,
  );

  group('native detached installer', () {
    final platform = Platform.isWindows
        ? TargetPlatform.windows
        : Platform.isMacOS
        ? TargetPlatform.macOS
        : TargetPlatform.linux;
    final children = <int>[];
    var installerDiagnostics = '';
    tearDown(() async {
      for (final processId in children) {
        Process.killPid(processId);
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      children.clear();
    });
    Future<String> makeApp(
      String directory,
      String label,
      File marker, {
      bool broken = false,
    }) async {
      if (platform == TargetPlatform.linux) {
        final file = File(path.join(directory, 'Arrmate.AppImage'));
        await file.parent.create(recursive: true);
        await file.writeAsString(
          broken
              ? '#!/bin/sh\nexit 1\n'
              : '#!/bin/sh\nprintf "$label %s" "\$\$" > "\$ARRMATE_TEST_MARKER"\nexec sleep 30\n',
        );
        await Process.run('chmod', ['755', file.path]);
        return file.path;
      }
      final appDirectory = platform == TargetPlatform.macOS
          ? path.join(directory, 'Arrmate.app')
          : directory;
      final binary = File(
        platform == TargetPlatform.macOS
            ? path.join(appDirectory, 'Contents', 'MacOS', 'Arrmate')
            : path.join(appDirectory, 'arrmate.exe'),
      );
      await binary.parent.create(recursive: true);
      if (platform == TargetPlatform.windows) {
        final source = File(path.join(directory, 'fixture.cs'));
        await source.writeAsString(
          'using System; using System.IO; using System.Threading; using System.Diagnostics; public class Fixture { public static void Main() { File.WriteAllText(Environment.GetEnvironmentVariable("ARRMATE_TEST_MARKER"), "$label " + Process.GetCurrentProcess().Id); Thread.Sleep(30000); } }',
        );
        final result = await Process.run('powershell.exe', [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          "Add-Type -Path '${source.path.replaceAll("'", "''")}' -OutputAssembly '${binary.path.replaceAll("'", "''")}' -OutputType ConsoleApplication",
        ]);
        expect(result.exitCode, 0, reason: '${result.stderr}');
      } else {
        final source = File(path.join(directory, 'fixture.c'));
        await source.writeAsString(
          '#include <stdio.h>\n#include <unistd.h>\nint main() { FILE *f=fopen(${jsonEncode(marker.path)}, "w"); fprintf(f, "$label %d", getpid()); fclose(f); sleep(30); return 0; }\n',
        );
        final result = await Process.run('cc', [
          source.path,
          '-o',
          binary.path,
        ]);
        expect(result.exitCode, 0, reason: '${result.stderr}');
        await File(
          path.join(appDirectory, 'Contents', 'Info.plist'),
        ).writeAsString(
          '<?xml version="1.0"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleExecutable</key><string>Arrmate</string><key>CFBundleIdentifier</key><string>br.com.lucasliet.arrmate.updater.fixture</string><key>CFBundlePackageType</key><string>APPL</string></dict></plist>',
        );
        final signing = await Process.run('/usr/bin/codesign', [
          '--force',
          '--sign',
          '-',
          '--generate-entitlement-der',
          '--entitlements',
          path.absolute('macos', 'Runner', 'Release.entitlements'),
          appDirectory,
        ]);
        expect(signing.exitCode, 0, reason: '${signing.stderr}');
      }
      return appDirectory;
    }

    Future<ProcessResult> runHelper(
      String target,
      String staged,
      Directory work,
      File marker, {
      int parentPid = 2147483647,
    }) async {
      final helper = File(
        path.join(
          work.path,
          platform == TargetPlatform.windows ? 'install.ps1' : 'install.sh',
        ),
      );
      await helper.writeAsString(desktopUpdateScript(platform));
      final result = await Process.run(
        platform == TargetPlatform.windows ? 'powershell.exe' : '/bin/sh',
        [
          if (platform == TargetPlatform.windows) ...[
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
          ],
          helper.path,
          target,
          staged,
          work.path,
          '$parentPid',
          platform.name,
        ],
        environment: {'ARRMATE_TEST_MARKER': marker.path},
      ).timeout(const Duration(seconds: 45));
      final log = File(path.join(work.path, 'install.log'));
      installerDiagnostics = await log.exists() ? await log.readAsString() : '';
      return ProcessResult(
        result.pid,
        result.exitCode,
        result.stdout,
        '${result.stderr}\n$installerDiagnostics',
      );
    }

    Future<String> launchedVersion(File marker) async {
      for (var attempt = 0; attempt < 100; attempt++) {
        if (await marker.exists() && (await marker.length()) > 0) {
          final value = await marker.readAsString();
          children.add(int.parse(value.split(' ').last));
          return value.split(' ').first;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      fail(
        'The installer did not restart the application. $installerDiagnostics',
      );
    }

    test(
      'replaces the complete application and restarts it from paths with spaces and quotes',
      () async {
        final marker = File(path.join(root.path, 'launched'));
        final installed = await makeApp(
          path.join(root.path, "installed ' \$ usuário"),
          'old',
          marker,
        );
        final work = await Directory(path.join(root.path, 'work')).create();
        final staged = await makeApp(
          path.join(work.path, 'new'),
          'new',
          marker,
        );
        final result = await runHelper(installed, staged, work, marker);
        expect(result.exitCode, 0, reason: '${result.stderr} ${result.stdout}');
        expect(await launchedVersion(marker), 'new');
        expect(await work.exists(), isFalse);
        expect(
          await FileSystemEntity.type(installed),
          isNot(FileSystemEntityType.notFound),
        );
      },
    );
    test(
      'restores and restarts the previous version when replacement fails',
      () async {
        final marker = File(path.join(root.path, 'launched'));
        final installed = await makeApp(
          path.join(root.path, 'installed'),
          'old',
          marker,
        );
        final work = await Directory(path.join(root.path, 'work')).create();
        final result = await runHelper(
          installed,
          path.join(work.path, 'missing'),
          work,
          marker,
        );
        expect(result.exitCode, 1);
        expect(await launchedVersion(marker), 'old');
        expect(
          await File(path.join(work.path, 'install.log')).exists(),
          isTrue,
        );
        expect(
          await FileSystemEntity.type(installed),
          isNot(FileSystemEntityType.notFound),
        );
      },
    );
    test(
      'leaves the running application intact until its process exits',
      () async {
        final marker = File(path.join(root.path, 'launched'));
        final installed = await makeApp(
          path.join(root.path, 'installed'),
          'old',
          marker,
        );
        final work = await Directory(path.join(root.path, 'work')).create();
        final staged = await makeApp(
          path.join(work.path, 'new'),
          'new',
          marker,
        );
        final parent = await Process.start(
          Platform.isWindows ? 'powershell.exe' : '/bin/sleep',
          Platform.isWindows
              ? [
                  '-NoProfile',
                  '-NonInteractive',
                  '-Command',
                  'Start-Sleep -Seconds 30',
                ]
              : ['30'],
        );
        final installing = runHelper(
          installed,
          staged,
          work,
          marker,
          parentPid: parent.pid,
        );
        try {
          final ready = File(path.join(work.path, 'ready'));
          for (
            var attempt = 0;
            attempt < 100 && !await ready.exists();
            attempt++
          ) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
          expect(await ready.exists(), isTrue);
          expect(await marker.exists(), isFalse);
          expect(
            await FileSystemEntity.type(installed),
            isNot(FileSystemEntityType.notFound),
          );
        } finally {
          parent.kill();
          await parent.exitCode;
        }
        final result = await installing;
        expect(result.exitCode, 0, reason: '${result.stderr}');
        expect(await launchedVersion(marker), 'new');
      },
    );
    test('a cancelled helper never changes the application', () async {
      final marker = File(path.join(root.path, 'launched'));
      final installed = await makeApp(
        path.join(root.path, 'installed'),
        'old',
        marker,
      );
      final work = await Directory(path.join(root.path, 'work')).create();
      final staged = await makeApp(path.join(work.path, 'new'), 'new', marker);
      await File(path.join(work.path, 'cancel')).writeAsString('cancel');
      final result = await runHelper(installed, staged, work, marker);
      expect(result.exitCode, 1);
      expect(await marker.exists(), isFalse);
      expect(
        await FileSystemEntity.type(staged),
        isNot(FileSystemEntityType.notFound),
      );
      expect(
        await FileSystemEntity.type(installed),
        isNot(FileSystemEntityType.notFound),
      );
    });
    test(
      'recovers when the new AppImage immediately fails to start',
      () async {
        final marker = File(path.join(root.path, 'launched'));
        final installed = await makeApp(
          path.join(root.path, 'installed'),
          'old',
          marker,
        );
        final work = await Directory(path.join(root.path, 'work')).create();
        final staged = await makeApp(
          path.join(work.path, 'new'),
          'new',
          marker,
          broken: true,
        );
        final result = await runHelper(installed, staged, work, marker);
        expect(result.exitCode, 1);
        expect(await launchedVersion(marker), 'old');
      },
      skip: !Platform.isLinux,
    );
  });
}
