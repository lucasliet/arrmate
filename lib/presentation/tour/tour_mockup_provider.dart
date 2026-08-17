import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/models.dart';
import '../providers/instances_provider.dart';

/// Tracks whether the guided tour is currently running.
///
/// The flag lives in memory only: it is raised when the tour starts and
/// lowered as soon as the tour is finished or skipped, so nothing about the
/// tour survives a restart.
final tourActiveProvider = NotifierProvider<TourActiveNotifier, bool>(
  TourActiveNotifier.new,
);

/// Notifier backing [tourActiveProvider].
class TourActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Marks the tour as running, which enables the onboarding mockups.
  void start() => state = true;

  /// Marks the tour as finished, which removes the onboarding mockups.
  void stop() => state = false;
}

/// Whether the screens backed by [type] should paint sample content in place
/// of their empty states.
///
/// Mockups only show while the tour runs and no instance of [type] is
/// configured, i.e. exactly when a tour step would otherwise point at an
/// element that cannot exist yet. The sample content is purely visual: it is
/// never persisted, never sent to a server, and disappears with the tour.
final tourMockupProvider = Provider.family<bool, InstanceType>((ref, type) {
  if (!ref.watch(tourActiveProvider)) return false;
  return ref.watch(instancesByTypeProvider(type)).isEmpty;
});

/// Whether the screens aggregating Radarr and Sonarr data (calendar, queue)
/// should paint sample content.
///
/// Real data wins as soon as either service is configured, so a partially
/// configured setup never mixes sample entries with server entries.
final tourMediaMockupProvider = Provider<bool>((ref) {
  return ref.watch(tourMockupProvider(InstanceType.radarr)) &&
      ref.watch(tourMockupProvider(InstanceType.sonarr));
});
