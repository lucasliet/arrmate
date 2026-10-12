import 'package:apple_foundation_models/apple_foundation_models.dart';
import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:arrmate/core/services/assistant_apple_intelligence_service.dart';
import 'package:arrmate/core/services/assistant_model_service.dart';
import 'package:arrmate/presentation/providers/assistant_provider.dart';
import 'package:arrmate/presentation/screens/assistant/assistant_screen.dart';
import 'package:arrmate/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _AssistantNotifier extends AssistantNotifier {
  _AssistantNotifier({
    this.isGenerating = false,
    this.mode = AssistantModelMode.online,
    this.appleIntelligenceAvailability,
    this.messages = const [],
  });

  final bool isGenerating;
  final AssistantModelMode mode;
  final AppleFoundationModelsAvailability? appleIntelligenceAvailability;
  final List<AssistantMessage> messages;
  String? lastMessage;
  int appleIntelligenceRequests = 0;

  @override
  AssistantState build() => AssistantState(
    isLoading: false,
    isGenerating: isGenerating,
    mode: mode,
    appleIntelligenceAvailability: appleIntelligenceAvailability,
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
    messages: messages,
  );

  @override
  Future<void> useAppleIntelligence() async {
    appleIntelligenceRequests++;
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
        expect(find.text('Cloud'), findsNWidgets(2));
        expect(
          find.text('Import'),
          platform == TargetPlatform.android ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Apple Intelligence'),
          platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
              ? findsOneWidget
              : findsNothing,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Cloud'), findsOneWidget);
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

  testWidgets('keeps online options when local assistant is unsupported', (
    tester,
  ) async {
    await tester.pumpWidget(
      _assistantApp(
        const PlatformCapabilities(
          isWeb: true,
          supportsAppUpdates: false,
          supportsBackgroundNotifications: false,
          localAssistantRuntime: LocalAssistantRuntime.none,
          supportsFileSystemCache: false,
          supportsBrowserFileInput: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Cloud'), findsNWidgets(2));
    expect(find.text('Online Models'), findsNothing);
    expect(find.text('Download'), findsNothing);
    expect(find.text('Import'), findsNothing);
    expect(find.text('Local Models'), findsNothing);
    expect(find.text('Apple Intelligence'), findsNothing);
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
            localAssistantRuntime: LocalAssistantRuntime.none,
            supportsFileSystemCache: false,
            supportsBrowserFileInput: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Cloud'), findsNWidgets(2));
      expect(find.text('Online Models'), findsNothing);
      expect(find.text('Download'), findsNothing);
      expect(find.text('Import'), findsNothing);
      expect(find.text('Local Models'), findsNothing);
      expect(find.text('Apple Intelligence'), findsNothing);
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
          localAssistantRuntime: LocalAssistantRuntime.liteRt,
          supportsFileSystemCache: true,
          supportsBrowserFileInput: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Cloud'), findsNWidgets(2));
    expect(find.text('Online Models'), findsNothing);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
    expect(find.text('Local Models'), findsOneWidget);
    expect(find.text('Apple Intelligence'), findsNothing);
  });

  testWidgets('offers Apple Intelligence with its unavailable reason', (
    tester,
  ) async {
    final notifier = _AssistantNotifier(
      appleIntelligenceAvailability:
          AppleFoundationModelsAvailability.appleIntelligenceNotEnabled,
    );
    await tester.pumpWidget(
      _assistantApp(
        PlatformCapabilities.forPlatform(
          isWeb: false,
          targetPlatform: TargetPlatform.iOS,
        ),
        notifier: notifier,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Download'), findsNothing);
    expect(find.text('Import'), findsNothing);
    expect(
      find.text(
        AppleFoundationModelsAvailability
            .appleIntelligenceNotEnabled
            .unavailableReason!,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Apple Intelligence'));
    await tester.pumpAndSettle();

    expect(notifier.appleIntelligenceRequests, 1);
  });

  testWidgets('shows the active Apple Intelligence model', (tester) async {
    final notifier = _AssistantNotifier(
      mode: AssistantModelMode.appleIntelligence,
      appleIntelligenceAvailability:
          AppleFoundationModelsAvailability.available,
    );
    await tester.pumpWidget(
      _assistantApp(
        PlatformCapabilities.forPlatform(
          isWeb: false,
          targetPlatform: TargetPlatform.macOS,
        ),
        notifier: notifier,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Apple Intelligence'), findsOneWidget);
    expect(find.text('On-device model'), findsOneWidget);
    expect(find.byIcon(Icons.apple), findsOneWidget);
    expect(find.text('Ask about the app'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Como uso?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(notifier.lastMessage, 'Como uso?');
  });

  testWidgets('renders assistant replies as markdown', (tester) async {
    final notifier = _AssistantNotifier(
      mode: AssistantModelMode.appleIntelligence,
      messages: [
        AssistantMessage(
          id: 'm1',
          role: AssistantMessageRole.assistant,
          content:
              'Open the **SeriesDetailsScreen** and toggle the monitor flag.',
          createdAt: DateTime(2026),
        ),
      ],
    );
    await tester.pumpWidget(
      _assistantApp(
        PlatformCapabilities.forPlatform(
          isWeb: false,
          targetPlatform: TargetPlatform.linux,
        ),
        notifier: notifier,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('**'), findsNothing);

    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    final hasBoldPhrase = richTexts.any(
      (rich) => _containsBoldText(rich.text, 'SeriesDetailsScreen'),
    );
    expect(hasBoldPhrase, isTrue);
    expect(find.textContaining('toggle the monitor flag'), findsOneWidget);
  });

  testWidgets('keeps user messages as plain text', (tester) async {
    final notifier = _AssistantNotifier(
      mode: AssistantModelMode.appleIntelligence,
      messages: [
        AssistantMessage(
          id: 'm1',
          role: AssistantMessageRole.user,
          content: 'Does **bold** work here?',
          createdAt: DateTime(2026),
        ),
      ],
    );
    await tester.pumpWidget(
      _assistantApp(
        PlatformCapabilities.forPlatform(
          isWeb: false,
          targetPlatform: TargetPlatform.linux,
        ),
        notifier: notifier,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Does **bold** work here?'), findsOneWidget);
  });
}

bool _containsBoldText(
  InlineSpan span,
  String phrase, {
  bool inheritedBold = false,
}) {
  final isBold = inheritedBold || span.style?.fontWeight == FontWeight.bold;
  if (span is TextSpan && span.text?.contains(phrase) == true && isBold) {
    return true;
  }
  if (span is! TextSpan) return false;
  return span.children?.any(
        (child) => _containsBoldText(child, phrase, inheritedBold: isBold),
      ) ??
      false;
}
