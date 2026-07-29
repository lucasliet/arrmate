import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/instance_storage_provider.dart';
import 'package:arrmate/presentation/screens/settings/system_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'should show partial instance data and explicit section failures',
    (tester) async {
      // Given
      final overview = InstanceStorageOverview(
        instance: Instance(
          id: 'radarr-home',
          type: InstanceType.radarr,
          label: 'Home Radarr',
          url: 'https://radarr.example.com',
          apiKey: 'key',
        ),
        status: const InstanceStatus(
          appName: 'Radarr',
          instanceName: 'Home',
          version: '5.0.0',
        ),
        library: const InstanceLibraryStatistics(
          movieCount: 2,
          sizeOnDisk: 4000,
        ),
        diskSpaces: const [
          InstanceDiskSpace(
            path: '/mnt/media',
            label: 'Media',
            freeSpace: 400,
            totalSpace: 1000,
          ),
        ],
        failures: const [
          InstanceOverviewFailure(
            section: InstanceOverviewSection.library,
            message: 'Some library data is unavailable.',
          ),
        ],
      );

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instanceStorageOverviewsProvider.overrideWith(
              (ref) async => [overview],
            ),
          ],
          child: const MaterialApp(home: SystemOverviewScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.text('System Overview'), findsOneWidget);
      expect(find.text('Home Radarr'), findsOneWidget);
      expect(find.text('v5.0.0'), findsOneWidget);
      expect(find.text('2 Movies'), findsOneWidget);
      expect(find.text('3.9 KB Library'), findsOneWidget);
      expect(find.text('Disk Space'), findsOneWidget);
      expect(find.text('Media'), findsOneWidget);
      expect(find.text('Used 600 B (60%)'), findsOneWidget);
      expect(find.text('400 B free of 1000 B'), findsOneWidget);
      expect(find.text('Some library data is unavailable.'), findsOneWidget);
    },
  );

  testWidgets('should show an empty state without Arr instances', (
    tester,
  ) async {
    // Given
    final overrides = [
      instanceStorageOverviewsProvider.overrideWith((ref) async => []),
    ];

    // When
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: SystemOverviewScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Then
    expect(find.text('No Arr instances configured'), findsOneWidget);
  });
}
