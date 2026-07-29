import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/models.dart';
import '../../providers/advanced_providers.dart';

/// Displays system health checks and warnings from connected instances.
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.health_and_safety),
            tooltip: 'Run health check',
            onPressed: healthAsync.isLoading
                ? null
                : () {
                    ref.read(healthProvider.notifier).runHealthChecks();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          if (healthAsync.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: healthAsync.when(
              skipLoadingOnRefresh: true,
              data: (overview) {
                if (overview.configuredSourceCount == 0) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dns_outlined, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'No Arr instances configured',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add a Radarr or Sonarr instance to view server health.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (overview.serverChecks.isEmpty &&
                    overview.connectionFailures.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No server issues found',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Connected servers reported no health warnings.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  children: [
                    if (overview.connectionFailures.isNotEmpty) ...[
                      const _SectionHeader(title: 'Connection issues'),
                      for (final failure in overview.connectionFailures)
                        _ConnectionFailureTile(failure: failure),
                    ],
                    if (overview.serverChecks.isNotEmpty) ...[
                      const _SectionHeader(title: 'Server warnings'),
                      for (final check in overview.serverChecks)
                        _ServerHealthCheckTile(check: check),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text('Failed to load health status'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(healthProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _ConnectionFailureTile extends StatelessWidget {
  const _ConnectionFailureTile({required this.failure});

  final HealthConnectionFailure failure;

  @override
  Widget build(BuildContext context) {
    final isLoadFailure =
        failure.operation == HealthConnectionOperation.loadStatus;
    return ListTile(
      leading: Icon(
        isLoadFailure ? Icons.wifi_off_rounded : Icons.sync_problem_rounded,
        color: isLoadFailure ? Colors.red : Colors.orange,
      ),
      title: Text(
        isLoadFailure
            ? '${failure.service} connection failed'
            : '${failure.service} check could not start',
      ),
      subtitle: Text(
        isLoadFailure
            ? 'Could not load server health. Check the connection and try again.'
            : 'The latest available server status is shown below.',
      ),
    );
  }
}

class _ServerHealthCheckTile extends StatelessWidget {
  const _ServerHealthCheckTile({required this.check});

  final HealthCheck check;

  @override
  Widget build(BuildContext context) {
    final isError = check.type.toLowerCase() == 'error';
    return ListTile(
      leading: Icon(
        isError ? Icons.error_outline : Icons.warning_amber_rounded,
        color: isError ? Colors.red : Colors.orange,
      ),
      title: Text(check.source),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(check.message),
          if (check.wikiUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Wiki: ${check.wikiUrl}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      isThreeLine: check.wikiUrl.isNotEmpty,
    );
  }
}
