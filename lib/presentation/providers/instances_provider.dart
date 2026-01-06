import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../domain/models/models.dart';
import 'data_providers.dart';

/// Provider that manages the list of configured [Instance]s.
final instancesProvider = NotifierProvider<InstancesNotifier, InstancesState>(
  () {
    return InstancesNotifier();
  },
);

/// Provider that returns the currently active Radarr instance.
final currentRadarrInstanceProvider = Provider<Instance?>((ref) {
  final state = ref.watch(instancesProvider);
  return state.instances
      .where((i) => i.type == InstanceType.radarr)
      .cast<Instance?>()
      .firstOrNull;
});

/// Provider that returns the currently active Sonarr instance.
final currentSonarrInstanceProvider = Provider<Instance?>((ref) {
  final state = ref.watch(instancesProvider);
  return state.instances
      .where((i) => i.type == InstanceType.sonarr)
      .cast<Instance?>()
      .firstOrNull;
});

/// State for the [InstancesNotifier].
class InstancesState {
  final List<Instance> instances;
  final bool isLoading;

  const InstancesState({this.instances = const [], this.isLoading = true});

  bool get hasRadarr => instances.any((i) => i.type == InstanceType.radarr);
  bool get hasSonarr => instances.any((i) => i.type == InstanceType.sonarr);
  bool get isEmpty => instances.isEmpty;

  InstancesState copyWith({List<Instance>? instances, bool? isLoading}) {
    return InstancesState(
      instances: instances ?? this.instances,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Manages the CRUD operations for [Instance]s using SharedPreferences persistence.
class InstancesNotifier extends Notifier<InstancesState> {
  static const _instancesKey = 'instances';

  @override
  InstancesState build() {
    logger.debug('[InstancesNotifier] Initializing instances provider');
    _loadInstances();
    return const InstancesState();
  }

  Future<void> _loadInstances() async {
    final prefs = await SharedPreferences.getInstance();
    final instancesJson = prefs.getString(_instancesKey);

    if (instancesJson != null) {
      try {
        final List<dynamic> decoded = json.decode(instancesJson);
        final instances = decoded
            .map((e) => Instance.fromJson(e as Map<String, dynamic>))
            .toList();
        logger.info('[InstancesNotifier] Loaded ${instances.length} instances');
        state = state.copyWith(instances: instances, isLoading: false);
      } catch (e, st) {
        logger.error('[InstancesNotifier] Error decoding instances', e, st);
        state = state.copyWith(isLoading: false);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _saveInstances() async {
    final prefs = await SharedPreferences.getInstance();
    final instancesJson = json.encode(
      state.instances.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_instancesKey, instancesJson);
  }

  /// Adds a new instance to the list and persists it.
  Future<void> addInstance(Instance instance) async {
    logger.info(
      '[InstancesNotifier] Adding instance: ${instance.name ?? instance.id}',
    );
    state = state.copyWith(instances: [...state.instances, instance]);
    await _saveInstances();
  }

  /// Updates an existing instance in the list.
  Future<void> updateInstance(Instance instance) async {
    final instances = state.instances.map((i) {
      return i.id == instance.id ? instance : i;
    }).toList();
    state = state.copyWith(instances: instances);
    await _saveInstances();
  }

  /// Removes an instance by its ID.
  Future<void> removeInstance(String id) async {
    logger.info('[InstancesNotifier] Removing instance: $id');
    final instances = state.instances.where((i) => i.id != id).toList();
    state = state.copyWith(instances: instances);
    await _saveInstances();
  }

  /// Helper to find an instance by ID.
  Instance? getInstanceById(String id) {
    return state.instances.where((i) => i.id == id).firstOrNull;
  }

  /// Connects to the instance to fetch system status and tags, then updates it.
  /// Throws if connection or validation fails.
  Future<Instance> validateAndCacheInstanceData(Instance instance, ref) async {
    logger.debug(
      '[InstancesNotifier] Validating instance data: ${instance.name ?? instance.id}',
    );
    final instanceRepo = ref.read(instanceRepositoryProvider);

    try {
      final results = await Future.wait<dynamic>([
        instanceRepo.getSystemStatus(instance),
        instanceRepo.getTags(instance),
      ]);

      final status = results[0] as InstanceStatus;
      final tags = (results[1] as List).cast<Tag>();

      final updatedInstance = instance.copyWith(
        version: status.version,
        name: status.instanceName,
        tags: tags,
      );

      await updateInstance(updatedInstance);

      return updatedInstance;
    } catch (e, st) {
      logger.error(
        '[InstancesNotifier] Error validating instance: ${instance.name ?? instance.id}',
        e,
        st,
      );
      rethrow;
    }
  }
}
