import 'dart:io';

import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:arrmate/presentation/widgets/poster_network_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/localized_app.dart';
import 'mock_image_http.dart';

const _posterUrl = 'https://image.tmdb.org/t/p/w500/poster.jpg';
const _otherPosterUrl = 'https://image.tmdb.org/t/p/w500/other.jpg';
const _authHeaders = {'X-Api-Key': 'test-api-key'};

class _OfflineHttpClient extends Mock implements HttpClient {}

Widget _wrap({
  required bool isWeb,
  String imageUrl = _posterUrl,
  Map<String, String>? httpHeaders,
  WidgetBuilder? placeholderBuilder,
}) {
  return ProviderScope(
    overrides: [
      platformCapabilitiesProvider.overrideWithValue(
        PlatformCapabilities.forPlatform(
          isWeb: isWeb,
          targetPlatform: TargetPlatform.linux,
        ),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      locale: testLocale,
      home: Scaffold(
        body: SizedBox(
          width: 100,
          height: 150,
          child: PosterNetworkImage(
            imageUrl: imageUrl,
            httpHeaders: httpHeaders,
            placeholderBuilder: placeholderBuilder,
            errorBuilder: (context) => const Icon(Icons.broken_image),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerMockFallbacks();
  });

  // A poster decoded by an earlier test would be shown at once, skipping the
  // loading state the next test expects.
  setUp(() {
    imageCache.clear();
    imageCache.clearLiveImages();
  });

  group('PosterNetworkImage', () {
    testWidgets(
      'uses the framework network image on web so a covered route does not decode it again',
      (tester) async {
        await HttpOverrides.runZoned(
          () async {
            // Given
            final widget = _wrap(isWeb: true, httpHeaders: _authHeaders);

            // When
            await tester.pumpWidget(widget);

            // Then
            final image = tester.widget<Image>(find.byType(Image));
            final provider = image.image;
            expect(provider, isA<NetworkImage>());
            expect((provider as NetworkImage).url, _posterUrl);
            expect(provider.headers, _authHeaders);
            expect(
              provider.webHtmlElementStrategy,
              WebHtmlElementStrategy.fallback,
            );
            expect(image.fit, BoxFit.cover);
            expect(find.byType(CachedNetworkImage), findsNothing);
          },
          createHttpClient: (context) =>
              TestHttpOverrides().createHttpClient(context),
        );
      },
    );

    testWidgets('shows the loading placeholder on web until a frame arrives', (
      tester,
    ) async {
      await HttpOverrides.runZoned(
        () async {
          // Given
          final widget = _wrap(isWeb: true);

          // When
          await tester.pumpWidget(widget);

          // Then
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.byIcon(Icons.broken_image), findsNothing);
        },
        createHttpClient: (context) =>
            TestHttpOverrides().createHttpClient(context),
      );
    });

    testWidgets(
      'builds a new image on web when the poster URL changes in place',
      (tester) async {
        await HttpOverrides.runZoned(
          () async {
            // Given a poster already on screen
            await tester.pumpWidget(_wrap(isWeb: true));
            final first = tester.state(find.byType(Image));

            // When the same slot receives another poster
            await tester.pumpWidget(
              _wrap(isWeb: true, imageUrl: _otherPosterUrl),
            );

            // Then the image is not the one that showed the previous poster
            final second = tester.state(find.byType(Image));
            expect(second, isNot(same(first)));
            final image = tester.widget<Image>(find.byType(Image));
            expect((image.image as NetworkImage).url, _otherPosterUrl);
          },
          createHttpClient: (context) =>
              TestHttpOverrides().createHttpClient(context),
        );
      },
    );

    for (final isWeb in [true, false]) {
      testWidgets('shows the given placeholder while loading (web: $isWeb)', (
        tester,
      ) async {
        await HttpOverrides.runZoned(
          () async {
            // Given
            final widget = _wrap(
              isWeb: isWeb,
              placeholderBuilder: (context) => const Text('Loading poster'),
            );

            // When
            await tester.pumpWidget(widget);

            // Then
            expect(find.text('Loading poster'), findsOneWidget);
            expect(find.byType(CircularProgressIndicator), findsNothing);
          },
          createHttpClient: (context) =>
              TestHttpOverrides().createHttpClient(context),
        );
      });
    }

    testWidgets('shows the error fallback on web when the image fails', (
      tester,
    ) async {
      // Given
      imageCache.clear();
      imageCache.clearLiveImages();
      final offlineClient = _OfflineHttpClient();
      when(
        () => offlineClient.getUrl(any()),
      ).thenThrow(const SocketException('offline'));
      debugNetworkImageHttpClientProvider = () => offlineClient;
      final widget = _wrap(isWeb: true);

      // When
      await tester.pumpWidget(widget);
      await tester.pump();
      debugNetworkImageHttpClientProvider = null;

      // Then
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('keeps the disk-cached image on native platforms', (
      tester,
    ) async {
      await HttpOverrides.runZoned(
        () async {
          // Given
          final widget = _wrap(isWeb: false, httpHeaders: _authHeaders);

          // When
          await tester.pumpWidget(widget);

          // Then
          final cached = tester.widget<CachedNetworkImage>(
            find.byType(CachedNetworkImage),
          );
          expect(cached.imageUrl, _posterUrl);
          expect(cached.httpHeaders, _authHeaders);
          expect(cached.fit, BoxFit.cover);
        },
        createHttpClient: (context) =>
            TestHttpOverrides().createHttpClient(context),
      );
    });
  });
}
