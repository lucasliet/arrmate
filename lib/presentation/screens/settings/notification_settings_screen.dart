import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/logger_service.dart';
import '../../../core/services/ntfy_service.dart';
import '../../../core/services/remote_notification_setup_service.dart';
import '../../../domain/models/settings/notification_settings.dart';
import '../../providers/instances_provider.dart';
import '../../providers/settings_provider.dart';

/// A screen that allows users to configure push notifications via ntfy.sh.
///
/// Users can generate a unique topic, toggle specific notification triggers
/// (Grab, Import, etc.), and auto-configure their Radarr/Sonarr instances
/// to send webhooks to this device.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifications = settings.notifications;
    final ntfyService = ref.watch(ntfyServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          if (notifications.ntfyTopic == null) ...[
            ListTile(
              leading: const Icon(Icons.notifications_none),
              title: const Text('Setup Push Notifications'),
              subtitle: const Text('Tap to generate your unique topic'),
              trailing: const Icon(Icons.add_circle_outline),
              onTap: () =>
                  ref.read(settingsProvider.notifier).generateNtfyTopic(),
            ),
          ] else ...[
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: Text(
                ntfyService.isConnected
                    ? 'Connected to ntfy.sh'
                    : 'Disconnected',
              ),
              secondary: Icon(
                ntfyService.isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: ntfyService.isConnected ? Colors.green : Colors.grey,
              ),
              value: notifications.enabled,
              onChanged: (value) async {
                final updated = notifications.copyWith(enabled: value);
                await ref
                    .read(settingsProvider.notifier)
                    .updateNotifications(updated);

                if (value && context.mounted) {
                  _handleAutoConfigure(
                    context,
                    ref,
                    silent: true,
                    settings: updated,
                  );
                }
              },
            ),
            ListTile(
              title: const Text('Your Topic'),
              subtitle: Text(notifications.ntfyTopic!),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy topic',
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: notifications.ntfyTopic!),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Topic copied to clipboard')),
                  );
                },
              ),
            ),
            _buildSetupInstructions(context, notifications, ref),
            if (notifications.enabled) ...[
              const Divider(),
              _buildSectionHeader(context, 'Downloads'),
              _buildNotificationToggle(
                context,
                ref,
                notifications,
                'Notify on Grab',
                'When a release is sent to download client',
                notifications.notifyOnGrab,
                (v) => notifications.copyWith(notifyOnGrab: v),
              ),
              _buildNotificationToggle(
                context,
                ref,
                notifications,
                'Notify on Import',
                'When a file is successfully imported',
                notifications.notifyOnImport,
                (v) => notifications.copyWith(notifyOnImport: v),
              ),
              _buildNotificationToggle(
                context,
                ref,
                notifications,
                'Notify on Failure',
                'When a download fails to import',
                notifications.notifyOnDownloadFailed,
                (v) => notifications.copyWith(notifyOnDownloadFailed: v),
              ),

              const Divider(),
              _buildSectionHeader(context, 'Media Updates'),
              _buildNotificationToggle(
                context,
                ref,
                notifications,
                'Movie/Series Added',
                'When a movie or series is added',
                notifications.notifyOnMediaAdded,
                (v) => notifications.copyWith(notifyOnMediaAdded: v),
              ),
              _buildNotificationToggle(
                context,
                ref,
                notifications,
                'Movie/Series Deleted',
                'When a movie or series is deleted',
                notifications.notifyOnMediaDeleted,
                (v) => notifications.copyWith(notifyOnMediaDeleted: v),
              ),
              _buildNotificationToggle(
                context,
                ref,
                notifications,
                'File Deleted',
                'When a media file is deleted',
                notifications.notifyOnFileDelete,
                (v) => notifications.copyWith(notifyOnFileDelete: v),
              ),

              const Divider(),
              _buildSectionHeader(context, 'System'),
              _buildNotificationToggle(
                context,
                ref,
                notifications,
                'Application Update',
                'When Arrmate is updated',
                notifications.notifyOnUpgrade,
                (v) => notifications.copyWith(notifyOnUpgrade: v),
              ),
              _buildNotificationToggle(
                context,
                ref,
                notifications,
                'Manual Interaction',
                'When manual intervention is required',
                notifications.notifyOnManualRequired,
                (v) => notifications.copyWith(notifyOnManualRequired: v),
              ),
              _buildNotificationToggle(
                context,
                ref,
                notifications,
                'Health Issues',
                'When system health issues are detected',
                notifications.notifyOnHealthIssue,
                (v) => notifications.copyWith(notifyOnHealthIssue: v),
              ),
              if (notifications.notifyOnHealthIssue) ...[
                _buildNotificationToggle(
                  context,
                  ref,
                  notifications,
                  'Include Warnings',
                  'Also notify on health warnings',
                  notifications.includeHealthWarnings,
                  (v) => notifications.copyWith(includeHealthWarnings: v),
                  indent: true,
                ),
                _buildNotificationToggle(
                  context,
                  ref,
                  notifications,
                  'Health Restored',
                  'When a health issue is resolved',
                  notifications.notifyOnHealthRestored,
                  (v) => notifications.copyWith(notifyOnHealthRestored: v),
                  indent: true,
                ),
              ],

              const Divider(),
              SwitchListTile(
                title: const Text('Battery Saver Mode'),
                subtitle: const Text(
                  'Disable background polling. Notifications only when app is open.',
                ),
                secondary: const Icon(Icons.battery_saver),
                value: notifications.batterySaverMode,
                onChanged: (value) {
                  final updated = notifications.copyWith(
                    batterySaverMode: value,
                  );
                  ref
                      .read(settingsProvider.notifier)
                      .updateNotifications(updated);
                },
              ),
              if (!notifications.batterySaverMode)
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Polling Interval'),
                  subtitle: const Text('How often to check for notifications'),
                  trailing: DropdownButton<int>(
                    value: notifications.pollingIntervalMinutes,
                    underline: const SizedBox.shrink(),
                    items: NotificationSettings.pollingIntervalOptions
                        .map(
                          (interval) => DropdownMenuItem(
                            value: interval,
                            child: Text('$interval min'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final updated = notifications.copyWith(
                          pollingIntervalMinutes: value,
                        );
                        ref
                            .read(settingsProvider.notifier)
                            .updateNotifications(updated);
                      }
                    },
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings currentSettings,
    String title,
    String subtitle,
    bool value,
    NotificationSettings Function(bool value) onUpdate, {
    bool indent = false,
  }) {
    return CheckboxListTile(
      contentPadding: indent
          ? const EdgeInsets.only(left: 32, right: 16)
          : const EdgeInsets.symmetric(horizontal: 16),
      title: Text(title, style: TextStyle(fontSize: indent ? 14 : 16)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: indent ? 12 : 14)),
      value: value,
      onChanged: (newValue) async {
        if (newValue != null) {
          final updated = onUpdate(newValue);
          await ref
              .read(settingsProvider.notifier)
              .updateNotifications(updated);
          if (context.mounted) {
            _handleAutoConfigure(context, ref, silent: true, settings: updated);
          }
        }
      },
    );
  }

  Widget _buildSetupInstructions(
    BuildContext context,
    NotificationSettings settings,
    WidgetRef ref,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Setup in Radarr/Sonarr',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Auto-configure *arr instances'),
                onPressed: () => _handleAutoConfigure(context, ref),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'OR MANUAL SETUP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text('1. Go to Settings > Connect'),
            const Text('2. Add new connection > ntfy'),
            const Text('3. Configure:'),
            const SizedBox(height: 8),
            _buildConfigRow('Server URL', 'https://ntfy.sh'),
            _buildConfigRow('Topic', settings.ntfyTopic ?? ''),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('ntfy documentation'),
              onPressed: () =>
                  launchUrl(Uri.parse('https://docs.ntfy.sh/integrations/')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  /// Orchestrates the auto-configuration process for all configured instances.
  ///
  /// Displays a loading dialog (unless [silent] is true) and iterates through
  /// all instances, calling [RemoteNotificationService.configureInstance] for each.
  /// Result summaries are shown in a dialog or SnackBar.
  Future<void> _handleAutoConfigure(
    BuildContext context,
    WidgetRef ref, {
    bool silent = false,
    NotificationSettings? settings,
  }) async {
    logger.info(
      '[NotificationSettingsScreen] Starting auto-configuration (silent: $silent)',
    );
    final instances = ref.read(instancesProvider).instances;
    if (instances.isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No instances configured')),
        );
      }
      return;
    }

    if (!silent) {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-configuring notifications...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final service = ref.read(remoteNotificationServiceProvider);
    final results = <NotificationSetupResult>[];

    try {
      for (final instance in instances) {
        final result = await service.configureInstance(
          instance,
          settings: settings,
        );
        results.add(result);
      }
    } catch (e, st) {
      logger.error(
        '[NotificationSettingsScreen] Error during auto-configure',
        e,
        st,
      );
      results.add(NotificationSetupResult.failure('Unexpected error: $e'));
    } finally {
      if (!silent && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!context.mounted) return;

    if (!silent) {
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (context) => AlertDialog(
          title: const Text('Setup Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: results
                .map(
                  (r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      r.isSuccess ? Icons.check_circle : Icons.error,
                      color: r.isSuccess ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      r.message,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      final successCount = results.where((r) => r.isSuccess).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$successCount/${instances.length} instances configured.',
          ),
          backgroundColor: successCount == instances.length
              ? Colors.green
              : Colors.orange,
        ),
      );
    }
  }
}
