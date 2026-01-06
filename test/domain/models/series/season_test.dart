import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/domain/models/series/season.dart';

void main() {
  group('Season', () {
    group('copyWith', () {
      test('Deve manter monitored original quando não fornecido', () {
        // Given
        const season = Season(seasonNumber: 1, monitored: true);

        // When
        final result = season.copyWith();

        // Then
        expect(result.monitored, isTrue);
        expect(result.seasonNumber, equals(1));
      });

      test('Deve atualizar monitored para false quando fornecido', () {
        // Given
        const season = Season(seasonNumber: 1, monitored: true);

        // When
        final result = season.copyWith(monitored: false);

        // Then
        expect(result.monitored, isFalse);
        expect(result.seasonNumber, equals(1));
      });

      test('Deve atualizar monitored para true quando fornecido', () {
        // Given
        const season = Season(seasonNumber: 2, monitored: false);

        // When
        final result = season.copyWith(monitored: true);

        // Then
        expect(result.monitored, isTrue);
        expect(result.seasonNumber, equals(2));
      });
    });

    group('label', () {
      test('Deve retornar "Specials" para seasonNumber 0', () {
        // Given
        const season = Season(seasonNumber: 0, monitored: false);

        // When
        final result = season.label;

        // Then
        expect(result, equals('Specials'));
      });

      test('Deve retornar "Season X" para seasonNumber maior que 0', () {
        // Given
        const season = Season(seasonNumber: 3, monitored: true);

        // When
        final result = season.label;

        // Then
        expect(result, equals('Season 3'));
      });
    });
  });
}
