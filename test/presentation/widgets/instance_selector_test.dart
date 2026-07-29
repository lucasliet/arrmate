import 'dart:convert';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/widgets/instance_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('should change the active instance from the app bar selector', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final home = Instance(
      id: 'radarr-home',
      type: InstanceType.radarr,
      label: 'Home',
      url: 'https://home.example.com',
      apiKey: 'key',
    );
    final remote = Instance(
      id: 'radarr-remote',
      type: InstanceType.radarr,
      label: 'Remote',
      url: 'https://remote.example.com',
      apiKey: 'key',
    );
    SharedPreferences.setMockInitialValues({
      'instances': jsonEncode([home.toJson(), remote.toJson()]),
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: const [InstanceSelector(type: InstanceType.radarr)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Select Radarr instance'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remote'));
    await tester.pumpAndSettle();

    expect(container.read(currentRadarrInstanceProvider), equals(remote));
  });
}
