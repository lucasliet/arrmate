import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/models.dart';
import '../../providers/instance_storage_provider.dart';
import '../../providers/instances_provider.dart';
import '../../widgets/common_widgets.dart';

/// Displays storage, library, and version information for every Arr instance.
class SystemOverviewScreen extends ConsumerWidget {
  const SystemOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviews = ref.watch(instanceStorageOverviewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Overview'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: overviews.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.dns_outlined,
              title: 'No Arr instances configured',
              subtitle: 'Add a Radarr or Sonarr instance to view system data.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView.separated(
              padding: const EdgeInsets.all(paddingMd),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: paddingMd),
              itemBuilder: (context, index) {
                return _InstanceOverviewCard(overview: items[index]);
              },
            ),
          );
        },
        loading: () =>
            const LoadingIndicator(message: 'Loading system overview...'),
        error: (_, _) => ErrorDisplay(
          message: 'Failed to load the system overview.',
          onRetry: () => _refresh(ref),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    final instances = [
      ...ref.read(instancesByTypeProvider(InstanceType.radarr)),
      ...ref.read(instancesByTypeProvider(InstanceType.sonarr)),
    ];
    for (final instance in instances) {
      ref.invalidate(instanceStorageOverviewProvider(instance));
    }
    final refreshedOverview = ref.refresh(
      instanceStorageOverviewsProvider.future,
    );
    await refreshedOverview;
  }
}

class _InstanceOverviewCard extends StatelessWidget {
  final InstanceStorageOverview overview;

  const _InstanceOverviewCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            if (overview.library != null) ...[
              const SizedBox(height: paddingMd),
              _LibrarySummary(
                instanceType: overview.instance.type,
                statistics: overview.library!,
              ),
            ],
            const SizedBox(height: paddingMd),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: paddingSm),
            Text('Disk Space', style: theme.textTheme.titleSmall),
            const SizedBox(height: paddingSm),
            _DiskSpaceSection(diskSpaces: overview.diskSpaces),
            if (overview.hasFailures) ...[
              const SizedBox(height: paddingMd),
              _FailureContainer(failures: overview.failures),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final instance = overview.instance;
    final version = formatInstanceVersion(overview.version);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          child: Icon(
            instance.type == InstanceType.radarr
                ? Icons.movie_outlined
                : Icons.tv_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(instance.label, style: theme.textTheme.titleMedium),
              Text(
                instance.type.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (version.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: paddingSm,
              vertical: paddingXs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(radiusSm),
            ),
            child: Text(
              version,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}

class _LibrarySummary extends StatelessWidget {
  final InstanceType instanceType;
  final InstanceLibraryStatistics statistics;

  const _LibrarySummary({required this.instanceType, required this.statistics});

  @override
  Widget build(BuildContext context) {
    final metrics = instanceType == InstanceType.radarr
        ? [
            _MetricData(
              icon: Icons.movie_outlined,
              value: '${statistics.movieCount}',
              label: statistics.movieCount == 1 ? 'Movie' : 'Movies',
            ),
            _MetricData(
              icon: Icons.folder_outlined,
              value: formatBytes(statistics.sizeOnDisk),
              label: 'Library',
            ),
          ]
        : [
            _MetricData(
              icon: Icons.tv_outlined,
              value: '${statistics.seriesCount}',
              label: 'Series',
            ),
            _MetricData(
              icon: Icons.video_library_outlined,
              value: '${statistics.episodeCount}',
              label: statistics.episodeCount == 1 ? 'Episode' : 'Episodes',
            ),
            _MetricData(
              icon: Icons.folder_outlined,
              value: formatBytes(statistics.sizeOnDisk),
              label: 'Library',
            ),
          ];

    return Wrap(
      spacing: paddingSm,
      runSpacing: paddingSm,
      children: metrics.map((metric) {
        return _Metric(data: metric);
      }).toList(),
    );
  }
}

class _MetricData {
  final IconData icon;
  final String value;
  final String label;

  const _MetricData({
    required this.icon,
    required this.value,
    required this.label,
  });
}

class _Metric extends StatelessWidget {
  final _MetricData data;

  const _Metric({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: paddingSm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data.icon,
            size: iconSizeSm,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: paddingSm),
          Text(
            '${data.value} ${data.label}',
            style: theme.textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _DiskSpaceSection extends StatelessWidget {
  final List<InstanceDiskSpace>? diskSpaces;

  const _DiskSpaceSection({required this.diskSpaces});

  @override
  Widget build(BuildContext context) {
    if (diskSpaces == null) {
      return const SizedBox.shrink();
    }
    if (diskSpaces!.isEmpty) {
      return Text(
        'No storage locations reported.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: diskSpaces!
          .map(
            (diskSpace) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DiskSpaceRow(diskSpace: diskSpace),
            ),
          )
          .toList(),
    );
  }
}

class _DiskSpaceRow extends StatelessWidget {
  final InstanceDiskSpace diskSpace;

  const _DiskSpaceRow({required this.diskSpace});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usedPercent = (diskSpace.usedFraction * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          diskSpace.displayLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (diskSpace.path.isNotEmpty &&
            diskSpace.displayLabel != diskSpace.path)
          Text(
            diskSpace.path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: paddingSm),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: diskSpace.usedFraction,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: paddingXs),
        Row(
          children: [
            Expanded(
              child: Text(
                'Used ${formatBytes(diskSpace.usedSpace)} ($usedPercent%)',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Text(
              '${formatBytes(diskSpace.freeSpace)} free of '
              '${formatBytes(diskSpace.totalSpace)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FailureContainer extends StatelessWidget {
  final List<InstanceOverviewFailure> failures;

  const _FailureContainer({required this.failures});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              failures.map((failure) => failure.message).join('\n'),
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
