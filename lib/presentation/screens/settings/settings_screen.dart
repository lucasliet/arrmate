import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/ntfy_service.dart';
import '../../../domain/models/settings/notification_settings.dart';
import '../../providers/instances_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/update_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildInstancesSection(context, ref),
          const Divider(),
          _buildAppearanceSection(context, ref),
          const Divider(),
          _buildSystemSection(context),
          const Divider(),
          _buildNotificationsSection(context, ref),
          const Divider(),
          _buildAboutSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildInstancesSection(BuildContext context, WidgetRef ref) {
    final instancesState = ref.watch(instancesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Instances',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (instancesState.instances.isEmpty)
          const PasteMessage(message: 'No instances configured'),
        ...instancesState.instances.map((instance) {
          final versionInfo = instance.version != null
              ? ' · v${instance.version}'
              : '';
          final tagsInfo = instance.tags.isNotEmpty
              ? ' · ${instance.tags.length} tags'
              : '';

          return ListTile(
            leading: Icon(
              instance.type.name == 'radarr' ? Icons.movie : Icons.tv,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(instance.label),
            subtitle: Text(instance.url + versionInfo + tagsInfo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/instance/${instance.id}');
            },
          );
        }),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add Instance'),
          onTap: () {
            context.push('/settings/instance/new');
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          title: const Text('Theme Mode'),
          subtitle: Text(settings.appearance.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showAppearanceDialog(context, ref, settings.appearance);
          },
        ),
        ListTile(
          title: const Text('Color Scheme'),
          subtitle: Text(settings.colorScheme.label),
          trailing: Icon(Icons.circle, color: settings.colorScheme.color),
          onTap: () {
            _showColorSchemeDialog(context, ref, settings.colorScheme);
          },
        ),
      ],
    );
  }

  void _showAppearanceDialog(
    BuildContext context,
    WidgetRef ref,
    AppAppearance current,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Mode'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppAppearance.values.map((mode) {
                final isSelected = mode == current;
                return ListTile(
                  title: Text(mode.label),
                  leading: Icon(
                    mode == AppAppearance.light
                        ? Icons.light_mode
                        : mode == AppAppearance.dark
                        ? Icons.dark_mode
                        : Icons.brightness_auto,
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setAppearance(mode);
                    context.pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showColorSchemeDialog(
    BuildContext context,
    WidgetRef ref,
    AppColorScheme current,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Color'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: AppColorScheme.values.map((scheme) {
                return InkWell(
                  onTap: () {
                    ref.read(settingsProvider.notifier).setColorScheme(scheme);
                    context.pop();
                  },
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.color,
                      shape: BoxShape.circle,
                      border: current == scheme
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsSection(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifications = settings.notifications;
    final ntfyService = ref.watch(ntfyServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
              ntfyService.isConnected ? 'Connected to ntfy.sh' : 'Disconnected',
            ),
            secondary: Icon(
              ntfyService.isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: ntfyService.isConnected ? Colors.green : Colors.grey,
            ),
            value: notifications.enabled,
            onChanged: (value) {
              ref
                  .read(settingsProvider.notifier)
                  .updateNotifications(notifications.copyWith(enabled: value));
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
          _buildSetupInstructions(context, notifications),
          if (notifications.enabled) ...[
            const Divider(),
            CheckboxListTile(
              title: const Text('Notify on Grab'),
              subtitle: const Text('When a release is sent to download client'),
              value: notifications.notifyOnGrab,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateNotifications(
                        notifications.copyWith(notifyOnGrab: value),
                      );
                }
              },
            ),
            CheckboxListTile(
              title: const Text('Notify on Import'),
              subtitle: const Text('When a file is successfully imported'),
              value: notifications.notifyOnImport,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateNotifications(
                        notifications.copyWith(notifyOnImport: value),
                      );
                }
              },
            ),
            CheckboxListTile(
              title: const Text('Notify on Failure'),
              subtitle: const Text('When a download fails to import'),
              value: notifications.notifyOnDownloadFailed,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateNotifications(
                        notifications.copyWith(notifyOnDownloadFailed: value),
                      );
                }
              },
            ),
            CheckboxListTile(
              title: const Text('Notify on Health Issue'),
              subtitle: const Text('When system health issues are detected'),
              value: notifications.notifyOnHealthIssue,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateNotifications(
                        notifications.copyWith(notifyOnHealthIssue: value),
                      );
                }
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSetupInstructions(
    BuildContext context,
    NotificationSettings settings,
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

  Widget _buildSystemSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'SYSTEM MANAGEMENT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.library_books_outlined),
          title: const Text('Logs'),
          subtitle: const Text('System event logs'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/settings/logs'),
        ),
        ListTile(
          leading: const Icon(Icons.health_and_safety_outlined),
          title: const Text('Health'),
          subtitle: const Text('System health and issues'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/settings/health'),
        ),
        ListTile(
          leading: const Icon(Icons.high_quality_outlined),
          title: const Text('Quality Profiles'),
          subtitle: const Text('Available profiles from instances'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/settings/quality-profiles'),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'About',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '...';
            return ListTile(
              title: const Text('Version'),
              subtitle: Text(version),
              trailing: updateState.status == UpdateStatus.checking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : (updateState.status == UpdateStatus.upToDate
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          )
                        : const Icon(Icons.refresh, size: 20)),
              onTap: updateState.status == UpdateStatus.checking
                  ? null
                  : () async {
                      await ref
                          .read(updateProvider.notifier)
                          .checkForUpdate(force: true);
                      if (context.mounted &&
                          ref.read(updateProvider).status ==
                              UpdateStatus.upToDate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('App is up to date')),
                        );
                      }
                    },
            );
          },
        ),
        ListTile(
          title: const Text('Source Code'),
          subtitle: const Text('GitHub'),
          onTap: () {
            launchUrl(Uri.parse('https://github.com/lucasliet/arrmate'));
          },
        ),
      ],
    );
  }
}

class PasteMessage extends StatelessWidget {
  final String message;
  const PasteMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
