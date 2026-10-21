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
}
