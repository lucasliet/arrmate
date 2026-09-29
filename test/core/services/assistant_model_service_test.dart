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
  });
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
