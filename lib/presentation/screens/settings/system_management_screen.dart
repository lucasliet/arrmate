import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../providers/cache_maintenance_provider.dart';
import '../../providers/settings_provider.dart';

/// Displays system diagnostics, server status, and app maintenance controls.
class SystemManagementScreen extends ConsumerWidget {
  const SystemManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.systemManagementTitle)),
      body: ListView(
        children: [
          _SectionHeader(title: l10n.systemServer),
          ListTile(
            leading: const Icon(Icons.library_books_outlined),
            title: Text(l10n.systemLogs),
            subtitle: Text(l10n.systemLogsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/logs'),
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: Text(l10n.systemHealth),
            subtitle: Text(l10n.systemHealthSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/health'),
          ),
          ListTile(
            leading: const Icon(Icons.network_check),
            title: Text(l10n.diagnosticsTitle),
            subtitle: Text(l10n.systemDiagnosticsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/diagnostics'),
          ),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: Text(l10n.systemOverviewTitle),
            subtitle: Text(l10n.systemOverviewSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/system-overview'),
          ),
          ListTile(
            leading: const Icon(Icons.high_quality_outlined),
            title: Text(l10n.qualityProfilesTitle),
            subtitle: Text(l10n.systemQualityProfilesSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/quality-profiles'),
          ),
          const Divider(),
          _SectionHeader(title: l10n.systemTorrentProtection),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(l10n.systemMinimumSeedingDays),
            subtitle: Text(
              settings.minimumSeedingDays == 0
                  ? l10n.systemSeedingWarningDisabled
                  : l10n.systemSeedingWarningEnabled(
                      settings.minimumSeedingDays,
                    ),
            ),
            trailing: Text(
              l10n.systemSeedingDaysShort(settings.minimumSeedingDays),
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
          _SectionHeader(title: l10n.systemAppMaintenance),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: Text(l10n.versionHistoryTitle),
            subtitle: Text(l10n.systemVersionHistorySubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/version-history'),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: Text(l10n.systemClearImageCache),
            subtitle: Text(l10n.systemClearImageCacheSubtitle),
            onTap: () => _clearImageCache(context, ref),
          ),
          ListTile(
            leading: Icon(
              Icons.restart_alt,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.systemResetSettings,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: Text(l10n.systemResetSettingsSubtitle),
            onTap: () => _confirmResetSettings(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _clearImageCache(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.systemImageCacheCleared;
    final cacheService = ref.read(cacheMaintenanceProvider);
    await cacheService.clearImageCache();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmResetSettings(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.systemResetConfirmTitle),
        content: Text(dialogContext.l10n.systemResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.commonReset),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(settingsProvider.notifier).resetSettings();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.systemSettingsReset)));
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
          title: Text(context.l10n.systemMinimumSeedingDays),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.l10n.systemDaysLabel,
                    hintText: '0',
                    border: const OutlineInputBorder(),
                    helperText: context.l10n.systemDaysHelper,
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 0) {
                      return context.l10n.systemDaysInvalid;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.systemMinimumSeedingDaysDescription,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.commonCancel),
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
              child: Text(context.l10n.commonSave),
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
