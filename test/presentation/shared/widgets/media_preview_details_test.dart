import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/l10n/generated/app_localizations_en.dart';
import 'package:arrmate/presentation/shared/widgets/media_preview_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_app.dart';

void main() {
  group('previewExtraTitles', () {
    final l10n = AppLocalizationsEn();

    test('should list the original and the English title when both differ', () {
      // When
      final lines = previewExtraTitles(
        l10n,
        title: 'Operação Sombra',
        originalTitle: '捕风追影',
        englishTitle: "The Shadow's Edge",
      );

      // Then
      expect(lines, [
        'Original title: 捕风追影',
        "English title: The Shadow's Edge",
      ]);
    });

    test('should list nothing when the titles match the localized one', () {
      // When
      final lines = previewExtraTitles(
        l10n,
        title: 'Interstellar',
        originalTitle: ' interstellar ',
        englishTitle: 'Interstellar',
      );

      // Then
      expect(lines, isEmpty);
    });

    test('should skip the English title when it is the original one', () {
      // When
      final lines = previewExtraTitles(
        l10n,
        title: 'Interestelar',
        originalTitle: 'Interstellar',
        englishTitle: 'Interstellar',
      );

      // Then
      expect(lines, ['Original title: Interstellar']);
    });

    test('should list the English title alone under a foreign original', () {
      // When
      final lines = previewExtraTitles(
        l10n,
        title: '捕风追影',
        originalTitle: '捕风追影',
        englishTitle: "The Shadow's Edge",
      );

      // Then
      expect(lines, ["English title: The Shadow's Edge"]);
    });
  });

  group('MediaPreviewCredits', () {
    Future<void> pump(
      WidgetTester tester,
      AsyncValue<MediaPreviewDetails> details,
    ) {
      return tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            locale: testLocale,
            home: Scaffold(body: MediaPreviewCredits(details: details)),
          ),
        ),
      );
    }

    testWidgets('should list the cast and the crew with their roles', (
      tester,
    ) async {
      // When
      await pump(
        tester,
        const AsyncData(
          MediaPreviewDetails(
            cast: [MediaCredit(name: 'Jackie Chan', role: 'Wong Tak-Chung')],
            crew: [MediaCredit(name: 'Larry Yang', role: 'Director, Writer')],
          ),
        ),
      );

      // Then
      expect(find.text('Cast'), findsOneWidget);
      expect(find.text('Jackie Chan'), findsOneWidget);
      expect(find.text('Wong Tak-Chung'), findsOneWidget);
      expect(find.text('Crew'), findsOneWidget);
      expect(find.text('Larry Yang'), findsOneWidget);
      expect(find.text('Director, Writer'), findsOneWidget);
    });

    testWidgets('should omit a section without people', (tester) async {
      // When
      await pump(
        tester,
        const AsyncData(
          MediaPreviewDetails(cast: [MediaCredit(name: 'Bryan Cranston')]),
        ),
      );

      // Then
      expect(find.text('Cast'), findsOneWidget);
      expect(find.text('Crew'), findsNothing);
    });

    testWidgets('should show nothing when the details fail to load', (
      tester,
    ) async {
      // When
      await pump(tester, AsyncError(Exception('offline'), StackTrace.empty));

      // Then
      expect(find.text('Cast'), findsNothing);
      expect(find.text('Crew'), findsNothing);
      expect(find.textContaining('offline'), findsNothing);
    });
  });
}
