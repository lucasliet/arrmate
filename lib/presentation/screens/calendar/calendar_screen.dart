import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/models.dart';
import '../../providers/instances_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/notification_icon_button.dart';
import '../../tour/app_tour_keys.dart';
import 'providers/calendar_provider.dart';
import 'widgets/calendar_filter_bar.dart';
import 'widgets/calendar_item.dart';

/// Displays a timeline of upcoming releases (movies and episodes).
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(filteredCalendarProvider);
    final filters = ref.watch(calendarFiltersProvider);
    final loadStatus = ref.watch(calendarLoadStatusProvider);
    final instances = ref
        .watch(instancesProvider)
        .instances
        .where(
          (instance) =>
              instance.type == InstanceType.radarr ||
              instance.type == InstanceType.sonarr,
        )
        .toList();
    final filtersNotifier = ref.read(calendarFiltersProvider.notifier);
    final tourKeys = ref.watch(appTourKeysProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar', key: tourKeys.calendarTitleKey),
        actions: const [NotificationIconButton()],
      ),
      body: Column(
        children: [
          CalendarFilterBar(
            instances: instances,
            filters: filters,
            onInstanceChanged: filtersNotifier.selectInstance,
            onMediaTypeChanged: filtersNotifier.selectMediaType,
            onOnlyMonitoredChanged: filtersNotifier.setOnlyMonitored,
            onOnlyPremieresChanged: filtersNotifier.setOnlyPremieres,
            onHideSpecialsChanged: filtersNotifier.setHideSpecials,
            onReset: filtersNotifier.reset,
          ),
          if (loadStatus.hasFailures)
            _CalendarFailureBanner(
              failures: loadStatus.failures,
              onRetry: () => ref.read(calendarProvider.notifier).refresh(),
            ),
          Expanded(
            child: calendarState.when(
              skipLoadingOnRefresh: true,
              data: (events) => _buildCalendarContent(
                context,
                ref,
                events,
                filters,
                loadStatus,
                instances.isNotEmpty,
              ),
              error: (error, stack) => ErrorDisplay(
                message: error.toString(),
                onRetry: () => ref.read(calendarProvider.notifier).refresh(),
              ),
              loading: () =>
                  const LoadingIndicator(message: 'Loading calendar...'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContent(
    BuildContext context,
    WidgetRef ref,
    List<CalendarEvent> events,
    CalendarFilters filters,
    CalendarLoadStatus loadStatus,
    bool hasInstances,
  ) {
    final grouped = _groupByDate(events);
    final sortedDates = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () => ref.read(calendarProvider.notifier).refresh(),
      child: ListView(
        key: const ValueKey('calendar-events-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (events.isEmpty)
            SizedBox(
              height: 320,
              child: EmptyState(
                icon: Icons.calendar_today,
                title: filters.isActive
                    ? 'No matching events'
                    : 'No upcoming events',
                subtitle: filters.isActive
                    ? 'Adjust the calendar filters to see more events.'
                    : 'Check back later or add content to your libraries.',
              ),
            )
          else
            ...sortedDates.map((date) {
              final dateEvents = grouped[date]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(context, date),
                  ...dateEvents.map((event) => CalendarItem(event: event)),
                  const SizedBox(height: 8),
                ],
              );
            }),
          if (hasInstances)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Center(
                child: loadStatus.isLoadingMore
                    ? const CircularProgressIndicator(
                        key: ValueKey('calendar-loading-more'),
                      )
                    : OutlinedButton.icon(
                        key: const ValueKey('calendar-load-more'),
                        onPressed: () =>
                            ref.read(calendarProvider.notifier).loadMore(),
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Load more'),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Map<DateTime, List<CalendarEvent>> _groupByDate(List<CalendarEvent> events) {
    final groups = <DateTime, List<CalendarEvent>>{};
    for (var event in events) {
      final localDate = event.releaseDate.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      if (groups[date] == null) groups[date] = [];
      groups[date]!.add(event);
    }
    return groups;
  }

  Widget _buildDateHeader(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String label;
    if (date == today) {
      label = 'Today';
    } else if (date == today.add(const Duration(days: 1))) {
      label = 'Tomorrow';
    } else {
      label = DateFormat('EEEE, MMMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CalendarFailureBanner extends StatelessWidget {
  final List<CalendarInstanceFailure> failures;
  final VoidCallback onRetry;

  const _CalendarFailureBanner({required this.failures, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey('calendar-partial-failure'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Some instances could not be loaded',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
          ...failures.map(
            (failure) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${failure.instanceLabel} (${failure.instanceType.label}): ${failure.message}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
