import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/common_widgets.dart';
import 'providers/activity_provider.dart';
import 'providers/history_provider.dart';
import 'widgets/queue_list_item.dart';
import 'history_screen.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Queue'),
              Tab(text: 'History'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(queueProvider);
                ref.invalidate(activityHistoryProvider);
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _QueueTab(),
            const HistoryScreen(),
          ],
        ),
      ),
    );
  }
}

class _QueueTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueProvider);

    return queueState.when(
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(queueProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: const EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'Queue is empty',
                  subtitle: 'No active downloads at the moment.',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(queueProvider),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return QueueListItem(item: items[index]);
            },
          ),
        );
      },
      error: (error, stack) => ErrorDisplay(
        message: error.toString(),
        onRetry: () => ref.refresh(queueProvider),
      ),
      loading: () => const LoadingIndicator(message: 'Loading queue...'),
    );
  }
}
