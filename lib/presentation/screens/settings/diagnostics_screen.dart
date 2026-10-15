import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/network/request_diagnostics.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/system_diagnostics_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/models.dart';
import '../../l10n/labels.dart';
import '../../providers/cache_maintenance_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/instances_provider.dart';
import '../../widgets/common_widgets.dart';

/// Runs connectivity diagnostics for the provided configured instances.
typedef SystemDiagnosticsRunner =
    Future<SystemDiagnosticsSnapshot> Function(List<Instance> instances);

/// Exports a fully built, sanitized diagnostic report.
typedef DiagnosticReportExporter = Future<void> Function(String report);

/// Loads the package metadata included in an exported diagnostic report.
typedef DiagnosticsPackageInfoLoader = Future<PackageInfo> Function();

/// Exposes the instance loading state used by connection diagnostics.
final diagnosticsInstancesStateProvider = Provider<InstancesState>((ref) {
  return ref.watch(instancesProvider);
});

/// Creates the runner used for authenticated endpoint checks.
final systemDiagnosticsRunnerProvider = Provider<SystemDiagnosticsRunner>((
  ref,
) {
  final repository = ref.watch(instanceRepositoryProvider);
  final service = SystemDiagnosticsService(
    loadStatus: repository.getSystemStatus,
  );
  return service.run;
});

/// Loads package metadata for report generation.
final diagnosticsPackageInfoLoaderProvider =
    Provider<DiagnosticsPackageInfoLoader>((ref) {
      return PackageInfo.fromPlatform;
    });

/// Shares a generated diagnostic report through the platform share sheet.
final diagnosticReportExporterProvider = Provider<DiagnosticReportExporter>((
  ref,
) {
  return (report) async {
    await SharePlus.instance.share(
      ShareParams(text: report, subject: 'Arrmate Diagnostic Report'),
    );
  };
});

/// Provider exposing the latest system diagnostics snapshot.
final systemDiagnosticsProvider =
    AsyncNotifierProvider.autoDispose<
      SystemDiagnosticsController,
      SystemDiagnosticsSnapshot
    >(SystemDiagnosticsController.new);

class SystemDiagnosticsController
    extends AutoDisposeAsyncNotifier<SystemDiagnosticsSnapshot> {
  int _generation = 0;
  Completer<List<Instance>>? _instancesCompleter;
  bool _isWatchingInstances = false;

  @override
  Future<SystemDiagnosticsSnapshot> build() async {
    _generation++;
    _watchInstances();
    final instancesState = ref.read(diagnosticsInstancesStateProvider);
    final instances = instancesState.isLoading
        ? await _waitForInstances()
        : instancesState.instances;
    return ref.read(systemDiagnosticsRunnerProvider).call(instances);
  }

  void _watchInstances() {
    if (_isWatchingInstances) return;
    _isWatchingInstances = true;
    ref.onDispose(() {
      _generation++;
      _isWatchingInstances = false;
      final completer = _instancesCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.completeError(
          StateError('Connection diagnostics was disposed before loading.'),
        );
      }
      _instancesCompleter = null;
    });
    ref.listen<InstancesState>(diagnosticsInstancesStateProvider, (
      previous,
      next,
    ) {
      if (next.isLoading) return;
      final completer = _instancesCompleter;
      if (completer != null && !completer.isCompleted) {
        _instancesCompleter = null;
        completer.complete(next.instances);
        return;
      }
      if (previous != null && previous.instances != next.instances) {
        ref.invalidateSelf();
      }
    });
  }

  Future<List<Instance>> _waitForInstances() {
    final existing = _instancesCompleter;
    if (existing != null) return existing.future;
    final completer = Completer<List<Instance>>();
    _instancesCompleter = completer;
    return completer.future;
  }

  /// Runs the diagnostics against every configured instance.
  Future<void> run() async {
    final generation = ++_generation;
    final previous = state;
    state = const AsyncValue<SystemDiagnosticsSnapshot>.loading()
        .copyWithPrevious(previous);
    final next = await AsyncValue.guard(() async {
      final instancesState = ref.read(diagnosticsInstancesStateProvider);
      if (instancesState.isLoading) {
        throw StateError('Configured instances are still loading.');
      }
      return ref
          .read(systemDiagnosticsRunnerProvider)
          .call(instancesState.instances);
    });
    if (generation == _generation) {
      state = next;
    }
  }
}

