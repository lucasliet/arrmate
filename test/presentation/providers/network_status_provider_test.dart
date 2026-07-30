import 'dart:async';

import 'package:arrmate/presentation/providers/network_status_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkAvailability', () {
    test('should report offline when every interface is none', () {
      // Given
      final availability = NetworkAvailability(
        interfaces: const [ConnectivityResult.none, ConnectivityResult.none],
        observedAt: DateTime.utc(2024, 1, 1),
      );

      // When / Then
      expect(availability.isOffline, isTrue);
    });

    test('should report offline when interfaces is empty', () {
      // Given
      final availability = NetworkAvailability(
        interfaces: const [],
        observedAt: DateTime.utc(2024, 1, 1),
      );

      // When / Then
      expect(availability.isOffline, isTrue);
    });

    test('should report online when at least one interface is usable', () {
      // Given
      final availability = NetworkAvailability(
        interfaces: const [ConnectivityResult.none, ConnectivityResult.wifi],
        observedAt: DateTime.utc(2024, 1, 1),
      );

      // When / Then
      expect(availability.isOffline, isFalse);
    });
  });

  group('networkAvailabilityProvider', () {
    late MockConnectivity connectivity;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      connectivity = MockConnectivity();
      registerFallbackValue(<ConnectivityResult>[]);
    });

    test(
      'should be online and persist last online when wifi is available',
      () async {
        // Given
        when(
          connectivity.checkConnectivity,
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(
          () => connectivity.onConnectivityChanged,
        ).thenAnswer((_) => const Stream.empty());

        final container = ProviderContainer(
          overrides: [connectivityProvider.overrideWithValue(connectivity)],
        );
        addTearDown(container.dispose);

        // When
        final availability = await container.read(
          networkAvailabilityProvider.future,
        );

        // Then
        expect(availability.isOffline, isFalse);
        expect(availability.lastOnlineAt, isNotNull);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('network_last_online_at'), isNotNull);
      },
    );

    test('should keep the seeded last online when offline', () async {
      // Given
      final seeded = DateTime.utc(2023, 6, 15).toIso8601String();
      SharedPreferences.setMockInitialValues({
        'network_last_online_at': seeded,
      });
      when(
        connectivity.checkConnectivity,
      ).thenAnswer((_) async => [ConnectivityResult.none]);
      when(
        () => connectivity.onConnectivityChanged,
      ).thenAnswer((_) => const Stream.empty());

      final container = ProviderContainer(
        overrides: [connectivityProvider.overrideWithValue(connectivity)],
      );
      addTearDown(container.dispose);

      // When
      final availability = await container.read(
        networkAvailabilityProvider.future,
      );

      // Then
      expect(availability.isOffline, isTrue);
      expect(availability.lastOnlineAt?.toIso8601String(), seeded);
    });

    test(
      'should update last online when transitioning from offline to online',
      () async {
        // Given
        final controller =
            StreamController<List<ConnectivityResult>>.broadcast();
        addTearDown(controller.close);
        when(
          connectivity.checkConnectivity,
        ).thenAnswer((_) async => [ConnectivityResult.none]);
        when(
          () => connectivity.onConnectivityChanged,
        ).thenAnswer((_) => controller.stream);

        final container = ProviderContainer(
          overrides: [connectivityProvider.overrideWithValue(connectivity)],
        );
        addTearDown(container.dispose);

        // When
        final subscription = container.listen(
          networkAvailabilityProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);
        await container.read(networkAvailabilityProvider.future);
        await Future<void>.delayed(Duration.zero);
        controller.add([ConnectivityResult.wifi]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Then
        final latest = container.read(networkAvailabilityProvider).value;
        expect(latest, isNotNull);
        expect(latest!.isOffline, isFalse);
        expect(latest.lastOnlineAt, isNotNull);
      },
    );
  });
}
