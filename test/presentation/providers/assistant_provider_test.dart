import 'dart:async';
import 'dart:io';

import 'package:apple_foundation_models/apple_foundation_models.dart';
import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:arrmate/core/services/assistant_apple_intelligence_service.dart';
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

  test('starts online and records Apple Intelligence availability', () {
    expect(state().isLoading, isFalse);
    expect(state().mode, AssistantModelMode.online);
    expect(
      state().appleIntelligenceAvailability,
      AppleFoundationModelsAvailability.available,
    );
  });

  test(
    'keeps the current mode when Apple Intelligence is unavailable',
    () async {
      apple.availability = AppleFoundationModelsAvailability.modelNotReady;

      await notifier().useAppleIntelligence();

      expect(state().mode, AssistantModelMode.online);
      expect(
        state().error,
        AppleFoundationModelsAvailability.modelNotReady.unavailableReason,
      );
    },
  );

  test(
    'a slower cloud selection does not override Apple Intelligence',
    () async {
      final pendingOnline = Completer<AssistantOnlineModelSelection>();
      online.pending = pendingOnline;

      final onlineSelection = notifier().useOnlineMode();
      await notifier().useAppleIntelligence();
      expect(state().mode, AssistantModelMode.appleIntelligence);

      pendingOnline.complete(_onlineSelection);
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

const _onlineSelection = AssistantOnlineModelSelection(
  models: ['test-free'],
  selectedModelId: 'test-free',
);

class _FakeOnlineChatService extends AssistantOnlineChatService {
  Completer<AssistantOnlineModelSelection>? pending;

  @override
  Future<AssistantOnlineModelSelection> initialize() {
    final completer = pending;
    pending = null;
    return completer?.future ?? Future.value(_onlineSelection);
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
