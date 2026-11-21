import 'package:arrmate/data/api/media_metadata_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/movies/movie_add_sheet.dart';
import 'package:arrmate/presentation/screens/series/series_add_sheet.dart';
import 'package:arrmate/presentation/shared/providers/media_preview_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_app.dart';

class _FakeMetadataService extends MediaMetadataService {
  _FakeMetadataService({this.details, this.fails = false});

  final MediaPreviewDetails? details;
  final bool fails;
  final requested = <int>[];

  Future<MediaPreviewDetails> _answer(int id) async {
    requested.add(id);
    if (fails) throw Exception('offline');
    return details!;
  }

  @override
  Future<MediaPreviewDetails> getMovieDetails(int tmdbId) => _answer(tmdbId);

  @override
  Future<MediaPreviewDetails> getSeriesDetails(int tvdbId) => _answer(tvdbId);
}

Movie _movie({String? originalTitle}) => Movie(
  tmdbId: 1419406,
  title: 'Operação Sombra',
  originalTitle: originalTitle,
  sortTitle: 'operacao sombra',
  year: 2025,
  runtime: 142,
  status: MovieStatus.released,
  isAvailable: true,
  minimumAvailability: MovieStatus.released,
  monitored: false,
  qualityProfileId: 0,
  added: DateTime(2025),
);

Future<void> _pump(
  WidgetTester tester,
  Widget sheet,
  MediaMetadataService service,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mediaMetadataServiceProvider.overrideWithValue(service),
        currentRadarrInstanceProvider.overrideWithValue(null),
        currentSonarrInstanceProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        locale: testLocale,
        home: Scaffold(body: sheet),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MovieAddSheet preview', () {
    testWidgets('should show the original title, the cast and the crew', (
      tester,
    ) async {
      // Given
      final service = _FakeMetadataService(
        details: const MediaPreviewDetails(
          originalTitle: '捕风追影',
          englishTitle: "The Shadow's Edge",
          cast: [MediaCredit(name: 'Jackie Chan', role: 'Wong Tak-Chung')],
          crew: [MediaCredit(name: 'Larry Yang', role: 'Director')],
        ),
      );

      // When
      await _pump(
        tester,
        MovieAddSheet(initialMovie: _movie(), embedded: true),
        service,
      );

      // Then
      expect(service.requested, [1419406]);
      expect(find.text('Operação Sombra (2025)'), findsOneWidget);
      expect(find.text('Original title: 捕风追影'), findsOneWidget);
      expect(find.text("English title: The Shadow's Edge"), findsOneWidget);
      expect(find.text('Jackie Chan'), findsOneWidget);
      expect(find.text('Larry Yang'), findsOneWidget);
    });

    testWidgets(
      'should keep the original title Radarr sent when the details fail',
      (tester) async {
        // When
        await _pump(
          tester,
          MovieAddSheet(
            initialMovie: _movie(originalTitle: '捕风追影'),
            embedded: true,
          ),
          _FakeMetadataService(fails: true),
        );

        // Then
        expect(find.text('Original title: 捕风追影'), findsOneWidget);
        expect(find.text('Cast'), findsNothing);
        expect(find.text('Configure Addition'), findsOneWidget);
      },
    );

    testWidgets('should omit the original title when it does not differ', (
      tester,
    ) async {
      // When
      await _pump(
        tester,
        MovieAddSheet(
          initialMovie: _movie(originalTitle: 'Operação Sombra'),
          embedded: true,
        ),
        _FakeMetadataService(details: const MediaPreviewDetails()),
      );

      // Then
      expect(find.textContaining('Original title'), findsNothing);
      expect(find.textContaining('English title'), findsNothing);
    });
  });

  group('SeriesAddSheet preview', () {
    testWidgets('should show the cast of the series', (tester) async {
      // Given
      final service = _FakeMetadataService(
        details: const MediaPreviewDetails(
          cast: [MediaCredit(name: 'Bryan Cranston', role: 'Walter White')],
        ),
      );
      final series = Series.fromJson(const {
        'tvdbId': 81189,
        'title': 'Breaking Bad',
        'sortTitle': 'breaking bad',
        'year': 2008,
        'status': 'ended',
        'added': '2008-01-20T00:00:00Z',
        'seasons': <dynamic>[],
      });

      // When
      await _pump(
        tester,
        SeriesAddSheet(initialSeries: series, embedded: true),
        service,
      );

      // Then
      expect(service.requested, [81189]);
      expect(find.text('Cast'), findsOneWidget);
      expect(find.text('Bryan Cranston'), findsOneWidget);
      expect(find.text('Walter White'), findsOneWidget);
    });
  });
}
