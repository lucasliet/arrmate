import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/request_diagnostics.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/system_diagnostics_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/models.dart';
import '../../providers/cache_maintenance_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/instances_provider.dart';
import '../../widgets/common_widgets.dart';

/// Provider exposing the latest system diagnostics snapshot.
final systemDiagnosticsProvider =
    AsyncNotifierProvider.autoDispose<
      SystemDiagnosticsController,
      SystemDiagnosticsSnapshot?
    >(SystemDiagnosticsController.new);

class SystemDiagnosticsController
    extends AutoDisposeAsyncNotifier<SystemDiagnosticsSnapshot?> {
  @override
  Future<SystemDiagnosticsSnapshot?> build() async => null;

  /// Runs the diagnostics against every configured instance.
  Future<void> run() async {
    final previous = state;
    state = const AsyncValue<SystemDiagnosticsSnapshot?>.loading()
        .copyWithPrevious(previous);
    state = await AsyncValue.guard(() async {
      final repository = ref.read(instanceRepositoryProvider);
      final service = SystemDiagnosticsService(
        loadStatus: repository.getSystemStatus,
      );
      final instances = [
        ...ref.read(instancesByTypeProvider(InstanceType.radarr)),
        ...ref.read(instancesByTypeProvider(InstanceType.sonarr)),
      ];
      return service.run(instances);
    });
  }
}

/// Displays network and request diagnostics, with the ability to export a
/// sanitized bug report.
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(systemDiagnosticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(systemDiagnosticsProvider.notifier).run(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Export report',
            onPressed: () => _exportReport(context, ref),
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: snapshotAsync.when(
        data: (snapshot) => _DiagnosticsBody(snapshot: snapshot),
        loading: () =>
            const LoadingIndicator(message: 'Running diagnostics...'),
        error: (error, _) => ErrorDisplay(
          message: 'Failed to run diagnostics: $error',
          onRetry: () => ref.read(systemDiagnosticsProvider.notifier).run(),
        ),
      ),
    );
  }

  Future<void> _exportReport(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
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
      final packageInfo = await PackageInfo.fromPlatform();

      final builder = DiagnosticReportBuilder();
      final report = builder.build(
        snapshot: snapshot,
        requests: requests,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        platform: platform,
        imageCacheClearedAt: cacheService.lastClearedAt,
      );

      await SharePlus.instance.share(
        ShareParams(text: report, subject: 'Arrmate Diagnostic Report'),
      );
    } catch (error, stackTrace) {
      logger.error('[Diagnostics] Export failed', error, stackTrace);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to export report: $error')),
      );
    }
  }
}

class _DiagnosticsBody extends ConsumerWidget {
  final SystemDiagnosticsSnapshot? snapshot;

  const _DiagnosticsBody({required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (snapshot == null) {
      return EmptyState(
        icon: Icons.network_check,
        title: 'No diagnostics yet',
        subtitle: 'Run a diagnostic check to inspect instance connectivity.',
        action: FilledButton.icon(
          onPressed: () => ref.read(systemDiagnosticsProvider.notifier).run(),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Run diagnostics'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(paddingMd),
      children: [
        _NetworkSummary(snapshot: snapshot!),
        const SizedBox(height: paddingMd),
        Text('Instance checks', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: paddingSm),
        if (snapshot!.checks.isEmpty)
          const Text('No instances configured.')
        else
          ...snapshot!.checks.map(
            (check) => Padding(
              padding: const EdgeInsets.only(bottom: paddingSm),
              child: _CheckTile(check: check),
            ),
          ),
        const SizedBox(height: paddingMd),
        Text('Recent requests', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: paddingSm),
        const _RequestDiagnosticsList(),
      ],
    );
  }
}

class _NetworkSummary extends StatelessWidget {
  final SystemDiagnosticsSnapshot snapshot;

  const _NetworkSummary({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  snapshot.isOffline ? Icons.cloud_off : Icons.cloud_done,
                  color: snapshot.isOffline
                      ? theme.colorScheme.error
                      : Colors.green,
                ),
                const SizedBox(width: paddingSm),
                Text(
                  snapshot.isOffline ? 'Offline' : 'Online',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: paddingSm),
            Text(
              'Generated ${formatDate(snapshot.generatedAt.toLocal())}',
              style: theme.textTheme.bodySmall,
            ),
            if (snapshot.networkInterfaces.isNotEmpty)
              Text(
                'Interfaces: ${snapshot.networkInterfaces.join(', ')}',
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
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        check.isSuccessful ? Icons.check_circle : Icons.error,
        color: check.isSuccessful ? Colors.green : theme.colorScheme.error,
      ),
      title: Text('${check.instanceLabel} · ${check.endpointLabel}'),
      subtitle: Text(
        check.isSuccessful
            ? 'OK · ${check.duration.inMilliseconds}ms'
                  '${check.version != null ? ' · v${check.version}' : ''}'
            : 'Failed · ${check.error ?? 'unknown error'}',
      ),
    );
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
      return const Text('No recent requests recorded.');
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
        '${entry.source} · ${entry.statusCode ?? entry.errorType ?? 'unknown'} '
        '· ${entry.duration.inMilliseconds}ms',
      ),
    );
  }
}
