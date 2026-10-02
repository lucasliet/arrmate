import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/discovery/discovery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('add-movie search header survives a width change', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    final width = ValueNotifier<double>(480);
    addTearDown(width.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentRadarrInstanceProvider.overrideWithValue(null)],
        child: MaterialApp(
          home: ValueListenableBuilder<double>(
            valueListenable: width,
            builder: (context, value, _) => Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: value,
                height: 700,
                child: const DiscoveryScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hide already added'), findsOneWidget);

    width.value = 280;
    await tester.pumpAndSettle();
    width.value = 480;
    await tester.pumpAndSettle();

    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);
    expect(find.text('Hide already added'), findsOneWidget);
  });
}
