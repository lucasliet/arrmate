import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:arrmate/core/services/assistant_model_service.dart';
import 'package:arrmate/presentation/providers/assistant_provider.dart';
import 'package:arrmate/presentation/screens/assistant/assistant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _AssistantNotifier extends AssistantNotifier {
  @override
  AssistantState build() => AssistantState(
    isLoading: false,
    selectedOnlineModelId: 'deepseek-v4-flash-free',
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
}

Widget _assistantApp(PlatformCapabilities capabilities) => ProviderScope(
  overrides: [
    assistantProvider.overrideWith(_AssistantNotifier.new),
    platformCapabilitiesProvider.overrideWithValue(capabilities),
  ],
  child: const MaterialApp(home: AssistantScreen()),
);

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

  testWidgets('preserves local options on non-web platforms', (tester) async {
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
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
    expect(find.text('Local Models'), findsOneWidget);
  });
}
