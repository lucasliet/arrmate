import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/instance_connection_resolver.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/remote_notification_setup_service.dart';
import '../../domain/models/models.dart';
import 'data_providers.dart';
import 'settings_provider.dart';

/// Provider for resolving the reachable URL of configured instances.
final instanceConnectionResolverProvider = Provider<InstanceConnectionResolver>(
  (ref) => InstanceConnectionResolver(),
);

/// Provider that manages the list of configured [Instance]s.
final instancesProvider = NotifierProvider<InstancesNotifier, InstancesState>(
  () {
    return InstancesNotifier();
  },
);

/// Provider that returns the currently active Radarr instance.
final currentRadarrInstanceProvider = Provider<Instance?>((ref) {
  return ref.watch(currentInstanceProvider(InstanceType.radarr));
});

/// Provider that returns the currently active Sonarr instance.
final currentSonarrInstanceProvider = Provider<Instance?>((ref) {
  return ref.watch(currentInstanceProvider(InstanceType.sonarr));
});

/// Provider that returns the currently active qBittorrent instance.
final currentQBittorrentInstanceProvider = Provider<Instance?>((ref) {
  return ref.watch(currentInstanceProvider(InstanceType.qbittorrent));
});

/// Provider that returns all configured instances of [type].
final instancesByTypeProvider = Provider.family<List<Instance>, InstanceType>((
  ref,
  type,
) {
  final instances = ref.watch(
    instancesProvider.select((state) => state.instances),
  );
  return instances.where((instance) => instance.type == type).toList();
});

/// Provider that returns the selected instance for [type].
final currentInstanceProvider = Provider.family<Instance?, InstanceType>((
  ref,
  type,
) {
  final state = ref.watch(instancesProvider);
  final instances = state.instances.where((instance) => instance.type == type);
  final selectedId = state.selectedInstanceIds[type];

  if (selectedId != null) {
    final selected = instances
        .where((instance) => instance.id == selectedId)
        .firstOrNull;
    if (selected != null) {
      return selected;
    }
  }

  return instances.firstOrNull;
});

/// State for the [InstancesNotifier].
class InstancesState {
  final List<Instance> instances;
  final Map<InstanceType, String> selectedInstanceIds;
  final bool isLoading;

  const InstancesState({
    this.instances = const [],
    this.selectedInstanceIds = const {},
    this.isLoading = true,
  });

  bool get hasRadarr => instances.any((i) => i.type == InstanceType.radarr);
  bool get hasSonarr => instances.any((i) => i.type == InstanceType.sonarr);
  bool get isEmpty => instances.isEmpty;

