import 'dart:async';
import 'dart:convert';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
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
}

Widget _screen(String instanceId) {
  return ProviderScope(
    child: MaterialApp(home: InstanceEditScreen(instanceId: instanceId)),
  );
}

TextFormField _nameField(WidgetTester tester) {
  return tester.widget<TextFormField>(find.byType(TextFormField).first);
}
