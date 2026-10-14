import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/common_widgets.dart';
import 'providers/watching_provider.dart';
import 'widgets/watching_list_item.dart';

/// Activity tab listing in-progress Jellyfin items matched to the library.
class WatchingTab extends ConsumerWidget {
  /// Creates a [WatchingTab].
  const WatchingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchingState = ref.watch(watchingItemsProvider);

    return watchingState.when(
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(watchingItemsProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height - 200,
                child: const EmptyState(
                  icon: Icons.play_circle_outline,
                  title: 'Nothing in progress',
                  subtitle: 'Media you pause in Jellyfin will appear here.',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(watchingItemsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return WatchingListItem(item: items[index]);
            },
          ),
        );
      },
      error: (error, stack) => ErrorDisplay(
        message: error.toString(),
        onRetry: () => ref.read(watchingItemsProvider.notifier).refresh(),
      ),
      loading: () =>
          const LoadingIndicator(message: 'Loading continue watching...'),
    );
  }
}
