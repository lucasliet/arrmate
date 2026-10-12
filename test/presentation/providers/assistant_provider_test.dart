import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:apple_foundation_models/apple_foundation_models.dart';
import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:arrmate/core/services/assistant_apple_intelligence_service.dart';
import 'package:arrmate/core/services/assistant_knowledge_service.dart';
import 'package:arrmate/core/services/assistant_online_chat_service.dart';
import 'package:arrmate/presentation/providers/assistant_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Directory supportDirectory;
  late _FakeOnlineChatService online;
  late _FakeAppleIntelligenceService apple;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    supportDirectory = await Directory.systemTemp.createTemp('arrmate-ai-');
    messenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => supportDirectory.path,
    );
    online = _FakeOnlineChatService();
    apple = _FakeAppleIntelligenceService();
    container = ProviderContainer(
      overrides: [
        platformCapabilitiesProvider.overrideWithValue(
          PlatformCapabilities.forPlatform(
            isWeb: false,
            targetPlatform: TargetPlatform.iOS,
          ),
        ),
        assistantProvider.overrideWith(
          () => AssistantNotifier(
            onlineChatService: online,
            appleIntelligenceService: apple,
          ),
        ),
      ],
    );
    container.read(assistantProvider);
    for (
      var i = 0;
      i < 100 && container.read(assistantProvider).isLoading;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });

  tearDown(() async {
    container.dispose();
    messenger.setMockMethodCallHandler(pathProviderChannel, null);
    await supportDirectory.delete(recursive: true);
  });

  AssistantState state() => container.read(assistantProvider);
  AssistantNotifier notifier() => container.read(assistantProvider.notifier);

  /// Creates a container over the shared fakes with [preferences] seeded,
  /// used by tests that need persisted state before the first build.
  Future<ProviderContainer> pumpAssistant({
    Map<String, Object> preferences = const {},
  }) async {
    SharedPreferences.setMockInitialValues(preferences);
    final seeded = ProviderContainer(
      overrides: [
        platformCapabilitiesProvider.overrideWithValue(
          PlatformCapabilities.forPlatform(
            isWeb: false,
            targetPlatform: TargetPlatform.iOS,
          ),
        ),
        assistantProvider.overrideWith(
          () => AssistantNotifier(
            onlineChatService: online,
            appleIntelligenceService: apple,
          ),
        ),
      ],
    );
    addTearDown(seeded.dispose);
    seeded.read(assistantProvider);
    for (var i = 0; i < 100 && seeded.read(assistantProvider).isLoading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return seeded;
  }

  test(
    'pre-selects Apple Intelligence when available and nothing was persisted',
    () {
      expect(state().isLoading, isFalse);
      expect(state().mode, AssistantModelMode.appleIntelligence);
      expect(
        state().appleIntelligenceAvailability,
        AppleFoundationModelsAvailability.available,
      );
    },
  );

  test(
    'stays online when Apple Intelligence is unavailable at startup',
    () async {
      apple.availability = AppleFoundationModelsAvailability.modelNotReady;

      final seeded = await pumpAssistant();

      expect(seeded.read(assistantProvider).mode, AssistantModelMode.online);
    },
  );

  test(
    'keeps the persisted cloud choice even when Apple Intelligence is available',
    () async {
      final seeded = await pumpAssistant(
        preferences: {'assistant_selected_mode': 'online'},
      );

      expect(seeded.read(assistantProvider).mode, AssistantModelMode.online);
    },
  );

  test(
    'falls back to online when the persisted Apple choice is unavailable',
    () async {
      apple.availability = AppleFoundationModelsAvailability.modelNotReady;

      final seeded = await pumpAssistant(
        preferences: {'assistant_selected_mode': 'appleIntelligence'},
      );

      expect(seeded.read(assistantProvider).mode, AssistantModelMode.online);
    },
  );

  test('restores the persisted local model selection', () async {
    final modelFile = File(
      '${supportDirectory.path}/assistant_models/gemma4_e2b/gemma-4-E2B-it.litertlm',
    );
    await modelFile.create(recursive: true);
    await modelFile.writeAsBytes([0]);
    final modelId = base64Url
        .encode(utf8.encode(modelFile.path))
        .replaceAll('=', '')
        .toLowerCase();

    final seeded = await pumpAssistant(
      preferences: <String, Object>{
        'assistant_selected_mode': 'local',
        'assistant_selected_model_id': modelId,
      },
    );

    final restored = seeded.read(assistantProvider);
    expect(restored.mode, AssistantModelMode.local);
    expect(restored.selectedModelId, modelId);
    expect(restored.selectedModelPath, modelFile.path);
  });

  test(
    'persists the Apple Intelligence choice when the user selects it',
    () async {
      await notifier().useAppleIntelligence();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('assistant_selected_mode'), 'appleIntelligence');
    },
  );

  test(
    'persists the cloud choice when the user switches to online mode',
    () async {
      await notifier().useOnlineMode();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('assistant_selected_mode'), 'online');
    },
  );

  test(
    'keeps the current mode when Apple Intelligence is unavailable',
    () async {
      final seeded = await pumpAssistant(
        preferences: {'assistant_selected_mode': 'online'},
      );

      apple.availability = AppleFoundationModelsAvailability.modelNotReady;
      await seeded.read(assistantProvider.notifier).useAppleIntelligence();

      expect(seeded.read(assistantProvider).mode, AssistantModelMode.online);
      expect(
        seeded.read(assistantProvider).error,
        AppleFoundationModelsAvailability.modelNotReady.unavailableReason,
      );
    },
  );

  test(
    'does not persist a mode switch that Apple Intelligence refused',
    () async {
      apple.availability = AppleFoundationModelsAvailability.modelNotReady;

      await notifier().useAppleIntelligence();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('assistant_selected_mode'), isNull);
    },
  );

  test('answers through the cloud without needing a model selection', () async {
    await notifier().useOnlineMode();

    await notifier().sendMessage('Como adiciono uma instância?');

    expect(state().hasModel, isTrue);
    expect(state().isGenerating, isFalse);
    expect(state().messages.map((message) => message.content), [
      'Como adiciono uma instância?',
      'Cloud reply',
    ]);
  });

  test(
    'a slower cloud selection does not override Apple Intelligence',
    () async {
      final onlineSelection = notifier().useOnlineMode();
      await notifier().useAppleIntelligence();
      expect(state().mode, AssistantModelMode.appleIntelligence);

      await onlineSelection;

      expect(state().mode, AssistantModelMode.appleIntelligence);
    },
  );

  test(
    'a slower Apple Intelligence check does not override the cloud',
    () async {
      final pendingApple = Completer<AppleFoundationModelsAvailability>();
      apple.pending = pendingApple;

      final appleSelection = notifier().useAppleIntelligence();
      await notifier().useOnlineMode();
      expect(state().mode, AssistantModelMode.online);

      pendingApple.complete(AppleFoundationModelsAvailability.available);
      await appleSelection;

      expect(state().mode, AssistantModelMode.online);
    },
  );
}

class _FakeOnlineChatService extends AssistantOnlineChatService {
  @override
  Future<AssistantOnlineChatResult> sendMessage(
    List<AssistantOnlineChatMessage> history,
    AssistantKnowledgeService knowledgeService,
  ) async {
    return const AssistantOnlineChatResult(content: 'Cloud reply');
  }
}

class _FakeAppleIntelligenceService extends AssistantAppleIntelligenceService {
  AppleFoundationModelsAvailability availability =
      AppleFoundationModelsAvailability.available;
  Completer<AppleFoundationModelsAvailability>? pending;

  @override
  Future<AppleFoundationModelsAvailability> checkAvailability() {
    final completer = pending;
    pending = null;
    return completer?.future ?? Future.value(availability);
  }
}
