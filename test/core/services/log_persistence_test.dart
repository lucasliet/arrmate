import 'dart:io';

import 'package:arrmate/core/services/log_persistence.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('should retain the newest one hundred startup logs', () async {
    final documentsDirectory = await Directory.systemTemp.createTemp(
      'arrmate-logs-',
    );
    addTearDown(() => documentsDirectory.delete(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => documentsDirectory.path,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          ),
    );
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
}
