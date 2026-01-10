import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/models.dart';

import '../../providers/instances_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/update_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/notification_icon_button.dart';

/// Main settings screen for configuring instances, appearance, notifications, and about info.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [NotificationIconButton()],
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
          const _PasteMessage(message: 'No instances configured'),
        ...instancesState.instances.map((instance) {
          final versionInfo = instance.version != null
              ? ' · v${instance.version}'
              : '';
          final tagsInfo = instance.tags.isNotEmpty
              ? ' · ${instance.tags.length} tags'
              : '';

          return ListTile(
            leading: Icon(
              instance.type == InstanceType.radarr
                  ? Icons.movie
                  : (instance.type == InstanceType.sonarr
                        ? Icons.tv
                        : Icons.download),
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
        ListTile(
          title: const Text('Home Tab'),
          subtitle: Text(settings.homeTab.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showHomeTabDialog(context, ref, settings.homeTab);
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

  void _showHomeTabDialog(BuildContext context, WidgetRef ref, AppTab current) {
    final selectableTabs = AppTab.values
        .where((t) => t != AppTab.settings)
        .toList();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Home Tab'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: selectableTabs.map((tab) {
                final isSelected = tab == current;
                return ListTile(
                  title: Text(tab.label),
                  leading: Icon(tab.icon),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setHomeTab(tab);
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
        ListTile(
          leading: Icon(
            notifications.enabled
                ? Icons.notifications_active
                : Icons.notifications_none,
            color: notifications.enabled
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          title: const Text('Notification Settings'),
          subtitle: Text(
            notifications.enabled
                ? 'Enabled · ntfy.sh integration'
                : 'Setup notifications',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/notifications'),
        ),
        ListTile(
          leading: const Icon(Icons.inbox),
          title: const Text('Notification Center'),
          subtitle: Consumer(
            builder: (context, ref, _) {
              final unreadCount = ref.watch(unreadNotificationCountProvider);
              return Text(
                unreadCount > 0
                    ? '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}'
                    : 'View all notifications',
              );
            },
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/notifications'),
        ),
      ],
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
          onTap: () => context.push('/settings/logs'),
        ),
        ListTile(
          leading: const Icon(Icons.health_and_safety_outlined),
          title: const Text('Health'),
          subtitle: const Text('System health and issues'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/health'),
        ),
        ListTile(
          leading: const Icon(Icons.high_quality_outlined),
          title: const Text('Quality Profiles'),
          subtitle: const Text('Available profiles from instances'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/quality-profiles'),
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

class _PasteMessage extends StatelessWidget {
  final String message;
  const _PasteMessage({required this.message});

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
