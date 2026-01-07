import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/logger_service.dart';
import '../../../core/services/remote_notification_setup_service.dart';
import '../../../domain/models/settings/notification_settings.dart';
import '../../providers/instances_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/settings_provider.dart';

/// A screen that allows users to configure in-app notifications via ntfy.sh.
///
/// Users can generate a unique topic, toggle specific notification triggers
/// (Grab, Import, etc.), and auto-configure their Radarr/Sonarr instances
/// to send webhooks to this device.
///
/// Notifications are displayed in-app only (no system push notifications).
/// Settings are saved locally on each toggle, but remote *arr instances are
/// only updated when the user leaves the screen, reducing network calls.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _hasChanges = false;

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      final currentSettings = ref.read(settingsProvider).notifications;
      if (currentSettings.enabled && mounted) {
        _handleAutoConfigure(silent: true, settings: currentSettings);
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifications = settings.notifications;
    final ntfyService = ref.watch(ntfyServiceProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _onWillPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: ListView(
          children: [
            // Info card about in-app notifications
            _buildInfoCard(context),
            if (notifications.ntfyTopic == null) ...[
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text('Setup Notifications'),
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
                  setState(() => _hasChanges = true);

                  if (value && mounted) {
                    _handleAutoConfigure(silent: true, settings: updated);
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
                      const SnackBar(
                        content: Text('Topic copied to clipboard'),
                      ),
                    );
                  },
                ),
              ),
              _buildSetupInstructions(notifications),
              if (notifications.enabled) ...[
                const Divider(),
                _buildSectionHeader('Downloads'),
                _buildNotificationToggle(
                  notifications,
                  'Notify on Grab',
                  'When a release is sent to download client',
                  notifications.notifyOnGrab,
                  (v) => notifications.copyWith(notifyOnGrab: v),
                ),
                _buildNotificationToggle(
                  notifications,
                  'Notify on Import',
                  'When a file is successfully imported',
                  notifications.notifyOnImport,
                  (v) => notifications.copyWith(notifyOnImport: v),
                ),
                _buildNotificationToggle(
                  notifications,
                  'Notify on Failure',
                  'When a download fails to import',
                  notifications.notifyOnDownloadFailed,
                  (v) => notifications.copyWith(notifyOnDownloadFailed: v),
                ),

                const Divider(),
                _buildSectionHeader('Media Updates'),
                _buildNotificationToggle(
                  notifications,
                  'Movie/Series Added',
                  'When a movie or series is added',
                  notifications.notifyOnMediaAdded,
                  (v) => notifications.copyWith(notifyOnMediaAdded: v),
                ),
                _buildNotificationToggle(
                  notifications,
                  'Movie/Series Deleted',
                  'When a movie or series is deleted',
                  notifications.notifyOnMediaDeleted,
                  (v) => notifications.copyWith(notifyOnMediaDeleted: v),
                ),
                _buildNotificationToggle(
                  notifications,
                  'File Deleted',
                  'When a media file is deleted',
                  notifications.notifyOnFileDelete,
                  (v) => notifications.copyWith(notifyOnFileDelete: v),
                ),

                const Divider(),
                _buildSectionHeader('System'),
                _buildNotificationToggle(
                  notifications,
                  '*arr Instance Update',
                  'When Radarr/Sonarr server is updated',
                  notifications.notifyOnUpgrade,
                  (v) => notifications.copyWith(notifyOnUpgrade: v),
                ),
                _buildNotificationToggle(
                  notifications,
                  'Manual Interaction',
                  'When manual intervention is required',
                  notifications.notifyOnManualRequired,
                  (v) => notifications.copyWith(notifyOnManualRequired: v),
                ),
                _buildNotificationToggle(
                  notifications,
                  'Health Issues',
                  'When system health issues are detected',
                  notifications.notifyOnHealthIssue,
                  (v) => notifications.copyWith(notifyOnHealthIssue: v),
                ),
                if (notifications.notifyOnHealthIssue) ...[
                  _buildNotificationToggle(
                    notifications,
                    'Include Warnings',
                    'Also notify on health warnings',
                    notifications.includeHealthWarnings,
                    (v) => notifications.copyWith(includeHealthWarnings: v),
                    indent: true,
                  ),
                  _buildNotificationToggle(
                    notifications,
                    'Health Restored',
                    'When a health issue is resolved',
                    notifications.notifyOnHealthRestored,
                    (v) => notifications.copyWith(notifyOnHealthRestored: v),
                    indent: true,
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'In-App Notifications',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Notifications are received in real-time while the app is open. '
                    'When you close the app, new notifications will be fetched the next time you open it.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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
          setState(() => _hasChanges = true);
        }
      },
    );
  }

  Widget _buildSetupInstructions(NotificationSettings settings) {
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
                onPressed: () => _handleAutoConfigure(),
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
  Future<void> _handleAutoConfigure({
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
      if (!silent && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!mounted) return;

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
