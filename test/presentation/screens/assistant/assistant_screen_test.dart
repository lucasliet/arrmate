import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:arrmate/core/services/assistant_model_service.dart';
import 'package:arrmate/core/services/assistant_online_chat_service.dart';
import 'package:arrmate/presentation/providers/assistant_provider.dart';
import 'package:arrmate/presentation/screens/assistant/assistant_screen.dart';
import 'package:arrmate/presentation/theme/app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _AssistantNotifier extends AssistantNotifier {
  _AssistantNotifier({this.onlineModels = const [], this.isGenerating = false});

  final List<String> onlineModels;
  final bool isGenerating;
  String? lastSelectedOnlineModel;
  String? lastMessage;

  @override
  AssistantState build() => AssistantState(
    isLoading: false,
    isGenerating: isGenerating,
    selectedOnlineModelId: AssistantOnlineChatService.defaultModelId,
    onlineModels: onlineModels,
    installedModels: [
      AssistantInstalledModel(
        id: 'local-model',
        label: 'Local model',
        path: '/model.litertlm',
        source: 'import',
        sizeBytes: 1,
        modifiedAt: DateTime(2026),
      ),
    ],
  );

  @override
  Future<void> selectOnlineModel(String modelId) async {
    lastSelectedOnlineModel = modelId;
  }

  @override
  Future<void> sendMessage(String content) async {
    lastMessage = content;
  }
}

Widget _assistantApp(
  PlatformCapabilities capabilities, {
  _AssistantNotifier? notifier,
}) {
  final effectiveNotifier = notifier ?? _AssistantNotifier();

  return ProviderScope(
    overrides: [
      assistantProvider.overrideWith(() => effectiveNotifier),
      platformCapabilitiesProvider.overrideWithValue(capabilities),
    ],
    child: MaterialApp(
      theme: AppTheme.light(AppColorScheme.blue),
      home: const AssistantScreen(),
    ),
  );
}

void main() {
  for (final platform in [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    testWidgets(
      'wide native $platform retains capabilities and keyboard draft',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1600, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final notifier = _AssistantNotifier();
        final capabilities = PlatformCapabilities.forPlatform(
          isWeb: false,
          targetPlatform: platform,
        );
        await tester.pumpWidget(
          _assistantApp(capabilities, notifier: notifier),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(TextField)).width,
          lessThanOrEqualTo(900),
        );
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        expect(find.text('Online Models'), findsOneWidget);
        expect(
          find.text('Import'),
          platform == TargetPlatform.android ? findsOneWidget : findsNothing,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Online Models'), findsNothing);
        await tester.enterText(
          find.byType(TextField),
          'Native online question',
        );
        await tester.binding.setSurfaceSize(const Size(500, 800));
        await tester.pumpAndSettle();
        expect(find.text('Native online question'), findsOneWidget);
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pumpAndSettle();
        expect(notifier.lastMessage, 'Native online question');
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('keyboard submission preserves draft while generating', (
    tester,
  ) async {
    final notifier = _AssistantNotifier(isGenerating: true);
    await tester.pumpWidget(
      _assistantApp(
        PlatformCapabilities.forPlatform(
          isWeb: false,
          targetPlatform: TargetPlatform.linux,
        ),
        notifier: notifier,
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Next question');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(notifier.lastMessage, isNull);
    expect(find.text('Next question'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'desktop model sheet is bounded, scrolls with wheel, and closes with Escape',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _assistantApp(
          PlatformCapabilities.forPlatform(
            isWeb: false,
            targetPlatform: TargetPlatform.linux,
          ),
          notifier: _AssistantNotifier(
            onlineModels: List.generate(40, (index) => 'native-model-$index'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Online Models'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(ListView)).width, 720);
      final list = find.byType(ListView);
      final scrollable = find.descendant(
        of: list,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(list),
          scrollDelta: const Offset(0, 200),
        ),
      );
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps online options when local assistant is unsupported', (
    tester,
  ) async {
    await tester.pumpWidget(
      _assistantApp(
        const PlatformCapabilities(
          isWeb: true,
          supportsAppUpdates: false,
          supportsBackgroundNotifications: false,
          supportsLocalAssistant: false,
          supportsFileSystemCache: false,
          supportsBrowserFileInput: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('OpenCode Zen'), findsNWidgets(2));
    expect(find.text('Online Models'), findsOneWidget);
    expect(find.text('Download'), findsNothing);
    expect(find.text('Import'), findsNothing);
    expect(find.text('Local Models'), findsNothing);
  });

  testWidgets(
    'hides local options on native platforms without local assistant',
    (tester) async {
      await tester.pumpWidget(
        _assistantApp(
          const PlatformCapabilities(
            isWeb: false,
            supportsAppUpdates: false,
            supportsBackgroundNotifications: false,
            supportsLocalAssistant: false,
            supportsFileSystemCache: false,
            supportsBrowserFileInput: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('OpenCode Zen'), findsNWidgets(2));
      expect(find.text('Online Models'), findsOneWidget);
      expect(find.text('Download'), findsNothing);
      expect(find.text('Import'), findsNothing);
      expect(find.text('Local Models'), findsNothing);
    },
  );

  testWidgets('shows local options when local assistant is supported', (
    tester,
  ) async {
    await tester.pumpWidget(
      _assistantApp(
        const PlatformCapabilities(
          isWeb: false,
          supportsAppUpdates: true,
          supportsBackgroundNotifications: true,
          supportsLocalAssistant: true,
          supportsFileSystemCache: true,
          supportsBrowserFileInput: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('OpenCode Zen'), findsNWidgets(2));
    expect(find.text('Online Models'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
    expect(find.text('Local Models'), findsOneWidget);
  });

  testWidgets('selects the last online model from the sheet', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const lastModelId = 'test-model-11-free';
    final notifier = _AssistantNotifier(
      onlineModels: List.generate(12, (index) => 'test-model-$index-free'),
    );

    await tester.pumpWidget(
      _assistantApp(
        const PlatformCapabilities(
          isWeb: false,
          supportsAppUpdates: false,
          supportsBackgroundNotifications: false,
          supportsLocalAssistant: false,
          supportsFileSystemCache: false,
          supportsBrowserFileInput: false,
        ),
        notifier: notifier,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Online Models'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(lastModelId),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text(lastModelId));
    await tester.pumpAndSettle();

    expect(notifier.lastSelectedOnlineModel, lastModelId);
  });
}
