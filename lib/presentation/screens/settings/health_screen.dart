import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            onPressed: () {
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
              data: (checks) {
                if (checks.isEmpty) {
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
                        Text('No issues found', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: checks.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final check = checks[index];
                    final isError = check.type.toLowerCase() == 'error';

                    return ListTile(
                      leading: Icon(
                        isError
                            ? Icons.error_outline
                            : Icons.warning_amber_rounded,
                        color: isError ? Colors.red : Colors.orange,
                      ),
                      title: Text(check.source),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(check.message),
                          if (check.wikiUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
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
                  },
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
