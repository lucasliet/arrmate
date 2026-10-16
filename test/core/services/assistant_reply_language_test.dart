import 'package:arrmate/core/services/assistant_reply_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('assistantReplyInstruction', () {
    test('asks for English replies for the English interface', () {
      expect(assistantReplyInstruction('en'), contains('English'));
    });

    test('asks for Spanish replies for the Spanish interface', () {
      expect(assistantReplyInstruction('es'), contains('Español'));
    });

    test('falls back to Brazilian Portuguese', () {
      expect(assistantReplyInstruction('pt'), contains('Português do Brasil'));
      expect(assistantReplyInstruction('fr'), contains('Português do Brasil'));
    });
  });
}
