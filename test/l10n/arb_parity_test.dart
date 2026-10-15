import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readArb(String locale) {
  final file = File('lib/l10n/app_$locale.arb');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

/// Returns the placeholder names the template declares for [key].
Set<String> _declaredPlaceholders(Map<String, dynamic> template, String key) {
  final meta = template['@$key'];
  if (meta is! Map<String, dynamic>) return const {};
  final placeholders = meta['placeholders'];
  if (placeholders is! Map<String, dynamic>) return const {};
  return placeholders.keys.toSet();
}

/// Whether [message] references the placeholder [name].
bool _usesPlaceholder(String message, String name) =>
    RegExp('\\{$name[,}]').hasMatch(message);

void main() {
  final template = _readArb('en');
  final templateKeys = _messageKeys(template);

  for (final locale in ['pt_BR', 'pt', 'es']) {
    group('app_$locale.arb', () {
      final arb = _readArb(locale);

      test('has exactly the template keys', () {
        final keys = _messageKeys(arb);
        expect(keys.difference(templateKeys), isEmpty, reason: 'extra keys');
        expect(templateKeys.difference(keys), isEmpty, reason: 'missing keys');
      });

      test('has no empty translations', () {
        for (final key in _messageKeys(arb)) {
          expect((arb[key] as String).trim(), isNotEmpty, reason: key);
        }
      });

      test('uses every placeholder the template declares', () {
        for (final key in templateKeys) {
          final translation = arb[key];
          if (translation is! String) continue;
          for (final name in _declaredPlaceholders(template, key)) {
            expect(
              _usesPlaceholder(translation, name),
              isTrue,
              reason: '$key must use {$name}',
            );
          }
        }
      });
    });
  }

  test('pt fallback mirrors pt_BR', () {
    final ptBr = _readArb('pt_BR')..remove('@@locale');
    final pt = _readArb('pt')..remove('@@locale');
    expect(pt, ptBr);
  });
}
