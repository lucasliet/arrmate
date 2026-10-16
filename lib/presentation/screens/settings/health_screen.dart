import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/context_extensions.dart';
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
        title: Text(context.l10n.healthTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.health_and_safety),
            tooltip: context.l10n.healthRunCheck,
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.dns_outlined, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.settingsNoArrInstancesConfigured,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.healthNoInstancesSubtitle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (overview.serverChecks.isEmpty &&
                    overview.connectionFailures.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.healthNoIssuesTitle,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.healthNoIssuesSubtitle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  children: [
                    if (overview.connectionFailures.isNotEmpty) ...[
                      _SectionHeader(
                        title: context.l10n.healthConnectionIssues,
                      ),
                      for (final failure in overview.connectionFailures)
                        _ConnectionFailureTile(failure: failure),
                    ],
                    if (overview.serverChecks.isNotEmpty) ...[
                      _SectionHeader(title: context.l10n.healthServerWarnings),
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
                    Text(context.l10n.healthLoadFailed),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(healthProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(context.l10n.commonRetry),
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
            ? context.l10n.healthConnectionFailed(failure.service)
            : context.l10n.healthCheckCouldNotStart(failure.service),
      ),
      subtitle: Text(
        isLoadFailure
            ? context.l10n.healthLoadFailureSubtitle
            : context.l10n.healthRunFailureSubtitle,
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
                context.l10n.healthWiki(check.wikiUrl),
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
