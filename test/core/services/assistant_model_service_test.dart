import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arrmate/core/services/assistant_model_service_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDirectory;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp('arrmate-model-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => supportDirectory.path,
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await supportDirectory.delete(recursive: true);
  });

  group('AssistantModelService download', () {
    test('should preserve an existing model when download fails', () async {
      final model = AssistantModelService.catalog.first;
      final targetDirectory = Directory(
        '${supportDirectory.path}/assistant_models/${model.id}',
      );
      await targetDirectory.create(recursive: true);
      final targetFile = File('${targetDirectory.path}/${model.fileName}');
      await targetFile.writeAsString('existing model');
      final service = AssistantModelService(
        dio: Dio()..httpClientAdapter = _DownloadAdapter(statusCode: 500),
      );

      await expectLater(
        service.downloadModel(model),
        throwsA(isA<DioException>()),
      );

      expect(await targetFile.readAsString(), 'existing model');
      expect(await File('${targetFile.path}.partial').exists(), isFalse);
    });

    test(
      'should replace an existing model after successful download',
      () async {
        final model = AssistantModelService.catalog.first;
        final targetDirectory = Directory(
          '${supportDirectory.path}/assistant_models/${model.id}',
        );
        await targetDirectory.create(recursive: true);
        final targetFile = File('${targetDirectory.path}/${model.fileName}');
        await targetFile.writeAsString('existing model');
        final service = AssistantModelService(
          dio: Dio()..httpClientAdapter = _DownloadAdapter(statusCode: 200),
        );

        final downloaded = await service.downloadModel(model);

        expect(downloaded.path, targetFile.path);
        expect(await targetFile.readAsString(), 'replacement model');
        expect(await File('${targetFile.path}.partial').exists(), isFalse);
      },
    );

    test(
      'should download the same model concurrently without sharing temporary files',
      () async {
        final model = AssistantModelService.catalog.first;
        final targetDirectory = Directory(
          '${supportDirectory.path}/assistant_models/${model.id}',
        );
        final adapter = _OverlappingDownloadAdapter();
        final service = AssistantModelService(
          dio: Dio()..httpClientAdapter = adapter,
        );

        final firstDownload = service.downloadModel(model);
        await adapter.firstResponseStarted.future;
        final firstPartialFile = await _waitForPartialFile(targetDirectory);
        expect(firstPartialFile, isNotNull);

        final secondDownload = await service.downloadModel(model);

        adapter.finishFirstResponse.complete();
        final firstDownloaded = await firstDownload;

        expect(secondDownload.path, firstDownloaded.path);
        expect(
          await File(firstDownloaded.path).readAsString(),
          'first model completed',
        );
        final remainingPartialFiles = await targetDirectory
            .list(recursive: true)
            .where((entity) => entity is File)
            .cast<File>()
            .where((file) => file.path.endsWith('.partial'))
            .toList();
        expect(remainingPartialFiles, isEmpty);
      },
    );
  });
}

Future<File?> _waitForPartialFile(Directory directory) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    final files = await directory
        .list(recursive: true)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();
    for (final file in files) {
      if (file.path.endsWith('.partial')) {
        return file;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return null;
}

class _OverlappingDownloadAdapter implements HttpClientAdapter {
  final Completer<void> firstResponseStarted = Completer<void>();
  final Completer<void> finishFirstResponse = Completer<void>();
  var _requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _requestCount++;
    if (_requestCount == 1) {
      return ResponseBody(_firstResponse(), 200);
    }
    return ResponseBody.fromString('second model', 200);
  }

  Stream<Uint8List> _firstResponse() async* {
    firstResponseStarted.complete();
    yield Uint8List.fromList(utf8.encode('first model'));
    await finishFirstResponse.future;
    yield Uint8List.fromList(utf8.encode(' completed'));
  }

  @override
  void close({bool force = false}) {}
}

class _DownloadAdapter implements HttpClientAdapter {
  _DownloadAdapter({required this.statusCode});

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('replacement model', statusCode);

  @override
  void close({bool force = false}) {}
}
