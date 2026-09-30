import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:arrmate/core/services/assistant_model_service.dart';
import 'package:arrmate/core/services/assistant_online_chat_service.dart';
import 'package:arrmate/presentation/providers/assistant_provider.dart';
import 'package:arrmate/presentation/screens/assistant/assistant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _AssistantNotifier extends AssistantNotifier {
  _AssistantNotifier({this.onlineModels = const []});

  final List<String> onlineModels;
  String? lastSelectedOnlineModel;

  @override
  AssistantState build() => AssistantState(
    isLoading: false,
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
    child: const MaterialApp(home: AssistantScreen()),
  );
}

void main() {
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
