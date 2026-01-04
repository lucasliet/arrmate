import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../widgets/common_widgets.dart';
import 'providers/calendar_provider.dart';
import 'widgets/calendar_item.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: calendarState.when(
        data: (events) {
          if (events.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.read(calendarProvider.notifier).refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: const EmptyState(
                    icon: Icons.calendar_today,
                    title: 'No upcoming events',
                    subtitle:
                        'Check back later or add content to your libraries.',
                  ),
                ),
              ),
            );
          }

          // Group by date
          final grouped = _groupByDate(events);
          final sortedDates = grouped.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(calendarProvider.notifier).refresh(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final dateEvents = grouped[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateHeader(context, date),
                    ...dateEvents.map((e) => CalendarItem(event: e)),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          );
        },
        error: (error, stack) => ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.read(calendarProvider.notifier).refresh(),
        ),
        loading: () => const LoadingIndicator(message: 'Loading calendar...'),
      ),
    );
  }

  Map<DateTime, List<CalendarEvent>> _groupByDate(List<CalendarEvent> events) {
    final groups = <DateTime, List<CalendarEvent>>{};
    for (var event in events) {
      final date = DateTime(
        event.releaseDate.year,
        event.releaseDate.month,
        event.releaseDate.day,
      );
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
