import 'package:apple_foundation_models/apple_foundation_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('apple_foundation_models');
  const models = AppleFoundationModels();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('availability', () {
    test('parses the native availability', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => 'appleIntelligenceNotEnabled',
      );

      expect(
        await models.availability(),
        AppleFoundationModelsAvailability.appleIntelligenceNotEnabled,
      );
    });

    test('maps unknown values to unavailable', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => 'future');

      expect(
        await models.availability(),
        AppleFoundationModelsAvailability.unavailable,
      );
    });

    test('reports unavailable without a native implementation', () async {
      expect(
        await models.availability(),
        AppleFoundationModelsAvailability.unavailable,
      );
    });
  });

  group('respond', () {
    test('sends instructions, prompt and options', () async {
      MethodCall? received;
      messenger.setMockMethodCallHandler(channel, (call) async {
        received = call;
        return 'Resposta';
      });

      final content = await models.respond(
        instructions: 'Seja breve.',
        prompt: 'Olá',
        temperature: 0.3,
        maximumResponseTokens: 200,
      );

      expect(content, 'Resposta');
      expect(received?.method, 'respond');
      expect(received?.arguments, {
        'instructions': 'Seja breve.',
        'prompt': 'Olá',
        'temperature': 0.3,
        'maximumResponseTokens': 200,
      });
    });

    test('maps native error codes', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(
          code: 'context_window_exceeded',
          message: 'Too long',
        );
      });

      await expectLater(
        models.respond(instructions: 'i', prompt: 'p'),
        throwsA(
          isA<AppleFoundationModelsException>()
              .having(
                (e) => e.error,
                'error',
                AppleFoundationModelsError.contextWindowExceeded,
              )
              .having((e) => e.message, 'message', 'Too long'),
        ),
      );
    });

    test('treats unknown native errors as generation failures', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'something_new');
      });

      await expectLater(
        models.respond(instructions: 'i', prompt: 'p'),
        throwsA(
          isA<AppleFoundationModelsException>().having(
            (e) => e.error,
            'error',
            AppleFoundationModelsError.generationFailed,
          ),
        ),
      );
    });

    test('fails as unavailable without a native implementation', () async {
      await expectLater(
        models.respond(instructions: 'i', prompt: 'p'),
        throwsA(
          isA<AppleFoundationModelsException>().having(
            (e) => e.error,
            'error',
            AppleFoundationModelsError.unavailable,
          ),
        ),
      );
    });
  });
}
