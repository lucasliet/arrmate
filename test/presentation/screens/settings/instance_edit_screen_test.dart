import 'dart:async';
import 'dart:convert';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/providers/jellyfin_session_state_provider.dart';
import 'package:arrmate/presentation/screens/settings/instance_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DelayedInstancesNotifier extends InstancesNotifier {
  final Instance instance;
  final Completer<Instance> saveCompleter;

  _DelayedInstancesNotifier({
    required this.instance,
    required this.saveCompleter,
  });

  @override
  InstancesState build() {
    return InstancesState(instances: [instance], isLoading: false);
  }

  @override
  Future<Instance> validateAndSaveInstance(Instance instance) {
    return saveCompleter.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should rebuild form state when the routed instance id changes', (
    tester,
  ) async {
    // Given
    final first = Instance(
      id: 'instance-a',
      label: 'Instance A',
      url: 'https://a.example.com',
      apiKey: 'key-a',
    );
    final second = Instance(
      id: 'instance-b',
      label: 'Instance B',
      url: 'https://b.example.com',
      apiKey: 'key-b',
    );
    SharedPreferences.setMockInitialValues({
      'instances': jsonEncode([first.toJson(), second.toJson()]),
    });

    // When
    await tester.pumpWidget(_screen(first.id));
    await tester.pumpAndSettle();

    // Then
    expect(_nameField(tester).controller?.text, first.label);

    // When
    await tester.pumpWidget(_screen(second.id));
    await tester.pumpAndSettle();

    // Then
    expect(_nameField(tester).controller?.text, second.label);
  });

  testWidgets('should block conflicting actions while saving', (tester) async {
    // Given
    final instance = Instance(
      id: 'instance-a',
      label: 'Instance A',
      url: 'https://a.example.com',
      apiKey: 'key-a',
    );
    final saveCompleter = Completer<Instance>();
    final notifier = _DelayedInstancesNotifier(
      instance: instance,
      saveCompleter: saveCompleter,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [instancesProvider.overrideWith(() => notifier)],
        child: MaterialApp(home: InstanceEditScreen(instanceId: instance.id)),
      ),
    );
    await tester.pumpAndSettle();

    // When
    final saveFinder = find.widgetWithText(FilledButton, 'Save Instance');
    await tester.ensureVisible(saveFinder);
    await tester.tap(saveFinder);
    await tester.pump();

    // Then
    final saveButton = tester.widget<FilledButton>(
      find.byType(FilledButton).last,
    );
    final testButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Test Connection'),
    );
    final deleteButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete),
    );
    expect(saveButton.onPressed, isNull);
    expect(testButton.onPressed, isNull);
    expect(deleteButton.onPressed, isNull);

    // When
    await tester.pumpWidget(const SizedBox());
    saveCompleter.complete(instance);
    await tester.pump();

    // Then
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'should obscure the api key field by default with a reveal toggle',
    (tester) async {
      // Given
      final instance = Instance(
        id: 'instance-a',
        label: 'Instance A',
        url: 'https://a.example.com',
        apiKey: 'key-a',
      );
      SharedPreferences.setMockInitialValues({
        'instances': jsonEncode([instance.toJson()]),
      });

      // When
      await tester.pumpWidget(_screen(instance.id));
      await tester.pumpAndSettle();

      // Then
      final apiKeyField = _apiKeyField(tester);
      expect(apiKeyField.obscureText, isTrue);
      expect(apiKeyField.controller?.text, 'key-a');
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    },
  );

  testWidgets('should ask for a new login when the session has expired', (
    tester,
  ) async {
    // Given
    final instance = Instance(
      id: 'jellyfin-home',
      type: InstanceType.jellyfin,
      label: 'Home',
      url: 'https://jellyfin.example.com',
      userSession: const InstanceUserSession(
        accessToken: 'token-123',
        deviceId: 'device-1',
        userName: 'admin',
      ),
    );
    SharedPreferences.setMockInitialValues({
      'instances': jsonEncode([instance.toJson()]),
    });

    // When
    await tester.pumpWidget(_screen(instance.id, expiredIds: {instance.id}));
    await tester.pumpAndSettle();

    // Then
    expect(
      find.text(
        'Your Jellyfin session has expired. Add Basic Auth in Advanced '
        'Settings with your username and password to sign in again.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Session expired — add Basic Auth below to sign in again, or enter '
        'an API key',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('username:password'), findsNothing);
  });

  testWidgets('should show the Basic Auth hint for a jellyfin api key', (
    tester,
  ) async {
    // Given
    final instance = Instance(
      id: 'jellyfin-home',
      type: InstanceType.jellyfin,
      label: 'Home',
      url: 'https://jellyfin.example.com',
      apiKey: 'key-a',
    );
    SharedPreferences.setMockInitialValues({
      'instances': jsonEncode([instance.toJson()]),
    });

    // When
    await tester.pumpWidget(_screen(instance.id));
    await tester.pumpAndSettle();

    // Then
    expect(
      find.textContaining(
        'API key (Jellyfin dashboard → Advanced → API Keys). Leave empty if '
        'using "Add Basic Auth" below',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('username:password'), findsNothing);
  });

  testWidgets('should keep the stored session in the jellyfin api key help', (
    tester,
  ) async {
    // Given
    final instance = Instance(
      id: 'jellyfin-home',
      type: InstanceType.jellyfin,
      label: 'Home',
      url: 'https://jellyfin.example.com',
      userSession: const InstanceUserSession(
        accessToken: 'token-123',
        deviceId: 'device-1',
        userName: 'admin',
      ),
    );
    SharedPreferences.setMockInitialValues({
      'instances': jsonEncode([instance.toJson()]),
    });

    // When
    await tester.pumpWidget(_screen(instance.id));
    await tester.pumpAndSettle();

    // Then
    expect(find.textContaining('Signed in as admin.'), findsOneWidget);
    expect(find.textContaining('add Basic Auth below'), findsOneWidget);
    expect(find.textContaining('username:password'), findsNothing);
  });

  testWidgets('should reveal the api key when the eye button is tapped', (
    tester,
  ) async {
    // Given
    final instance = Instance(
      id: 'instance-a',
      label: 'Instance A',
      url: 'https://a.example.com',
      apiKey: 'key-a',
    );
    SharedPreferences.setMockInitialValues({
      'instances': jsonEncode([instance.toJson()]),
    });
    await tester.pumpWidget(_screen(instance.id));
    await tester.pumpAndSettle();

    // When
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    // Then
    final apiKeyField = _apiKeyField(tester);
    expect(apiKeyField.obscureText, isFalse);
    expect(apiKeyField.controller?.text, 'key-a');
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
  });
}

/// Starts with the given instance ids flagged as having an expired session.
class _FlaggedSessionsNotifier extends JellyfinSessionExpiredNotifier {
  _FlaggedSessionsNotifier(this._ids);

  final Set<String> _ids;

  @override
  Set<String> build() => _ids;
}

TextField _apiKeyField(WidgetTester tester) {
  return tester.widget<TextField>(
    find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == 'key-a',
    ),
  );
}

Widget _screen(String instanceId, {Set<String> expiredIds = const {}}) {
  return ProviderScope(
    overrides: [
      jellyfinSessionExpiredProvider.overrideWith(
        () => _FlaggedSessionsNotifier(expiredIds),
      ),
    ],
    child: MaterialApp(home: InstanceEditScreen(instanceId: instanceId)),
  );
}

TextFormField _nameField(WidgetTester tester) {
  return tester.widget<TextFormField>(find.byType(TextFormField).first);
}
