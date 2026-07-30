import 'dart:async';
import 'dart:convert';

import 'package:arrmate/core/network/instance_connection_resolver.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/instance_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockInstanceRepository extends Mock implements InstanceRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'should persist and restore the selected instance for each type',
    () async {
      final firstContainer = ProviderContainer();
      addTearDown(firstContainer.dispose);
      await _waitUntilLoaded(firstContainer);
      final notifier = firstContainer.read(instancesProvider.notifier);
      final firstRadarr = Instance(
        id: 'radarr-home',
        type: InstanceType.radarr,
        label: 'Home',
        url: 'https://home.example.com',
        apiKey: 'key',
      );
      final secondRadarr = Instance(
        id: 'radarr-remote',
        type: InstanceType.radarr,
        label: 'Remote',
        url: 'https://remote.example.com',
        apiKey: 'key',
      );

      await notifier.addInstance(firstRadarr);
      await notifier.addInstance(secondRadarr);
      await notifier.selectInstance(InstanceType.radarr, secondRadarr.id);

      expect(
        firstContainer.read(currentRadarrInstanceProvider),
        equals(secondRadarr),
      );

      final restoredContainer = ProviderContainer();
      addTearDown(restoredContainer.dispose);
      await _waitUntilLoaded(restoredContainer);

      expect(
        restoredContainer.read(currentRadarrInstanceProvider),
        equals(secondRadarr),
      );
    },
  );

  test('should reject selecting an instance with a different type', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);
    final notifier = container.read(instancesProvider.notifier);
    final sonarr = Instance(
      id: 'sonarr-home',
      type: InstanceType.sonarr,
      label: 'Home',
      url: 'https://home.example.com',
      apiKey: 'key',
    );
    await notifier.addInstance(sonarr);

    expect(
      () => notifier.selectInstance(InstanceType.radarr, sonarr.id),
      throwsArgumentError,
    );
  });

  test(
    'should not invalidate type instance lists when selection changes',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await _waitUntilLoaded(container);
      final notifier = container.read(instancesProvider.notifier);
      final firstRadarr = Instance(
        id: 'radarr-home',
        type: InstanceType.radarr,
        label: 'Home',
        url: 'https://home.example.com',
        apiKey: 'key',
      );
      final secondRadarr = Instance(
        id: 'radarr-remote',
        type: InstanceType.radarr,
        label: 'Remote',
        url: 'https://remote.example.com',
        apiKey: 'key',
      );
      await notifier.addInstance(firstRadarr);
      await notifier.addInstance(secondRadarr);
      var notifications = 0;
      final subscription = container.listen(
        instancesByTypeProvider(InstanceType.radarr),
        (_, _) => notifications++,
      );
      addTearDown(subscription.close);

      await notifier.selectInstance(InstanceType.radarr, secondRadarr.id);

      expect(notifications, 0);
      expect(container.read(instancesByTypeProvider(InstanceType.radarr)), [
        firstRadarr,
        secondRadarr,
      ]);
    },
  );

  test(
    'should validate matching app name before persisting an instance',
    () async {
      final repository = MockInstanceRepository();
      final container = ProviderContainer(
        overrides: [instanceRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await _waitUntilLoaded(container);
      final instance = Instance(
        id: 'radarr-home',
        type: InstanceType.radarr,
        label: 'Home',
        url: 'https://home.example.com',
        apiKey: 'key',
      );
      when(() => repository.getSystemStatus(instance)).thenAnswer(
        (_) async => const InstanceStatus(
          appName: 'RADARR',
          instanceName: 'Home Radarr',
          version: '5.0.0',
        ),
      );
      when(() => repository.getTags(instance)).thenAnswer((_) async => []);

      final validated = await container
          .read(instancesProvider.notifier)
          .validateAndSaveInstance(instance);

      expect(validated.name, 'Home Radarr');
      expect(validated.version, '5.0.0');
      expect(container.read(instancesProvider).instances, [validated]);
      final preferences = await SharedPreferences.getInstance();
      final persisted =
          jsonDecode(preferences.getString('instances')!) as List<dynamic>;
      expect(persisted, hasLength(1));
    },
  );

  test('should not persist an instance with a mismatched app name', () async {
    final repository = MockInstanceRepository();
    final container = ProviderContainer(
      overrides: [instanceRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);
    final instance = Instance(
      id: 'radarr-home',
      type: InstanceType.radarr,
      label: 'Home',
      url: 'https://home.example.com',
      apiKey: 'key',
    );
    when(() => repository.getSystemStatus(instance)).thenAnswer(
      (_) async => const InstanceStatus(
        appName: 'Sonarr',
        instanceName: 'Home Sonarr',
        version: '4.0.0',
      ),
    );
    when(() => repository.getTags(instance)).thenAnswer((_) async => []);

    await expectLater(
      container
          .read(instancesProvider.notifier)
          .validateAndSaveInstance(instance),
      throwsStateError,
    );

    expect(container.read(instancesProvider).instances, isEmpty);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('instances'), isNull);
  });

  test('should preserve an existing instance when validation fails', () async {
    final repository = MockInstanceRepository();
    final container = ProviderContainer(
      overrides: [instanceRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);
    final notifier = container.read(instancesProvider.notifier);
    final original = Instance(
      id: 'radarr-home',
      type: InstanceType.radarr,
      label: 'Home',
      url: 'https://home.example.com',
      apiKey: 'key',
    );
    final invalidUpdate = original.copyWith(url: 'https://invalid.example.com');
    await notifier.addInstance(original);
    when(() => repository.getSystemStatus(invalidUpdate)).thenAnswer(
      (_) async => const InstanceStatus(
        appName: 'Sonarr',
        instanceName: 'Wrong Server',
        version: '4.0.0',
      ),
    );
    when(() => repository.getTags(invalidUpdate)).thenAnswer((_) async => []);

    await expectLater(
      notifier.validateAndSaveInstance(invalidUpdate),
      throwsStateError,
    );

    expect(container.read(instancesProvider).instances, [original]);
    final preferences = await SharedPreferences.getInstance();
    final persisted =
        jsonDecode(preferences.getString('instances')!) as List<dynamic>;
    expect((persisted.single as Map<String, dynamic>)['url'], original.url);
  });

  test(
    'should validate and save using the URL selected for the network',
    () async {
      final repository = MockInstanceRepository();
      final resolver = InstanceConnectionResolver(
        loadConnectivity: () async => [ConnectivityResult.mobile],
        ping: (instance, uri) async => true,
        connectivityChanges: const Stream.empty(),
      );
      final container = ProviderContainer(
        overrides: [
          instanceRepositoryProvider.overrideWithValue(repository),
          instanceConnectionResolverProvider.overrideWithValue(resolver),
        ],
      );
      addTearDown(container.dispose);
      await _waitUntilLoaded(container);
      final instance = Instance(
        id: 'radarr-home',
        type: InstanceType.radarr,
        label: 'Home',
        url: 'http://192.168.1.10:7878',
        alternativeUrl: 'https://radarr.example.com',
        apiKey: 'key',
      );
      final resolvedInstance = instance.copyWith(
        activeUrl: 'https://radarr.example.com',
      );
      when(() => repository.getSystemStatus(resolvedInstance)).thenAnswer(
        (_) async => const InstanceStatus(
          appName: 'Radarr',
          instanceName: 'Home Radarr',
          version: '5.0.0',
        ),
      );
      when(
        () => repository.getTags(resolvedInstance),
      ).thenAnswer((_) async => []);

      final validated = await container
          .read(instancesProvider.notifier)
          .validateAndSaveInstance(instance);

      expect(validated.effectiveUrl, 'https://radarr.example.com');
      expect(
        container.read(currentRadarrInstanceProvider)?.effectiveUrl,
        'https://radarr.example.com',
      );
    },
  );

  test('should ignore a URL resolution from an older network', () async {
    final instance = Instance(
      id: 'radarr-home',
      type: InstanceType.radarr,
      label: 'Home',
      url: 'http://192.168.1.10:7878',
      alternativeUrl: 'https://radarr.example.com',
      apiKey: 'key',
    );
    SharedPreferences.setMockInitialValues({
      'instances': jsonEncode([instance.toJson()]),
    });
    final connectivityChanges =
        StreamController<List<ConnectivityResult>>.broadcast();
    addTearDown(connectivityChanges.close);
    final firstProbe = Completer<bool>();
    final secondProbe = Completer<bool>();
    var connectivityLoads = 0;
    var probeCalls = 0;
    final resolver = InstanceConnectionResolver(
      loadConnectivity: () async {
        connectivityLoads++;
        return connectivityLoads == 1
            ? [ConnectivityResult.wifi]
            : [ConnectivityResult.mobile];
      },
      ping: (instance, uri) {
        probeCalls++;
        return probeCalls == 1 ? firstProbe.future : secondProbe.future;
      },
      connectivityChanges: connectivityChanges.stream,
    );
    final container = ProviderContainer(
      overrides: [
        instanceConnectionResolverProvider.overrideWithValue(resolver),
      ],
    );
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);
    await _waitUntil(() => probeCalls == 1);

    connectivityChanges.add([ConnectivityResult.mobile]);
    await _waitUntil(() => probeCalls == 2);
    secondProbe.complete(true);
    await _waitUntil(
      () =>
          container.read(currentRadarrInstanceProvider)?.effectiveUrl ==
          instance.alternativeUrl,
    );
    firstProbe.complete(true);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(currentRadarrInstanceProvider)?.effectiveUrl,
      instance.alternativeUrl,
    );
  });
}

Future<void> _waitUntilLoaded(ProviderContainer container) async {
  container.read(instancesProvider);
  while (container.read(instancesProvider).isLoading) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Condition was not met before the timeout');
    }
    await Future<void>.delayed(Duration.zero);
  }
}
