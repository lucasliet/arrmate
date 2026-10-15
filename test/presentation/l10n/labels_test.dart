import 'package:arrmate/core/extensions/date_extensions.dart';
import 'package:arrmate/core/l10n/app_locale.dart';
import 'package:arrmate/core/network/api_error.dart';
import 'package:arrmate/core/utils/formatters.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/l10n/labels.dart';
import 'package:arrmate/presentation/router/app_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = appLocalizationsFor(const Locale('en'));
  final ptBR = appLocalizationsFor(const Locale('pt', 'BR'));
  final es = appLocalizationsFor(const Locale('es'));

  group('localized labels', () {
    test('English matches the domain getters', () {
      for (final status in MovieStatus.values) {
        expect(status.localizedLabel(en), status.label);
      }
      for (final type in SeriesMonitorType.values) {
        expect(type.localizedLabel(en), type.label);
      }
      for (final status in TorrentStatus.values) {
        expect(status.localizedLabel(en), status.label);
      }
      for (final status in TorrentLinkStatus.values) {
        expect(status.localizedLabel(en), status.label);
        expect(status.localizedDescription(en), status.description);
      }
      for (final type in HistoryEventType.values) {
        expect(type.localizedLabel(en), type.label);
        expect(type.localizedTitle(en), type.title);
      }
      for (final priority in FilePriority.values) {
        expect(priority.localizedLabel(en), priority.label);
      }
      for (final tab in AppTab.values) {
        expect(tab.localizedLabel(en), tab.label);
      }
    });

    test('translates enum labels to pt_BR and es', () {
      expect(TorrentStatus.uploading.localizedLabel(ptBR), 'Semeando');
      expect(TorrentStatus.uploading.localizedLabel(es), 'Sembrando');
      expect(AppTab.settings.localizedLabel(ptBR), 'Configurações');
      expect(AppTab.settings.localizedLabel(es), 'Ajustes');
      expect(QueueStatus.downloading.localizedLabel(ptBR), 'Baixando');
      expect(QueueStatus.downloading.localizedLabel(es), 'Descargando');
    });

    test('season labels and formatters', () {
      const specials = Season(seasonNumber: 0, monitored: true);
      const third = Season(seasonNumber: 3, monitored: true);
      expect(specials.localizedLabel(en), specials.label);
      expect(third.localizedLabel(en), third.label);
      expect(third.localizedLabel(ptBR), 'Temporada 3');
      expect(formatSeasonNumberL10n(0, es), 'Especiales');
      expect(formatEpisodeNumberL10n(1, 5, en), 'Season 1, Episode 5');
      expect(formatEpisodeNumberL10n(1, 5, es, short: true), 'S01E05');
    });

    test('history description keeps the English sentence', () {
      final event = HistoryEvent.fromJson({
        'id': 1,
        'eventType': 'grabbed',
        'date': '2024-01-01T00:00:00Z',
        'movieId': 10,
        'quality': {
          'quality': {'id': 1, 'name': 'Bluray-1080p'},
        },
        'data': {'indexer': 'Nyaa', 'downloadClient': 'qBittorrent'},
      });
      expect(event.localizedDescription(en), event.description);
      expect(
        event.localizedDescription(ptBR),
        'Filme capturado de Nyaa e enviado para qBittorrent.',
      );
    });

    test('relative dates', () {
      final now = DateTime.now();
      expect(now.relativeDateL10n(en), 'Just now');
      final yesterday = now.subtract(const Duration(days: 1, hours: 1));
      expect(yesterday.relativeDateL10n(en), yesterday.relativeDate);
      expect(yesterday.relativeDateL10n(es), 'Ayer');
      final months = now.subtract(const Duration(days: 65));
      expect(months.relativeDateL10n(en), months.relativeDate);
      expect(months.relativeDateL10n(ptBR), 'há 2 meses');
    });
  });

  group('describeError', () {
    test('translates built-in API error messages', () {
      expect(
        describeError(const ConnectionError(), en),
        const ConnectionError().message,
      );
      expect(
        describeError(const TimeoutError(), ptBR),
        'A solicitação expirou. Tente novamente.',
      );
      expect(
        describeError(const InvalidUrlError('foo'), es),
        'URL no válida: foo',
      );
      expect(
        describeError(const UnknownApiError('Request cancelled'), es),
        'Solicitud cancelada',
      );
    });

    test('keeps server messages and other errors untouched', () {
      expect(describeError(const ServerError('Disk full'), ptBR), 'Disk full');
      expect(describeError(StateError('boom'), es), 'Bad state: boom');
    });
  });
}
