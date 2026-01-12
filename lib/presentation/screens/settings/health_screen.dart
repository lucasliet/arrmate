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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(healthProvider.notifier).runHealthChecks();
            },
          ),
        ],
      ),
      body: healthAsync.when(
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
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final check = checks[index];
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
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
