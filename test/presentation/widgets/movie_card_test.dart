import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/data/models/models.dart';
import 'package:arrmate/presentation/screens/movies/widgets/movie_card.dart';

// Mock NetworkImage to avoid HTTP calls in widget tests
import 'dart:io';
import 'mock_image_http.dart';

void main() {
  final testMovie = Movie(
    tmdbId: 12345,
    title: 'Test Movie',
    sortTitle: 'test movie',
    year: 2023,
    runtime: 120,
    monitored: true,
    hasFile: true,
    isAvailable: true,
    status: MovieStatus.released,
    minimumAvailability: MovieStatus.released,
    added: DateTime.now(),
    qualityProfileId: 1,
    images: [
      MediaImage(coverType: 'poster', url: '/poster.jpg'),
    ],
  );

  testWidgets('MovieCard displays title and year', (tester) async {
    await HttpOverrides.runZoned(
      () async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: MovieCard(
                  movie: testMovie,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Test Movie'), findsOneWidget);
        expect(find.text('2023'), findsOneWidget);
      },
      createHttpClient: (context) => TestHttpOverrides().createHttpClient(context),
    );
  });

  testWidgets('MovieCard calls onTap when tapped', (tester) async {
    bool tapped = false;
    await HttpOverrides.runZoned(
      () async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: MovieCard(
                  movie: testMovie,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(MovieCard));
        expect(tapped, true);
      },
      createHttpClient: (context) => TestHttpOverrides().createHttpClient(context),
    );
  });
}