  InstancesState copyWith({
    List<Instance>? instances,
    Map<InstanceType, String>? selectedInstanceIds,
    bool? isLoading,
  }) {
    return InstancesState(
      instances: instances ?? this.instances,
      selectedInstanceIds: selectedInstanceIds ?? this.selectedInstanceIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Manages the CRUD operations for [Instance]s using SharedPreferences persistence.
class InstancesNotifier extends Notifier<InstancesState> {
  static const _instancesKey = 'instances';
  static const _selectedInstanceKeys = {
    InstanceType.radarr: 'selected_radarr_instance_id',
    InstanceType.sonarr: 'selected_sonarr_instance_id',
    InstanceType.qbittorrent: 'selected_qbittorrent_instance_id',
  };
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  int _resolutionGeneration = 0;

  @override
  InstancesState build() {
    logger.debug('[InstancesNotifier] Initializing instances provider');
    ref.onDispose(() {
      _resolutionGeneration++;
      _connectivitySubscription?.cancel();
    });
    _loadInstances();
    return const InstancesState();
  }

  /// Loads persisted instances from SharedPreferences.
  Future<void> _loadInstances() async {
    final prefs = await SharedPreferences.getInstance();
    final instancesJson = prefs.getString(_instancesKey);

    if (instancesJson != null) {
      try {
        final List<dynamic> decoded = json.decode(instancesJson);
        final instances = decoded
            .map((e) => Instance.fromJson(e as Map<String, dynamic>))
            .toList();
        final selectedInstanceIds = <InstanceType, String>{};
        for (final entry in _selectedInstanceKeys.entries) {
          final selectedId = prefs.getString(entry.value);
          if (selectedId != null) {
            selectedInstanceIds[entry.key] = selectedId;
          }
        }
        logger.info('[InstancesNotifier] Loaded ${instances.length} instances');
        state = state.copyWith(
          instances: instances,
          selectedInstanceIds: selectedInstanceIds,
          isLoading: false,
        );
        _syncConnectionMonitoring();
        _refreshResolvedUrls();
      } catch (e, st) {
        logger.error('[InstancesNotifier] Error decoding instances', e, st);
        state = state.copyWith(isLoading: false);
      }
    } else {
      state = state.copyWith(isLoading: false);
      _syncConnectionMonitoring();
    }
  }

  /// Persists the current list of instances to SharedPreferences.
  Future<void> _saveInstances() async {
    final prefs = await SharedPreferences.getInstance();
    final instancesJson = json.encode(
      state.instances.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_instancesKey, instancesJson);
  }

  /// Adds a new instance to the list and persists it.
  ///
  /// If notifications are enabled in global settings, it automatically
  /// triggers the auto-configuration for this new instance.
  Future<void> addInstance(Instance instance) async {
    logger.info(
      '[InstancesNotifier] Adding instance: ${instance.name ?? instance.id}',
    );
    state = state.copyWith(instances: [...state.instances, instance]);
    await _saveInstances();
    _syncConnectionMonitoring();

    // Auto-configure notifications if enabled
    final settings = ref.read(settingsProvider);
    if (settings.notifications.enabled &&
        settings.notifications.ntfyTopic != null) {
      logger.info(
        '[InstancesNotifier] Auto-configuring notifications for new instance',
      );
      final notificationService = ref.read(remoteNotificationServiceProvider);
      // We run this in background (no await) to not block the UI,
      // but we log failures inside the service.
      notificationService.configureInstance(instance).catchError((e, st) {
        logger.error(
          '[InstancesNotifier] Auto-config failed for new instance',
          e,
          st,
        );
        return NotificationSetupResult.failure(e.toString());
      });
    }
  }

  /// Updates an existing instance in the list.
  Future<void> updateInstance(Instance instance) async {
    final instances = state.instances.map((i) {
      return i.id == instance.id ? instance : i;
    }).toList();
    state = state.copyWith(instances: instances);
    await _saveInstances();
    _syncConnectionMonitoring();
  }

  /// Removes an instance by its ID.
  Future<void> removeInstance(String id) async {
    logger.info('[InstancesNotifier] Removing instance: $id');
    final instances = state.instances.where((i) => i.id != id).toList();
    final selectedInstanceIds = Map<InstanceType, String>.from(
      state.selectedInstanceIds,
    )..removeWhere((_, selectedId) => selectedId == id);
    state = state.copyWith(
      instances: instances,
      selectedInstanceIds: selectedInstanceIds,
    );
    await _saveInstances();
    await _saveSelectedInstances();
    _syncConnectionMonitoring();
  }

  /// Selects the active configured instance for [type].
  Future<void> selectInstance(InstanceType type, String id) async {
    final isConfigured = state.instances.any(
      (instance) => instance.id == id && instance.type == type,
    );
    if (!isConfigured) {
      throw ArgumentError.value(
        id,
        'id',
        'Instance is not configured for type',
      );
    }

    final selectedInstanceIds = Map<InstanceType, String>.from(
      state.selectedInstanceIds,
    )..[type] = id;
    state = state.copyWith(selectedInstanceIds: selectedInstanceIds);
    await _saveSelectedInstances();
  }

  Future<void> _saveSelectedInstances() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _selectedInstanceKeys.entries) {
      final selectedId = state.selectedInstanceIds[entry.key];
      if (selectedId == null) {
        await prefs.remove(entry.value);
      } else {
        await prefs.setString(entry.value, selectedId);
      }
    }
  }

  /// Returns an instance by its ID, or null if not found.
  Instance? getInstanceById(String id) {
    return state.instances.where((i) => i.id == id).firstOrNull;
  }

  /// Validates [instance] and returns it with refreshed server metadata.
  Future<Instance> validateInstance(Instance instance) async {
    logger.debug(
      '[InstancesNotifier] Validating instance data: ${instance.name ?? instance.id}',
    );

    try {
      final resolvedInstance = await ref
          .read(instanceConnectionResolverProvider)
          .resolve(instance);
      final instanceRepo = ref.read(instanceRepositoryProvider);
      final results = await Future.wait<dynamic>([
        instanceRepo.getSystemStatus(resolvedInstance),
        instanceRepo.getTags(resolvedInstance),
      ]);

      final status = results[0] as InstanceStatus;
      final tags = (results[1] as List).cast<Tag>();
      final expectedAppName = resolvedInstance.type.label.toLowerCase();
      final actualAppName = status.appName.trim().toLowerCase();
      if (actualAppName != expectedAppName) {
        throw StateError(
          'Expected ${instance.type.label}, but connected to ${status.appName}',
        );
      }

      return resolvedInstance.copyWith(
        version: status.version,
        name: status.instanceName,
        tags: tags,
      );
    } catch (e, st) {
      logger.error(
        '[InstancesNotifier] Error validating instance: ${instance.name ?? instance.id}',
        e,
        st,
      );
      rethrow;
    }
  }

  /// Validates and persists [instance] as a single transactional operation.
  Future<Instance> validateAndSaveInstance(Instance instance) async {
    final validatedInstance = await validateInstance(instance);
    final isEditing = state.instances.any(
      (existing) => existing.id == validatedInstance.id,
    );

    if (isEditing) {
      await updateInstance(validatedInstance);
    } else {
      await addInstance(validatedInstance);
    }

    return validatedInstance;
  }

  void _syncConnectionMonitoring() {
    final hasAlternativeUrl = state.instances.any(
      (instance) => instance.alternativeUrl?.trim().isNotEmpty ?? false,
    );
    if (!hasAlternativeUrl) {
      _connectivitySubscription?.cancel();
      _connectivitySubscription = null;
      return;
    }
    if (_connectivitySubscription != null) {
      return;
    }

    _connectivitySubscription = ref
        .read(instanceConnectionResolverProvider)
        .connectivityChanges
        .listen(
          (_) => _refreshResolvedUrls(),
          onError: (Object error, StackTrace stackTrace) {
            logger.error(
              '[InstancesNotifier] Connectivity monitoring failed',
              error,
              stackTrace,
            );
          },
        );
  }

  Future<void> _refreshResolvedUrls() async {
    final generation = ++_resolutionGeneration;
    final resolver = ref.read(instanceConnectionResolverProvider);
    final candidates = state.instances
        .where(
          (instance) => instance.alternativeUrl?.trim().isNotEmpty ?? false,
        )
        .toList();

    final resolutions = await Future.wait<MapEntry<Instance, Instance?>>(
      candidates.map((candidate) async {
        try {
          final resolved = await resolver.resolve(candidate);
          return MapEntry<Instance, Instance?>(candidate, resolved);
        } catch (error, stackTrace) {
          logger.warning(
            '[InstancesNotifier] No reachable URL for instance ${candidate.id}',
            error,
            stackTrace,
          );
          return MapEntry<Instance, Instance?>(candidate, null);
        }
      }),
    );
    if (generation != _resolutionGeneration) {
      return;
    }

    var instances = state.instances;
    for (final resolution in resolutions) {
      final candidate = resolution.key;
      final resolved = resolution.value;
      if (resolved == null) {
        continue;
      }
      instances = instances.map((current) {
        if (current.id != candidate.id ||
            current.url != candidate.url ||
            current.alternativeUrl != candidate.alternativeUrl) {
          return current;
        }
        return current.copyWith(activeUrl: resolved.activeUrl);
      }).toList();
    }
    state = state.copyWith(instances: instances);
  }
}
