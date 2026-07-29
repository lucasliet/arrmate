import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/update_service.dart';
import '../../widgets/common_widgets.dart';

/// Provider exposing the full release history from GitHub Releases.
final appReleaseHistoryProvider =
    FutureProvider.autoDispose<List<AppReleaseInfo>>((ref) async {
      final service = ref.watch(updateServiceProvider);
      return service.fetchReleases();
    });

/// Displays the full version history fetched from GitHub Releases.
class VersionHistoryScreen extends ConsumerWidget {
  const VersionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releasesAsync = ref.watch(appReleaseHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Version History')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(appReleaseHistoryProvider.future),
        child: releasesAsync.when(
          data: (releases) {
            if (releases.isEmpty) {
              return const EmptyState(
                icon: Icons.history,
                title: 'No releases available',
                subtitle: 'Release history could not be loaded.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: releases.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final release = releases[index];
                return _ReleaseCard(release: release);
              },
            );
          },
          loading: () =>
              const LoadingIndicator(message: 'Loading version history...'),
          error: (error, _) => ErrorDisplay(
            message: 'Failed to load version history: $error',
            onRetry: () => ref.invalidate(appReleaseHistoryProvider),
          ),
        ),
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  final AppReleaseInfo release;

  const _ReleaseCard({required this.release});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: release.isCurrentVersion
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'v${release.version}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: release.isCurrentVersion
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (release.isCurrentVersion)
                  Text(
                    'Installed',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const Spacer(),
                Text(
                  dateFormat.format(release.publishedAt.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (release.changelog.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(release.changelog, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
