import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cache_maintenance_provider.dart';
import '../../providers/settings_provider.dart';

/// Displays system diagnostics, server status, and app maintenance controls.
class SystemManagementScreen extends ConsumerWidget {
  const SystemManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('System Management')),
      body: ListView(
        children: [
          _SectionHeader(title: 'Server'),
          ListTile(
            leading: const Icon(Icons.library_books_outlined),
            title: const Text('Logs'),
            subtitle: const Text('System event logs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/logs'),
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Health'),
            subtitle: const Text('Server-reported Radarr and Sonarr alerts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/health'),
          ),
          ListTile(
            leading: const Icon(Icons.network_check),
            title: const Text('Connection Diagnostics'),
            subtitle: const Text(
              'Test endpoints, latency, request traces, and export a report',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/diagnostics'),
          ),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('System Overview'),
            subtitle: const Text('Storage, versions, and library sizes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/system-overview'),
          ),
          ListTile(
            leading: const Icon(Icons.high_quality_outlined),
            title: const Text('Quality Profiles'),
            subtitle: const Text('Available profiles from instances'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/quality-profiles'),
          ),
          const Divider(),
          _SectionHeader(title: 'Torrent Protection'),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Minimum seeding days'),
            subtitle: Text(
              settings.minimumSeedingDays == 0
                  ? 'Seeding warning disabled'
                  : 'Warn before deleting torrents that seeded for less than '
                        '${settings.minimumSeedingDays} '
                        'day${settings.minimumSeedingDays == 1 ? '' : 's'}.',
            ),
            trailing: Text(
              '${settings.minimumSeedingDays}d',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _showMinimumSeedingDaysDialog(
              context,
              ref,
              settings.minimumSeedingDays,
            ),
          ),
          const Divider(),
          _SectionHeader(title: 'App Maintenance'),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('Version History'),
            subtitle: const Text('Changelog for every published release'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/version-history'),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Clear image cache'),
            subtitle: const Text('Free up cached poster and image storage'),
            onTap: () => _clearImageCache(context, ref),
          ),
          ListTile(
            leading: Icon(
              Icons.restart_alt,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Reset app settings',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text(
              'Restore appearance, view, and notification defaults',
            ),
            onTap: () => _confirmResetSettings(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _clearImageCache(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final cacheService = ref.read(cacheMaintenanceProvider);
    await cacheService.clearImageCache();
    messenger.showSnackBar(
      const SnackBar(content: Text('Image cache cleared')),
    );
  }

  Future<void> _confirmResetSettings(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset app settings?'),
        content: const Text(
          'This restores appearance, view mode, and notification preferences '
          'to their defaults. Configured instances are preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(settingsProvider.notifier).resetSettings();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App settings reset to defaults')),
    );
  }

  void _showMinimumSeedingDaysDialog(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) {
    final controller = TextEditingController(text: current.toString());
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Minimum seeding days'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Days',
                    hintText: '0',
                    border: OutlineInputBorder(),
                    helperText: '0 disables the warning',
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 0) {
                      return 'Enter a valid number (0 or more)';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Torrents that seeded for less than this are flagged for '
                'confirmation before deletion. Set to 0 to disable.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  ref
                      .read(settingsProvider.notifier)
                      .setMinimumSeedingDays(int.parse(controller.text));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