/// Displays network and request diagnostics, with the ability to export a
/// sanitized bug report.
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(systemDiagnosticsProvider);
    final isRefreshing = snapshotAsync.isLoading && snapshotAsync.hasValue;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.diagnosticsTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.diagnosticsRunAgain,
            onPressed: snapshotAsync.isLoading
                ? null
                : () => ref.read(systemDiagnosticsProvider.notifier).run(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: context.l10n.diagnosticsExportReport,
            onPressed: snapshotAsync.hasValue
                ? () => _exportReport(context, ref)
                : null,
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isRefreshing)
            _DiagnosticsProgress(message: context.l10n.diagnosticsRefreshing),
          Expanded(
            child: snapshotAsync.when(
              skipLoadingOnRefresh: true,
              data: (snapshot) => _DiagnosticsBody(snapshot: snapshot),
              loading: () =>
                  LoadingIndicator(message: context.l10n.diagnosticsChecking),
              error: (error, _) => ErrorDisplay(
                message: context.l10n.diagnosticsRunFailed(
                  describeError(error, context.l10n),
                ),
                onRetry: () =>
                    ref.read(systemDiagnosticsProvider.notifier).run(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final platform = Theme.of(context).platform.name;
    final snapshot =
        ref.read(systemDiagnosticsProvider).valueOrNull ??
        SystemDiagnosticsSnapshot(
          generatedAt: DateTime.now(),
          networkInterfaces: const [],
          checks: const [],
        );
    final requests = RequestDiagnosticsRecorder.instance.entries;
    final cacheService = ref.read(cacheMaintenanceProvider);
    try {
      final packageInfo = await ref.read(
        diagnosticsPackageInfoLoaderProvider,
      )();
      if (!context.mounted) return;

      final builder = DiagnosticReportBuilder();
      final report = builder.build(
        snapshot: snapshot,
        requests: requests,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        platform: platform,
        imageCacheClearedAt: cacheService.lastClearedAt,
      );

      await ref.read(diagnosticReportExporterProvider)(report);
    } catch (error, stackTrace) {
      logger.error('[Diagnostics] Export failed', error, stackTrace);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.diagnosticsExportFailed(describeError(error, l10n)),
          ),
        ),
      );
    }
  }
}

class _DiagnosticsProgress extends StatelessWidget {
  final String message;

  const _DiagnosticsProgress({required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: paddingMd,
              vertical: paddingXs,
            ),
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsBody extends StatelessWidget {
  final SystemDiagnosticsSnapshot snapshot;

  const _DiagnosticsBody({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(paddingMd),
      children: [
        const _DiagnosticsPurpose(),
        const SizedBox(height: paddingMd),
        _NetworkSummary(snapshot: snapshot),
        const SizedBox(height: paddingMd),
        Text(
          context.l10n.diagnosticsEndpointConnectivity,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: paddingSm),
        if (snapshot.checks.isEmpty)
          Text(context.l10n.diagnosticsNoInstances)
        else
          ...snapshot.checks.map(
            (check) => Padding(
              padding: const EdgeInsets.only(bottom: paddingSm),
              child: _CheckTile(check: check),
            ),
          ),
        const SizedBox(height: paddingMd),
        Text(
          context.l10n.diagnosticsRecentRequests,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: paddingSm),
        const _RequestDiagnosticsList(),
      ],
    );
  }
}

class _DiagnosticsPurpose extends StatelessWidget {
  const _DiagnosticsPurpose();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.diagnosticsPurposeTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: paddingXs),
            Text(context.l10n.diagnosticsPurposeBody),
          ],
        ),
      ),
    );
  }
}

class _NetworkSummary extends StatelessWidget {
  final SystemDiagnosticsSnapshot snapshot;

