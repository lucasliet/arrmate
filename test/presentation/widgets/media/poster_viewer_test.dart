import 'package:arrmate/presentation/widgets/media/poster_viewer.dart';
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
}
