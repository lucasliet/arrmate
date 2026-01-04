import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/settings/notification_settings.dart';
import '../../providers/instances_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
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
          _buildAboutSection(context),
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
          return ListTile(
            leading: Icon(
              instance.type.name == 'radarr' ? Icons.movie : Icons.tv,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(instance.label),
            subtitle: Text(instance.url),
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

  void _showAppearanceDialog(BuildContext context, WidgetRef ref, AppAppearance current) {
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
                    mode == AppAppearance.light ? Icons.light_mode : 
                    mode == AppAppearance.dark ? Icons.dark_mode : Icons.brightness_auto,
                  ),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
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

  void _showColorSchemeDialog(BuildContext context, WidgetRef ref, AppColorScheme current) {
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
                        ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
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
        SwitchListTile(
          title: const Text('Enable Notifications'),
          subtitle: const Text('Periodically check for activity updates'),
          value: notifications.enabled,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updateNotifications(
                  notifications.copyWith(enabled: value),
                );
          },
        ),
        if (notifications.enabled) ...[
          CheckboxListTile(
            title: const Text('Notify on Grab'),
            subtitle: const Text('When a new release is sent to download client'),
            value: notifications.notifyOnGrab,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).updateNotifications(
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
                ref.read(settingsProvider.notifier).updateNotifications(
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
                ref.read(settingsProvider.notifier).updateNotifications(
                      notifications.copyWith(notifyOnDownloadFailed: value),
                    );
              }
            },
          ),
          ListTile(
            title: const Text('Polling Interval'),
            subtitle: Text('${notifications.pollingIntervalMinutes} minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showPollingIntervalDialog(context, ref, notifications.pollingIntervalMinutes);
            },
          ),
        ],
      ],
    );
  }

  void _showPollingIntervalDialog(BuildContext context, WidgetRef ref, int current) {
    final intervals = [15, 30, 60, 120, 240, 480, 1440];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Polling Interval'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: intervals.map((min) {
                final isSelected = min == current;
                final label = min < 60 ? '$min minutes' : '${min ~/ 60} hours';
                return ListTile(
                  title: Text(label),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () {
                    final settings = ref.read(settingsProvider);
                    ref.read(settingsProvider.notifier).updateNotifications(
                          settings.notifications.copyWith(pollingIntervalMinutes: min),
                        );
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

  Widget _buildAboutSection(BuildContext context) {
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
        ListTile(
          title: const Text('Version'),
          subtitle: const Text('0.1.0'),
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
