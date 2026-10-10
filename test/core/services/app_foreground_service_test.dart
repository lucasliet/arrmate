import 'package:arrmate/core/services/app_foreground_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('br.com.lucasliet.arrmate/foreground');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <String>[];

  setUp(() {
    calls.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  void mockChannel(Future<Object?>? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call.method);
          return handler(call);
        });
  }

  group('AppForegroundService', () {
    test('shouldInvokeNativeBringToFront_whenSupported', () async {
      // Given
      mockChannel((call) async => null);
      final service = AppForegroundService(isSupported: true);

      // When
      await service.bringToFront();

      // Then
      expect(calls, ['bringToFront']);
    });

    test('shouldDoNothing_whenPlatformIsNotSupported', () async {
      // Given
      mockChannel((call) async => null);
      final service = AppForegroundService(isSupported: false);

      // When
      await service.bringToFront();

      // Then
      expect(calls, isEmpty);
    });

    test('shouldSwallowPlatformErrors', () async {
      // Given
      mockChannel((call) async => throw PlatformException(code: 'boom'));
      final service = AppForegroundService(isSupported: true);

      // When
      final result = service.bringToFront();

      // Then
      await expectLater(result, completes);
    });

    test('shouldSwallowMissingImplementation', () async {
      // Given
      final service = AppForegroundService(isSupported: true);

      // When
      final result = service.bringToFront();

      // Then
      await expectLater(result, completes);
    });
  });
}
