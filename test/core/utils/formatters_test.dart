import 'package:arrmate/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('softWrapReleaseName', () {
    test('should add a break opportunity after each separator', () {
      expect(
        softWrapReleaseName('Some.Movie_2024-WEB'),
        'Some.\u200BMovie_\u200B2024-\u200BWEB',
      );
    });

    test('should leave names with spaces and trailing separators alone', () {
      expect(softWrapReleaseName('Test Torrent'), 'Test Torrent');
      expect(softWrapReleaseName('Movie...'), 'Movie...');
      expect(softWrapReleaseName('a. b'), 'a. b');
    });

    testWidgets('should make a narrow line break at a separator', (
      tester,
    ) async {
      // Given a name that does not fit on one line
      const name = 'Aaaaaaaa.Bbbbbbbb';
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 12 * 14,
              child: Text(
                softWrapReleaseName(name),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      );

      // When
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );
      final wrapped = softWrapReleaseName(name);
      double topOf(String character) {
        final offset = wrapped.indexOf(character);
        return paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: offset, extentOffset: offset + 1),
            )
            .single
            .top;
      }

      // Then the second word starts the second line, in one piece
      expect(topOf('B'), greaterThan(topOf('A')));
      expect(topOf('.'), topOf('A'));
    });
  });

  group('formatInstanceVersion', () {
    test('should return empty string when version is null', () {
      expect(formatInstanceVersion(null), '');
    });

    test('should add v prefix when version exists and starts with a digit', () {
      expect(formatInstanceVersion('5.0.0'), 'v5.0.0');
      expect(formatInstanceVersion('1.0'), 'v1.0');
    });

    test('should not add v prefix when version already starts with v', () {
      expect(formatInstanceVersion('v4.6.0'), 'v4.6.0');
      expect(formatInstanceVersion('v1.0.0-beta'), 'v1.0.0-beta');
    });

    test(
      'should add v prefix when version is Unknown or other non-digit string',
      () {
        expect(formatInstanceVersion('Unknown'), 'vUnknown');
        expect(formatInstanceVersion('beta-version'), 'vbeta-version');
      },
    );

    test('should handle edge cases', () {
      expect(formatInstanceVersion(''), '');
      expect(formatInstanceVersion(' '), '');
    });
  });

  group('formatPercentage', () {
    test('should format integer double values without decimals', () {
      expect(formatPercentage(50.0), '50%');
      expect(formatPercentage(0.0), '0%');
      expect(formatPercentage(100.0), '100%');
    });

    test('should round decimal values', () {
      expect(formatPercentage(50.5), '51%');
      expect(formatPercentage(50.4), '50%');
    });
  });
}
