import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/advanced_providers.dart';
import 'package:arrmate/presentation/screens/settings/logs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> platformCalls;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    platformCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  String copiedText() {
    final call = platformCalls.lastWhere(
      (call) => call.method == 'Clipboard.setData',
    );
    return (call.arguments as Map)['text'] as String;
  }

  group('Log copy', () {
    testWidgets('should copy the exception along with the message', (
      tester,
    ) async {
      // Given
      // The exception is the half worth pasting into a bug report, and the
      // button used to leave it behind on the screen.
      await tester.pumpWidget(_app(_page([_failure])));
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();

      // Then
      expect(
        copiedText(),
        '[${_failure.time.toLocal()}] Error (ManualImportService): '
        '${_failure.message}\n${_failure.exception}',
      );
    });

    testWidgets('should copy every exception when copying all logs', (
      tester,
    ) async {
      // Given
      await tester.pumpWidget(_app(_page([_failure, _secondFailure])));
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.byIcon(Icons.copy_all));
      await tester.pumpAndSettle();

      // Then
      final copied = copiedText();
      expect(copied, contains(_failure.exception));
      expect(copied, contains(_secondFailure.exception));
    });

    testWidgets('should copy an entry that carries no exception', (
      tester,
    ) async {
      // Given
      await tester.pumpWidget(_app(_page([_plain])));
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();

      // Then
      expect(
        copiedText(),
        '[${_plain.time.toLocal()}] Info (Api): ${_plain.message}',
      );
    });
  });
}

final _failure = LogEntry(
  time: DateTime.utc(2026, 9, 1, 12),
  level: 'Error',
  logger: 'ManualImportService',
  message: 'Error occurred while executing task ManualImport',
  exception:
      'NzbDrone.Core.Datastore.ModelNotFoundException: '
      'Movie with ID 0 does not exist',
);

final _secondFailure = LogEntry(
  time: DateTime.utc(2026, 9, 1, 13),
  level: 'Error',
  logger: 'DownloadService',
  message: 'Error occurred while executing task CheckForFinishedDownload',
  exception: 'System.Net.WebException: Unable to connect to the remote server',
);

final _plain = LogEntry(
  time: DateTime.utc(2026, 9, 1, 14),
  level: 'Info',
  logger: 'Api',
  message: 'Import completed',
);

LogPage _page(List<LogEntry> records) {
  return LogPage(
    page: 1,
    pageSize: 50,
    totalRecords: records.length,
    records: records,
  );
}

Widget _app(LogPage logPage) {
  return ProviderScope(
    overrides: [
      arrLogInstancesProvider.overrideWithValue([
        Instance(
          id: 'radarr',
          type: InstanceType.radarr,
          label: 'Radarr',
          url: 'https://radarr.example.com',
          apiKey: 'key',
        ),
      ]),
      arrLogLoaderProvider.overrideWithValue(({int page = 1}) async => logPage),
      appLogsProvider.overrideWith((ref) => Stream.value(const [])),
    ],
    child: const MaterialApp(home: LogsScreen()),
  );
}
