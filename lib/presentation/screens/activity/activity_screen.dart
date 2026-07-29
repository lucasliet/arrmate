import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/models.dart';
import '../../providers/instances_provider.dart';
import '../../tour/app_tour_keys.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/instance_load_failure_banner.dart';
import '../../widgets/notification_icon_button.dart';
import 'history_screen.dart';
import 'providers/activity_provider.dart';
import 'providers/history_provider.dart';
import 'providers/qbittorrent_provider.dart';
import 'qbittorrent_tab.dart';
import 'widgets/queue_list_item.dart';
import 'widgets/queue_options_sheet.dart';

/// Main screen showing current download queue and history.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qbittorrentInstance = ref.watch(currentQBittorrentInstanceProvider);
    final hasQBittorrent = qbittorrentInstance != null;
    final tourKeys = ref.watch(appTourKeysProvider);

    return DefaultTabController(
      length: hasQBittorrent ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity'),
          bottom: TabBar(
            key: tourKeys.activityTabBarKey,
            tabs: [
              const Tab(text: 'Queue'),
              const Tab(text: 'History'),
              if (hasQBittorrent) const Tab(text: 'Torrents'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(queueProvider);
                ref.invalidate(activityHistoryProvider);
                if (hasQBittorrent) {
                  ref.invalidate(qbittorrentTorrentsProvider);
                }
              },
            ),
            const NotificationIconButton(),
          ],
        ),
        body: TabBarView(
          children: [
            const _QueueTab(),
            const HistoryScreen(),
            if (hasQBittorrent) const QBittorrentTab(),
          ],
        ),
      ),
    );
  }
}

class _QueueTab extends ConsumerStatefulWidget {
  const _QueueTab();

  @override
  ConsumerState<_QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends ConsumerState<_QueueTab> {
  QueueQuery _query = const QueueQuery();

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(queueProvider);
    final failures = ref.watch(queueFailuresProvider);

    return Column(
      children: [
        if (failures.isNotEmpty)
          InstanceLoadFailureBanner(
            failures: failures,
            onRetry: () => ref.read(queueProvider.notifier).refresh(),
          ),
        Expanded(
          child: queueState.when(
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

              final view = buildQueueView(items, _query);

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(queueProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  itemCount: view.items.isEmpty ? 2 : view.items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildSummary(context, items, view);
                    }
                    if (view.items.isEmpty) {
                      return SizedBox(
                        height: MediaQuery.sizeOf(context).height - 300,
                        child: EmptyState(
                          icon: Icons.filter_alt_off_outlined,
                          title: 'No matching tasks',
                          subtitle: 'Adjust or reset the queue filters.',
                          action: TextButton(
                            onPressed: () => setState(() {
                              _query = QueueQuery(
                                sortField: _query.sortField,
                                ascending: _query.ascending,
                              );
                            }),
                            child: const Text('Clear filters'),
                          ),
                        ),
                      );
                    }
                    return QueueListItem(item: view.items[index - 1]);
                  },
                ),
              );
            },
            error: (error, stack) => ErrorDisplay(
              message: error.toString(),
              onRetry: () => ref.refresh(queueProvider),
            ),
            loading: () => const LoadingIndicator(message: 'Loading queue...'),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(
    BuildContext context,
    List<QueueItem> source,
    QueueViewResult view,
  ) {
    final theme = Theme.of(context);
    final taskLabel = view.items.length == 1 ? 'task' : 'tasks';
    final problemLabel = view.problemCount == 1 ? 'problem' : 'problems';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
      child: Row(
        children: [
          Text(
            '${view.items.length} $taskLabel',
            style: theme.textTheme.titleSmall,
          ),
          if (view.problemCount > 0) ...[
            const SizedBox(width: 6),
            Text(
              '(${view.problemCount} $problemLabel)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            tooltip: 'Queue options',
            onPressed: () => _showOptions(context, source),
            icon: Badge(
              isLabelVisible: _query.hasFilters,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, List<QueueItem> items) {
    final instances = ref.read(instancesProvider).instances;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return QueueOptionsSheet(
          items: items,
          instances: instances,
          query: _query,
          onApply: (query) {
            if (!mounted) return;
            setState(() => _query = query);
          },
        );
      },
    );
  }
}
