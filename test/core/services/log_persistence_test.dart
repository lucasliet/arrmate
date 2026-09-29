import 'dart:io';

import 'package:arrmate/core/services/log_persistence.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp('arrmate-logs-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => documentsDirectory.path,
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await documentsDirectory.delete(recursive: true);
  });

  test('should retain the newest one hundred startup logs', () async {
    final persistence = createLogPersistence();
    for (var index = 0; index < 102; index++) {
      await persistence.append('entry-$index');
    }

    await persistence.initialize();

    final content = await File(
      '${documentsDirectory.path}/app_logs.txt',
    ).readAsLines();
    expect(content.where((line) => line.startsWith('entry-')), [
      for (var index = 2; index < 102; index++) 'entry-$index',
    ]);
  });

  test('should bound and serialize writes after initialization', () async {
    final persistence = createLogPersistence();
    await persistence.initialize();

    final writes = [
      for (var index = 0; index < 150; index++)
        persistence.append('entry-$index'),
    ];
    await Future.wait(writes);

    final content = await File(
      '${documentsDirectory.path}/app_logs.txt',
    ).readAsLines();
    expect(content.where((line) => line.startsWith('entry-')), [
      'entry-0',
      for (var index = 50; index < 150; index++) 'entry-$index',
    ]);
  });
}
