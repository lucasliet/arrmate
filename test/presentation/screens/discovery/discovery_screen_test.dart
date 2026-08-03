import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/discovery/discovery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should show only the movie add flow for movie discovery', (
    tester,
  ) async {
    const screen = DiscoveryScreen(initialType: 'movie');

    await tester.pumpWidget(_wrap(screen));

    expect(find.text('Add Movie'), findsOneWidget);
    expect(find.text('Add Series'), findsNothing);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('should show only the series add flow for series discovery', (
    tester,
  ) async {
    const screen = DiscoveryScreen(initialType: 'series');

    await tester.pumpWidget(_wrap(screen));

    expect(find.text('Add Series'), findsOneWidget);
    expect(find.text('Add Movie'), findsNothing);
    expect(find.byType(TabBar), findsNothing);
  });
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      currentRadarrInstanceProvider.overrideWithValue(null),
      currentSonarrInstanceProvider.overrideWithValue(null),
    ],
    child: MaterialApp(home: child),
  );
}
