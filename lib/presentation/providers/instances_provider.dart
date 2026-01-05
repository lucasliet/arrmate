import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../domain/models/models.dart';
import 'data_providers.dart';

final instancesProvider = NotifierProvider<InstancesNotifier, InstancesState>(
  () {
    return InstancesNotifier();
  },
);

final currentRadarrInstanceProvider = Provider<Instance?>((ref) {
  final state = ref.watch(instancesProvider);
  return state.instances
      .where((i) => i.type == InstanceType.radarr)
      .cast<Instance?>()
      .firstOrNull;
});

final currentSonarrInstanceProvider = Provider<Instance?>((ref) {
  final state = ref.watch(instancesProvider);
  return state.instances
      .where((i) => i.type == InstanceType.sonarr)
      .cast<Instance?>()
      .firstOrNull;
});

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

class InstancesNotifier extends Notifier<InstancesState> {
  static const _instancesKey = 'instances';

  @override
  InstancesState build() {
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
        state = state.copyWith(instances: instances, isLoading: false);
      } catch (_) {
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

  Future<void> addInstance(Instance instance) async {
    state = state.copyWith(instances: [...state.instances, instance]);
    await _saveInstances();
  }

  Future<void> updateInstance(Instance instance) async {
    final instances = state.instances.map((i) {
      return i.id == instance.id ? instance : i;
    }).toList();
    state = state.copyWith(instances: instances);
    await _saveInstances();
  }

  Future<void> removeInstance(String id) async {
    final instances = state.instances.where((i) => i.id != id).toList();
    state = state.copyWith(instances: instances);
    await _saveInstances();
  }

  Instance? getInstanceById(String id) {
    return state.instances.where((i) => i.id == id).firstOrNull;
  }

  Future<Instance> validateAndCacheInstanceData(Instance instance, ref) async {
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
    } catch (e) {
      rethrow;
    }
  }
}
