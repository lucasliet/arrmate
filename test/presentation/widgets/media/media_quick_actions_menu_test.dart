import 'package:arrmate/core/utils/media_external_links.dart';
import 'package:arrmate/presentation/widgets/media/media_quick_actions_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should dispatch automatic search from the quick actions menu', (
    tester,
  ) async {
    // Given
    var searchCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuickActionsMenu(
            links: const [],
            onAutomaticSearch: () async => searchCount++,
            onOpenExternal: (_) async {},
          ),
        ),
      ),
    );

    // When
    await tester.tap(find.byTooltip('Quick actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic Search'));
    await tester.pumpAndSettle();

    // Then
    expect(searchCount, 1);
  });

  testWidgets('should dispatch the selected external link', (tester) async {
    // Given
    final expectedUri = Uri.https('www.imdb.com', '/title/tt1234567/');
    Uri? openedUri;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuickActionsMenu(
            links: [MediaExternalLink(label: 'IMDb', uri: expectedUri)],
            onAutomaticSearch: () async {},
            onOpenExternal: (uri) async => openedUri = uri,
          ),
        ),
      ),
    );

    // When
    await tester.tap(find.byTooltip('Quick actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open in IMDb'));
    await tester.pumpAndSettle();

    // Then
    expect(openedUri, expectedUri);
  });
}
