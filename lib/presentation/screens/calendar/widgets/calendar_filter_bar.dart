import 'package:flutter/material.dart';

import '../../../../domain/models/models.dart';
import '../providers/calendar_provider.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../l10n/labels.dart';

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
            tooltip: context.l10n.calendarFilterByInstance,
            initialValue: filters.instanceId ?? _allInstancesValue,
            onSelected: (value) =>
                onInstanceChanged(value == _allInstancesValue ? null : value),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: _allInstancesValue,
                child: Text(context.l10n.calendarAnyInstance),
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
              label: Text(_selectedInstanceLabel(context.l10n)),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<CalendarMediaType>(
            key: const ValueKey('calendar-media-filter'),
            tooltip: context.l10n.calendarFilterByMediaType,
            initialValue: filters.mediaType,
            onSelected: onMediaTypeChanged,
            itemBuilder: (context) => CalendarMediaType.values
                .map(
                  (type) => PopupMenuItem(
                    value: type,
                    child: Text(type.localizedLabel(context.l10n)),
                  ),
                )
                .toList(),
            child: Chip(
              avatar: const Icon(Icons.video_library_outlined, size: 18),
              label: Text(filters.mediaType.localizedLabel(context.l10n)),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const ValueKey('calendar-monitored-filter'),
            avatar: const Icon(Icons.bookmark_outline, size: 18),
            label: Text(context.l10n.commonMonitored),
            selected: filters.onlyMonitored,
            onSelected: onOnlyMonitoredChanged,
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const ValueKey('calendar-premieres-filter'),
            avatar: const Icon(Icons.play_circle_outline, size: 18),
            label: Text(context.l10n.calendarPremieres),
            selected: filters.onlyPremieres,
            onSelected: onOnlyPremieresChanged,
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const ValueKey('calendar-specials-filter'),
            avatar: const Icon(Icons.star_outline, size: 18),
            label: Text(context.l10n.calendarHideSpecials),
            selected: filters.hideSpecials,
            onSelected: onHideSpecialsChanged,
          ),
          if (filters.isActive) ...[
            const SizedBox(width: 8),
            ActionChip(
              key: const ValueKey('calendar-reset-filters'),
              avatar: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: Text(context.l10n.commonReset),
              onPressed: onReset,
            ),
          ],
        ],
      ),
    );
  }

  String _selectedInstanceLabel(AppLocalizations l10n) {
    final selectedId = filters.instanceId;
    if (selectedId == null) {
      return l10n.calendarInstanceAny;
    }
    for (final instance in instances) {
      if (instance.id == selectedId) {
        return l10n.calendarInstanceNamed(instance.label);
      }
    }
    return l10n.calendarInstanceAny;
  }
}
