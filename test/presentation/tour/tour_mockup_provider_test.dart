import 'dart:convert';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/tour/tour_mockup_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('should keep mockups hidden while the tour is not running', () async {
    // Given
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);

    // Then
    expect(container.read(tourActiveProvider), isFalse);
    for (final type in InstanceType.values) {
      expect(container.read(tourMockupProvider(type)), isFalse);
    }
    expect(container.read(tourMediaMockupProvider), isFalse);
  });

  test('should show mockups for every service on a fresh install', () async {
    // Given
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);

    // When
    container.read(tourActiveProvider.notifier).start();

    // Then
    for (final type in InstanceType.values) {
      expect(container.read(tourMockupProvider(type)), isTrue);
    }
    expect(container.read(tourMediaMockupProvider), isTrue);
  });

  test('should only mock the services without a configured instance', () async {
    // Given
    final radarr = Instance(
      id: 'radarr-home',
      type: InstanceType.radarr,
      label: 'Home',
      url: 'https://home.example.com',
      apiKey: 'key',
    );
    SharedPreferences.setMockInitialValues({
      'instances': jsonEncode([radarr.toJson()]),
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);

    // When
    container.read(tourActiveProvider.notifier).start();

    // Then
    expect(container.read(tourMockupProvider(InstanceType.radarr)), isFalse);
    expect(container.read(tourMockupProvider(InstanceType.sonarr)), isTrue);
    expect(
      container.read(tourMockupProvider(InstanceType.qbittorrent)),
      isTrue,
    );
    expect(
      container.read(tourMediaMockupProvider),
      isFalse,
      reason: 'calendar and queue already have Radarr data to show',
    );
  });

  test('should drop every mockup once the tour ends', () async {
    // Given
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);
    container.read(tourActiveProvider.notifier).start();

    // When
    container.read(tourActiveProvider.notifier).stop();

    // Then
    expect(container.read(tourActiveProvider), isFalse);
    for (final type in InstanceType.values) {
      expect(container.read(tourMockupProvider(type)), isFalse);
    }
    expect(container.read(tourMediaMockupProvider), isFalse);
  });
}

Future<void> _waitUntilLoaded(ProviderContainer container) async {
  container.read(instancesProvider);
  while (container.read(instancesProvider).isLoading) {
    await Future<void>.delayed(Duration.zero);
  }
}
