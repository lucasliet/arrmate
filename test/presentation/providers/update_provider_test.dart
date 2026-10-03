import 'dart:async';

import 'package:arrmate/core/services/desktop_update_service.dart';
import 'package:arrmate/core/services/update_service.dart';
import 'package:arrmate/presentation/providers/update_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _UpdateService extends Mock implements UpdateService {}

class _DesktopInstaller extends Mock implements DesktopUpdateService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final info = AppUpdateInfo(
    version: '2.1.0',
    changelog: 'Notes',
    downloadUrl: 'https://github.com/package',
    publishedAt: DateTime(2026),
  );
  setUpAll(() {
    registerFallbackValue(info);
    registerFallbackValue((int received, int total) {});
    registerFallbackValue(() {});
  });
  late _UpdateService service;
  late _DesktopInstaller installer;
  late ProviderContainer container;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    service = _UpdateService();
    installer = _DesktopInstaller();
    container = ProviderContainer(
      overrides: [
        updateServiceProvider.overrideWithValue(service),
        desktopUpdateServiceProvider.overrideWithValue(installer),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    debugDefaultTargetPlatformOverride = null;
  });
  test('check failure is shown as an error rather than up to date', () async {
    when(
      () => service.checkForUpdate(force: true),
    ).thenThrow(StateError('offline'));
    await container.read(updateProvider.notifier).checkForUpdate(force: true);
    expect(container.read(updateProvider).status, UpdateStatus.error);
    expect(
      container.read(updateProvider).errorMessage,
      contains('Could not check'),
    );
  });
  test(
    'desktop installation reports progress, prevents duplicate starts and allows retry after failure',
    () async {
      when(
        () => service.checkForUpdate(force: true),
      ).thenAnswer((_) async => info);
      final finish = Completer<void>();
      when(
        () => installer.installUpdate(
          any(),
          onProgress: any(named: 'onProgress'),
          onInstalling: any(named: 'onInstalling'),
        ),
      ).thenAnswer((invocation) async {
        (invocation.namedArguments[#onProgress] as void Function(int, int))(
          50,
          100,
        );
        await finish.future;
        throw StateError('Cannot write to installation directory');
      });
      final notifier = container.read(updateProvider.notifier);
      await notifier.checkForUpdate(force: true);
      final installing = notifier.startUpdate();
      expect(container.read(updateProvider).status, UpdateStatus.downloading);
      expect(container.read(updateProvider).progress, 50);
      await notifier.startUpdate();
      verify(
        () => installer.installUpdate(
          any(),
          onProgress: any(named: 'onProgress'),
          onInstalling: any(named: 'onInstalling'),
        ),
      ).called(1);
      finish.complete();
      await installing;
      expect(container.read(updateProvider).status, UpdateStatus.error);
      expect(
        container.read(updateProvider).errorMessage,
        contains('Cannot write'),
      );
      when(
        () => installer.installUpdate(
          any(),
          onProgress: any(named: 'onProgress'),
          onInstalling: any(named: 'onInstalling'),
        ),
      ).thenAnswer((invocation) async {
        (invocation.namedArguments[#onInstalling] as void Function())();
      });
      await notifier.startUpdate();
      expect(container.read(updateProvider).status, UpdateStatus.installing);
    },
  );
}
