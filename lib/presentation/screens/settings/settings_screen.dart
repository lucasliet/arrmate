import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
