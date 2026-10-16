import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/l10n/app_locale.dart';
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
        title: Text(context.l10n.systemOverviewTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.commonRefresh,
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: overviews.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.dns_outlined,
              title: context.l10n.settingsNoArrInstancesConfigured,
              subtitle: context.l10n.systemOverviewEmptySubtitle,
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
            LoadingIndicator(message: context.l10n.systemOverviewLoading),
        error: (_, _) => ErrorDisplay(
          message: context.l10n.systemOverviewLoadFailed,
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
            Text(
              context.l10n.systemOverviewDiskSpace,
              style: theme.textTheme.titleSmall,
            ),
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
    final l10n = context.l10n;
    final librarySize = _MetricData(
      icon: Icons.folder_outlined,
      text: l10n.systemOverviewLibrarySize(formatBytes(statistics.sizeOnDisk)),
    );
    final metrics = instanceType == InstanceType.radarr
        ? [
            _MetricData(
              icon: Icons.movie_outlined,
              text: l10n.systemOverviewMovieCount(statistics.movieCount),
            ),
            librarySize,
          ]
        : [
            _MetricData(
              icon: Icons.tv_outlined,
              text: l10n.systemOverviewSeriesCount(statistics.seriesCount),
            ),
            _MetricData(
              icon: Icons.video_library_outlined,
              text: l10n.systemOverviewEpisodeCount(statistics.episodeCount),
            ),
            librarySize,
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

  /// Translated metric text, value and label combined (e.g. "2 Movies").
  final String text;

  const _MetricData({required this.icon, required this.text});
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
          Text(data.text, style: theme.textTheme.labelLarge),
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
        context.l10n.systemOverviewNoStorage,
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
    final l10n = context.l10n;
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
                l10n.systemOverviewUsed(
                  formatBytes(diskSpace.usedSpace),
                  usedPercent,
                ),
                style: theme.textTheme.bodySmall,
              ),
            ),
            Text(
              l10n.systemOverviewFreeOf(
                formatBytes(diskSpace.freeSpace),
                formatBytes(diskSpace.totalSpace),
              ),
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
              failures
                  .map((failure) => _failureMessage(failure, context.l10n))
                  .join('\n'),
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Translates the default English message of [failure] for its section.
///
/// The provider reports a fixed English message per section, unless the
/// server rejected the credentials; server-provided messages are returned
/// untouched.
String _failureMessage(InstanceOverviewFailure failure, AppLocalizations l10n) {
  return switch ((failure.section, failure.message)) {
    (InstanceOverviewSection.status, 'Version information is unavailable.') =>
      l10n.systemOverviewVersionUnavailable,
    (
      InstanceOverviewSection.diskSpace,
      'Disk space information is unavailable.',
    ) =>
      l10n.systemOverviewDiskSpaceUnavailable,
    (InstanceOverviewSection.library, 'Library statistics are unavailable.') =>
      l10n.systemOverviewLibraryUnavailable,
    _ => failure.message,
  };
}
