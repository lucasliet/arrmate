import 'package:arrmate/presentation/widgets/media/poster_viewer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should open and close the full-screen poster viewer', (
    tester,
  ) async {
    // Given
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => showPosterViewer(
                context: context,
                title: 'Test Movie',
                poster: const ColoredBox(color: Colors.red),
              ),
              child: const Text('Open poster'),
            );
          },
        ),
      ),
    );

    // When
    await tester.tap(find.text('Open poster'));
    await tester.pumpAndSettle();

    // Then
    expect(find.byType(PosterViewer), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Test Movie'), findsOneWidget);

    // When
    await tester.tap(find.byKey(const Key('closePosterViewer')));
    await tester.pumpAndSettle();

    // Then
    expect(find.byType(PosterViewer), findsNothing);
  });

  testWidgets('zooms in on a mouse wheel scroll up', (tester) async {
    final scale = await _scaleAfterScroll(
      tester,
      PointerDeviceKind.mouse,
      const Offset(0, -120),
    );
    expect(scale, greaterThan(1));
    expect(scale, lessThanOrEqualTo(4));
  });

  testWidgets('zooms in on a trackpad scroll up', (tester) async {
    final scale = await _scaleAfterScroll(
      tester,
      PointerDeviceKind.trackpad,
      const Offset(0, -120),
    );
    expect(scale, greaterThan(1));
  });

  testWidgets('stays at 1x when scrolling down from the minimum', (
    tester,
  ) async {
    final scale = await _scaleAfterScroll(
      tester,
      PointerDeviceKind.mouse,
      const Offset(0, 120),
    );
    expect(scale, 1);
  });
}

Future<double> _scaleAfterScroll(
  WidgetTester tester,
  PointerDeviceKind kind,
  Offset delta,
) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: PosterViewer(
        title: 'Dune',
        poster: ColoredBox(color: Color(0xFF4CAF50)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final viewer = find.byType(InteractiveViewer);
  double scale() {
    return tester
        .widget<Transform>(
          find.descendant(of: viewer, matching: find.byType(Transform)),
        )
        .transform
        .getMaxScaleOnAxis();
  }

  expect(scale(), 1);
  await tester.sendEventToBinding(
    PointerScrollEvent(
      position: tester.getCenter(viewer),
      kind: kind,
      scrollDelta: delta,
    ),
  );
  await tester.pump();
  return scale();
}
