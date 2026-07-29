import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arrmate/core/services/logger_service.dart';
import 'package:arrmate/presentation/widgets/deep_link_listener.dart';

void main() {
  group('deepLinkToLocation', () {
    test('should reconcile identifier-in-host form', () {
      final uri = Uri.parse('arrmate://movies/123');

      expect(deepLinkToLocation(uri), '/movies/123');
    });

    test('should handle authority-less form', () {
      final uri = Uri.parse('arrmate:///series/9');

      expect(deepLinkToLocation(uri), '/series/9');
    });

    test('should preserve query parameters', () {
      final uri = Uri.parse('arrmate:///search?q=inception&type=movie');

      expect(deepLinkToLocation(uri), '/search?q=inception&type=movie');
    });

    test('should support nested season paths', () {
      final uri = Uri.parse('arrmate:///series/9/season/3');

      expect(deepLinkToLocation(uri), '/series/9/season/3');
    });

    test('should support nested episode paths in authority-less form', () {
      final uri = Uri.parse('arrmate:///series/9/season/3/episode/45');

      expect(deepLinkToLocation(uri), '/series/9/season/3/episode/45');
    });

    test('should support nested episode paths in host form', () {
      final uri = Uri.parse('arrmate://series/9/season/3/episode/45');

      expect(deepLinkToLocation(uri), '/series/9/season/3/episode/45');
    });

    test('should return empty for a bare scheme', () {
      final uri = Uri.parse('arrmate://');

      expect(deepLinkToLocation(uri), '');
    });
  });

  group('validateDeepLink', () {
    test('should accept valid movie deep link', () {
      expect(
        validateDeepLink(Uri.parse('arrmate://movies/123')),
        '/movies/123',
      );
    });

    test('should accept valid series deep link', () {
      expect(validateDeepLink(Uri.parse('arrmate:///series/9')), '/series/9');
    });

    test('should accept valid season deep link', () {
      expect(
        validateDeepLink(Uri.parse('arrmate:///series/9/season/3')),
        '/series/9/season/3',
      );
    });

    test('should accept valid episode deep link', () {
      expect(
        validateDeepLink(Uri.parse('arrmate:///series/9/season/3/episode/45')),
        '/series/9/season/3/episode/45',
      );
    });

    test('should accept bare section roots (calendar, activity, search)', () {
      expect(validateDeepLink(Uri.parse('arrmate:///calendar')), '/calendar');
      expect(validateDeepLink(Uri.parse('arrmate:///activity')), '/activity');
      expect(validateDeepLink(Uri.parse('arrmate:///search')), '/search');
    });

    test('should accept instance edit deep link', () {
      expect(
        validateDeepLink(Uri.parse('arrmate:///settings/instance/abc-123')),
        '/settings/instance/abc-123',
      );
      expect(
        validateDeepLink(Uri.parse('arrmate:///settings/instance/new')),
        '/settings/instance/new',
      );
    });

    test('should reject wrong scheme', () {
      expect(validateDeepLink(Uri.parse('http://movies/123')), isNull);
      expect(validateDeepLink(Uri.parse('arrmate2://movies/123')), isNull);
    });

    test('should reject bare scheme with no path', () {
      expect(validateDeepLink(Uri.parse('arrmate://')), isNull);
    });

    test('should reject movie id that is not a positive integer', () {
      expect(validateDeepLink(Uri.parse('arrmate://movies/0')), isNull);
      expect(validateDeepLink(Uri.parse('arrmate://movies/abc')), isNull);
      expect(validateDeepLink(Uri.parse('arrmate://movies/-5')), isNull);
    });

    test('should reject series id that is not a positive integer', () {
      expect(validateDeepLink(Uri.parse('arrmate://series/0')), isNull);
      expect(validateDeepLink(Uri.parse('arrmate://series/abc')), isNull);
      expect(
        validateDeepLink(Uri.parse('arrmate:///series/0/season/0')),
        isNull,
      );
      expect(
        validateDeepLink(Uri.parse('arrmate:///series/0/season/0/episode/12')),
        isNull,
      );
    });

    test('should reject unknown root segment', () {
      expect(validateDeepLink(Uri.parse('arrmate://unknown/1')), isNull);
      expect(validateDeepLink(Uri.parse('arrmate://foobar')), isNull);
    });

    test('should reject extra path segments beyond known grammar', () {
      expect(validateDeepLink(Uri.parse('arrmate://movies/1/2')), isNull);
      expect(validateDeepLink(Uri.parse('arrmate://calendar/1')), isNull);
    });

    test('should accept only known settings routes', () {
      const routes = [
        'assistant',
        'logs',
        'health',
        'system-overview',
        'version-history',
        'diagnostics',
        'quality-profiles',
        'notifications',
      ];

      expect(validateDeepLink(Uri.parse('arrmate:///settings')), '/settings');
      for (final route in routes) {
        expect(
          validateDeepLink(Uri.parse('arrmate:///settings/$route')),
          '/settings/$route',
        );
      }
    });

    test('should reject unsupported or incomplete settings routes', () {
      expect(
        validateDeepLink(Uri.parse('arrmate:///settings/instance')),
        isNull,
      );
      expect(
        validateDeepLink(Uri.parse('arrmate:///settings/unsupported')),
        isNull,
      );
      expect(
        validateDeepLink(Uri.parse('arrmate:///settings/logs/details')),
        isNull,
      );
    });

    test('should reject episode route with non-numeric episode id', () {
      expect(
        validateDeepLink(Uri.parse('arrmate:///series/9/season/3/episode/abc')),
        isNull,
      );
      expect(
        validateDeepLink(Uri.parse('arrmate:///series/9/season/3/episode/0')),
        isNull,
      );
    });

    test('should preserve query params on valid deep link', () {
      expect(
        validateDeepLink(Uri.parse('arrmate:///search?q=inception&type=movie')),
        '/search?q=inception&type=movie',
      );
    });

    test('should safely re-encode externally supplied path segments', () {
      expect(
        deepLinkToLocation(Uri.parse('arrmate:///search/value%2Fpart')),
        '/search/value%2Fpart',
      );
      expect(
        () => validateDeepLink(Uri.parse('arrmate:///movies/%25')),
        returnsNormally,
      );
      expect(validateDeepLink(Uri.parse('arrmate:///movies/%25')), isNull);
      expect(
        validateDeepLink(Uri.parse('arrmate:///movies/42%2Fsettings')),
        isNull,
      );
    });
  });

  group('DeepLinkListener', () {
    testWidgets('should defer navigation requested during child build', (
      tester,
    ) async {
      final links = StreamController<Uri>.broadcast(sync: true);
      final navigationDuringBuild = <bool>[];
      var isBuilding = false;
      var emitted = false;
      addTearDown(links.close);

      await tester.pumpWidget(
        DeepLinkListener(
          linkStream: links.stream,
          onNavigate: (_) => navigationDuringBuild.add(isBuilding),
          child: Builder(
            builder: (context) {
              if (!emitted) {
                emitted = true;
                isBuilding = true;
                links.add(Uri.parse('arrmate:///movies/42'));
                isBuilding = false;
              }
              return const SizedBox();
            },
          ),
        ),
      );

      expect(navigationDuringBuild, [isFalse]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should keep handling links when its child changes', (
      tester,
    ) async {
      final links = StreamController<Uri>.broadcast();
      final locations = <String>[];
      addTearDown(links.close);

      await tester.pumpWidget(
        DeepLinkListener(
          linkStream: links.stream,
          onNavigate: locations.add,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: Text('Shell route'),
          ),
        ),
      );

      links.add(Uri.parse('arrmate:///notifications'));
      await tester.pump();

      await tester.pumpWidget(
        DeepLinkListener(
          linkStream: links.stream,
          onNavigate: locations.add,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: Text('Root route'),
          ),
        ),
      );
      links.add(Uri.parse('arrmate:///movies/42'));
      await tester.pump();
      await tester.pump();

      expect(locations, ['/notifications', '/movies/42']);
    });

    testWidgets('should reject invalid links before navigation', (
      tester,
    ) async {
      final links = StreamController<Uri>.broadcast();
      final locations = <String>[];
      addTearDown(links.close);

      await tester.pumpWidget(
        DeepLinkListener(
          linkStream: links.stream,
          onNavigate: locations.add,
          child: const SizedBox(),
        ),
      );

      links.add(Uri.parse('https://example.com/movies/42'));
      links.add(Uri.parse('arrmate:///settings/instance'));
      await tester.pump();

      expect(locations, isEmpty);
    });

    testWidgets('should never write deep-link query values to logs', (
      tester,
    ) async {
      final links = StreamController<Uri>.broadcast();
      addTearDown(links.close);
      logger.clearLogs();

      await tester.pumpWidget(
        DeepLinkListener(
          linkStream: links.stream,
          onNavigate: (_) {},
          child: const SizedBox(),
        ),
      );

      links.add(
        Uri.parse('arrmate:///search?q=private-title&token=private-token'),
      );
      links.add(
        Uri.parse('arrmate:///settings/unsupported?password=private-password'),
      );
      await tester.pump();

      final recordedLogs = logger.logs
          .map((entry) => entry.toLogString())
          .join('\n');
      expect(recordedLogs, isNot(contains('private-title')));
      expect(recordedLogs, isNot(contains('private-token')));
      expect(recordedLogs, isNot(contains('private-password')));
    });

    testWidgets('should cancel its subscription when disposed', (tester) async {
      final links = StreamController<Uri>.broadcast();
      final locations = <String>[];
      addTearDown(links.close);

      await tester.pumpWidget(
        DeepLinkListener(
          linkStream: links.stream,
          onNavigate: locations.add,
          child: const SizedBox(),
        ),
      );
      await tester.pumpWidget(const SizedBox());

      links.add(Uri.parse('arrmate:///movies/42'));
      await tester.pump();

      expect(locations, isEmpty);
    });
  });
}
