import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/models.dart';
import '../../adaptive/content_layout.dart';
import '../../providers/instances_provider.dart';
import '../../tour/app_tour_keys.dart';
import '../../tour/tour_mock_data.dart';
import '../../tour/tour_mockup_provider.dart';
import '../../tour/widgets/tour_mockup_banner.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/notification_icon_button.dart';
import 'providers/calendar_provider.dart';
import 'widgets/calendar_filter_bar.dart';
import 'widgets/calendar_item.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../l10n/labels.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = ContentLayout(constraints.maxWidth).hasWideSections;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              context.l10n.labelTabCalendar,
              key: tourKeys.calendarTitleKey,
            ),
            toolbarHeight: isWide ? 88 : null,
            titleSpacing: isWide ? 32 : null,
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
                    message: describeError(error, context.l10n),
                    onRetry: () =>
                        ref.read(calendarProvider.notifier).refresh(),
                  ),
                  loading: () =>
                      LoadingIndicator(message: context.l10n.calendarLoading),
                ),
              ),
            ],
          ),
        );
      },
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
    // While the tour runs with no Radarr/Sonarr instance the calendar has
    // nothing to show, so it paints inert sample releases the tour can point
    // at. They disappear with the tour, restoring the real empty state.
    final showsTourMockup =
        events.isEmpty &&
        !filters.isActive &&
        ref.watch(tourMediaMockupProvider);
    final visibleEvents = showsTourMockup
        ? TourMockData.calendarEvents()
        : events;
    final tourKeys = ref.watch(appTourKeysProvider);
    final grouped = _groupByDate(visibleEvents);
    final sortedDates = grouped.keys.toList()..sort();
    final firstEvent = sortedDates.isEmpty
        ? null
        : grouped[sortedDates.first]!.first;
    final dateSections = sortedDates.map((date) {
      final dateEvents = grouped[date]!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(context, date),
          ...dateEvents.map((event) {
            final item = CalendarItem(
              key: identical(event, firstEvent)
                  ? tourKeys.calendarListKey
                  : null,
              event: event,
            );
            return showsTourMockup ? TourMockup(child: item) : item;
          }),
          const SizedBox(height: 8),
        ],
      );
    }).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(calendarProvider.notifier).refresh(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = ContentLayout(constraints.maxWidth).hasWideSections;
          return ListView(
            key: const ValueKey('calendar-events-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (showsTourMockup)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TourMockupBanner(),
                ),
              if (visibleEvents.isEmpty)
                SizedBox(
                  height: 320,
                  child: EmptyState(
                    icon: Icons.calendar_today,
                    title: filters.isActive
                        ? context.l10n.calendarNoMatchingEvents
                        : context.l10n.calendarNoUpcomingEvents,
                    subtitle: filters.isActive
                        ? context.l10n.calendarNoMatchingEventsHint
                        : context.l10n.calendarNoUpcomingEventsHint,
                  ),
                )
              else if (isWide)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      for (final section in dateSections)
                        SizedBox(
                          width: (constraints.maxWidth - 88) / 2,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            margin: EdgeInsets.zero,
                            child: section,
                          ),
                        ),
                    ],
                  ),
                )
              else
                ...dateSections,
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
                            label: Text(context.l10n.calendarLoadMore),
                          ),
                  ),
                ),
            ],
          );
        },
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
      label = context.l10n.calendarToday;
    } else if (date == today.add(const Duration(days: 1))) {
      label = context.l10n.calendarTomorrow;
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
                  context.l10n.widgetsSomeInstancesFailed,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
          ...failures.map(
            (failure) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                // Every calendar failure carries the same fixed English
                // message, so the translated equivalent is shown instead.
                '${failure.instanceLabel} (${failure.instanceType.label}): '
                '${context.l10n.calendarDataLoadFailed}',
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
