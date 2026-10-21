import 'dart:convert';
import 'dart:io';

import 'package:arrmate/core/l10n/app_locale.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Portuguese plural rules put 0 in the same category as 1, so a message that
/// only spells out `=1` would read "1 torrent" for zero.
void main() {
  for (final locale in const [Locale('pt', 'BR'), Locale('pt')]) {
    group('plural zero in $locale', () {
      final l10n = appLocalizationsFor(locale);

      test('seriesPurgedSummary never turns zero into one', () {
        expect(
          l10n.seriesPurgedSummary(0, 0),
          'Expurgado: 0 arquivos, 0 torrents.',
        );
        expect(
          l10n.seriesPurgedSummary(1, 1),
          'Expurgado: 1 arquivo, 1 torrent.',
        );
      });

      test('seriesPurgedSeasonsSummary never turns zero into one', () {
        expect(
          l10n.seriesPurgedSeasonsSummary(0, 0, 0),
          '0 temporadas expurgadas: 0 arquivos, 0 torrents.',
        );
        expect(
          l10n.seriesPurgedSeasonsSummary(1, 1, 1),
          '1 temporada expurgada: 1 arquivo, 1 torrent.',
        );
        expect(
          l10n.seriesPurgedSeasonsSummary(2, 12, 3),
          '2 temporadas expurgadas: 12 arquivos, 3 torrents.',
        );
      });

      test('seriesEpisodeCount never turns zero into one', () {
        expect(l10n.seriesEpisodeCount(0), '0 episódios');
        expect(l10n.seriesEpisodeCount(1), '1 episódio');
        expect(l10n.seriesEpisodeCount(9), '9 episódios');
      });
    });
  }

  group('every Portuguese plural spells out zero', () {
    // A block that spells out `=1` without `=0` reads "1 ..." for zero, so the
    // ARBs must give zero its own case wherever one is given.
    final pluralStart = RegExp(r'\{\w+, plural, ');

    /// The text of every plural block in [message], without its outer braces.
    Iterable<String> pluralBlocks(String message) sync* {
      for (final start in pluralStart.allMatches(message)) {
        var depth = 0;
        for (var i = start.start; i < message.length; i++) {
          if (message[i] == '{') depth++;
          if (message[i] == '}') depth--;
          if (depth == 0) {
            yield message.substring(start.end, i);
            break;
          }
        }
      }
    }

    for (final file in const ['app_pt_BR.arb', 'app_pt.arb']) {
      test('$file has an =0 case next to every =1 case', () {
        final arb =
            jsonDecode(File('lib/l10n/$file').readAsStringSync())
                as Map<String, dynamic>;
        final offenders = <String>[];
        for (final entry in arb.entries) {
          final value = entry.value;
          if (entry.key.startsWith('@') || value is! String) continue;
          for (final cases in pluralBlocks(value)) {
            if (cases.startsWith('=1{') && !cases.contains('=0{')) {
              offenders.add(entry.key);
            }
          }
        }
        expect(offenders, isEmpty, reason: 'plurals missing =0 in $file');
      });
    }

    test('a search with no result reads zero, not one', () {
      final l10n = appLocalizationsFor(const Locale('pt', 'BR'));

      expect(l10n.torrentResultCount(0), '0 torrents');
      expect(
        l10n.torrentResultCountWithHidden(0, 17),
        '0 torrents · ocultos: 17',
      );
      expect(
        l10n.torrentResultCountWithHidden(1, 17),
        '1 torrent · ocultos: 17',
      );
      expect(l10n.releasesResultCountHidden(0, 0), '0 resultados · 0 ocultos');
    });
  });
}
