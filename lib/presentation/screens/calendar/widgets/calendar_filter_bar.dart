import 'package:flutter/material.dart';

import '../../../../domain/models/models.dart';
import '../providers/calendar_provider.dart';

/// Displays the active calendar filters as an interactive horizontal bar.
class CalendarFilterBar extends StatelessWidget {
  static const _allInstancesValue = '__all_instances__';

  /// Configured Radarr and Sonarr instances available for filtering.
  final List<Instance> instances;

  /// Current filter values.
  final CalendarFilters filters;

  /// Called when the selected instance changes.
  final ValueChanged<String?> onInstanceChanged;

  /// Called when the selected media type changes.
  final ValueChanged<CalendarMediaType> onMediaTypeChanged;

  /// Called when the monitored-only filter changes.
  final ValueChanged<bool> onOnlyMonitoredChanged;

  /// Called when the premiere-only filter changes.
  final ValueChanged<bool> onOnlyPremieresChanged;

  /// Called when the special episode filter changes.
  final ValueChanged<bool> onHideSpecialsChanged;

  /// Called when every filter should be reset.
  final VoidCallback onReset;

  const CalendarFilterBar({
    super.key,
    required this.instances,
    required this.filters,
    required this.onInstanceChanged,
    required this.onMediaTypeChanged,
    required this.onOnlyMonitoredChanged,
    required this.onOnlyPremieresChanged,
    required this.onHideSpecialsChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          PopupMenuButton<String>(
            key: const ValueKey('calendar-instance-filter'),
            tooltip: 'Filter by instance',
            initialValue: filters.instanceId ?? _allInstancesValue,
            onSelected: (value) =>
                onInstanceChanged(value == _allInstancesValue ? null : value),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: _allInstancesValue,
                child: Text('Any instance'),
              ),
              ...instances.map(
                (instance) => PopupMenuItem<String>(
                  value: instance.id,
                  child: Text(instance.label),
                ),
              ),
            ],
            child: Chip(
              avatar: const Icon(Icons.dns_outlined, size: 18),
              label: Text('Instance: ${_selectedInstanceLabel()}'),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<CalendarMediaType>(
            key: const ValueKey('calendar-media-filter'),
            tooltip: 'Filter by media type',
            initialValue: filters.mediaType,
            onSelected: onMediaTypeChanged,
            itemBuilder: (context) => CalendarMediaType.values
                .map(
                  (type) => PopupMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
            child: Chip(
              avatar: const Icon(Icons.video_library_outlined, size: 18),
              label: Text(filters.mediaType.label),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const ValueKey('calendar-monitored-filter'),
            avatar: const Icon(Icons.bookmark_outline, size: 18),
            label: const Text('Monitored'),
            selected: filters.onlyMonitored,
            onSelected: onOnlyMonitoredChanged,
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const ValueKey('calendar-premieres-filter'),
            avatar: const Icon(Icons.play_circle_outline, size: 18),
            label: const Text('Premieres'),
            selected: filters.onlyPremieres,
            onSelected: onOnlyPremieresChanged,
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const ValueKey('calendar-specials-filter'),
            avatar: const Icon(Icons.star_outline, size: 18),
            label: const Text('Hide specials'),
            selected: filters.hideSpecials,
            onSelected: onHideSpecialsChanged,
          ),
          if (filters.isActive) ...[
            const SizedBox(width: 8),
            ActionChip(
              key: const ValueKey('calendar-reset-filters'),
              avatar: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Reset'),
              onPressed: onReset,
            ),
          ],
        ],
      ),
    );
  }

  String _selectedInstanceLabel() {
    final selectedId = filters.instanceId;
    if (selectedId == null) {
      return 'Any';
    }
    for (final instance in instances) {
      if (instance.id == selectedId) {
        return instance.label;
      }
    }
    return 'Any';
  }
}
