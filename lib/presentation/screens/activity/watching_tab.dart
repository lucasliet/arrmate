import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/common_widgets.dart';
import 'providers/watching_provider.dart';
import 'widgets/watching_list_item.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../l10n/labels.dart';

/// Activity tab listing Jellyfin items matched to the library: in-progress
/// media under "Continue Watching" followed by the next episode of each
/// followed series under "Next Up".
class WatchingTab extends ConsumerWidget {
  /// Creates a [WatchingTab].
  const WatchingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchingState = ref.watch(watchingItemsProvider);

    return watchingState.when(
      data: (feed) {
        if (feed.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(watchingItemsProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height - 200,
                child: const EmptyState(
                  icon: Icons.play_circle_outline,
                  title: 'Nothing in progress',
                  subtitle:
                      'Media you pause in Jellyfin and the next episodes of '
                      'series you follow will appear here.',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(watchingItemsProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              if (feed.continueWatching.isNotEmpty) ...[
                const _SectionHeader(title: 'Continue Watching'),
                for (final item in feed.continueWatching)
                  WatchingListItem(item: item),
              ],
              if (feed.nextUp.isNotEmpty) ...[
                const _SectionHeader(title: 'Next Up'),
                for (final item in feed.nextUp) WatchingListItem(item: item),
              ],
            ],
          ),
        );
      },
      error: (error, stack) => ErrorDisplay(
        message: describeError(error, context.l10n),
        onRetry: () => ref.read(watchingItemsProvider.notifier).refresh(),
      ),
      loading: () =>
          const LoadingIndicator(message: 'Loading continue watching...'),
    );
  }
}

/// Section title shown above each group of [WatchingListItem]s.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