  const _NetworkSummary({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final failedEndpointCount = snapshot.checks
        .where((check) => !check.isSuccessful)
        .length;
    final hasEndpointFailures = failedEndpointCount > 0;
    final endpointStatus = snapshot.areAllEndpointsUnavailable
        ? l10n.diagnosticsEndpointsUnavailable
        : hasEndpointFailures
        ? l10n.diagnosticsSomeEndpointsUnavailable
        : l10n.diagnosticsEndpointsAvailable;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  snapshot.hasNetworkInterface
                      ? Icons.wifi_rounded
                      : Icons.wifi_off_rounded,
                  color: snapshot.hasNetworkInterface
                      ? Colors.green
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: paddingSm),
                Text(
                  snapshot.hasNetworkInterface
                      ? l10n.diagnosticsNetworkAvailable
                      : l10n.diagnosticsNoNetworkInterface,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (snapshot.checks.isNotEmpty) ...[
              const SizedBox(height: paddingSm),
              Row(
                children: [
                  Icon(
                    hasEndpointFailures
                        ? Icons.dns_outlined
                        : Icons.dns_rounded,
                    color: hasEndpointFailures
                        ? theme.colorScheme.error
                        : Colors.green,
                  ),
                  const SizedBox(width: paddingSm),
                  Text(endpointStatus, style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
            const SizedBox(height: paddingSm),
            Text(
              l10n.diagnosticsGenerated(
                formatDate(snapshot.generatedAt.toLocal()),
              ),
              style: theme.textTheme.bodySmall,
            ),
            if (snapshot.networkInterfaces.isNotEmpty)
              Text(
                l10n.diagnosticsInterfaces(
                  snapshot.networkInterfaces.join(', '),
                ),
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  final InstanceDiagnosticCheck check;

  const _CheckTile({required this.check});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final durationMs = check.duration.inMilliseconds;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        check.isSuccessful ? Icons.check_circle : Icons.error,
        color: check.isSuccessful ? Colors.green : theme.colorScheme.error,
      ),
      title: Text('${check.instanceLabel} · ${_endpointLabel(check, l10n)}'),
      subtitle: Text(
        check.isSuccessful
            ? check.version != null
                  ? l10n.diagnosticsCheckOkWithVersion(
                      durationMs,
                      '${check.version}',
                    )
                  : l10n.diagnosticsCheckOk(durationMs)
            : l10n.diagnosticsCheckFailed(
                check.error ?? l10n.diagnosticsUnknownError,
              ),
      ),
    );
  }

  String _endpointLabel(InstanceDiagnosticCheck check, AppLocalizations l10n) {
    return switch (check.endpointLabel) {
      'Active' => l10n.diagnosticsEndpointActive,
      'Primary' => l10n.diagnosticsEndpointPrimary,
      'Alternative' => l10n.diagnosticsEndpointAlternative,
      'Primary · Active' => l10n.diagnosticsEndpointPrimaryActive,
      'Alternative · Active' => l10n.diagnosticsEndpointAlternativeActive,
      _ => check.endpointLabel,
    };
  }
}

class _RequestDiagnosticsList extends StatefulWidget {
  const _RequestDiagnosticsList();

  @override
  State<_RequestDiagnosticsList> createState() =>
      _RequestDiagnosticsListState();
}

class _RequestDiagnosticsListState extends State<_RequestDiagnosticsList> {
  late StreamSubscription<List<RequestDiagnosticEntry>> _subscription;
  List<RequestDiagnosticEntry> _entries =
      RequestDiagnosticsRecorder.instance.entries;

  @override
  void initState() {
    super.initState();
    _subscription = RequestDiagnosticsRecorder.instance.stream.listen((
      entries,
    ) {
      if (mounted) setState(() => _entries = entries);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) {
      return Text(context.l10n.diagnosticsNoRecentRequests);
    }
    return Column(
      children: _entries
          .take(20)
          .map((entry) => _RequestTile(entry: entry))
          .toList(),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final RequestDiagnosticEntry entry;

  const _RequestTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        entry.isSuccessful ? Icons.check : Icons.error_outline,
        size: 20,
        color: entry.isSuccessful ? Colors.green : theme.colorScheme.error,
      ),
      title: Text('${entry.method} ${entry.path}'),
      subtitle: Text(
        '${entry.source} · '
        '${entry.statusCode ?? entry.errorType ?? context.l10n.diagnosticsUnknownStatus} '
        '· ${entry.duration.inMilliseconds}ms',
      ),
    );
  }
}
