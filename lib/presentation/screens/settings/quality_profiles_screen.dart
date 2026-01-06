import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/advanced_providers.dart';

/// Lists available quality profiles from connected instances.
class QualityProfilesScreen extends ConsumerWidget {
  const QualityProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieProfilesAsync = ref.watch(movieQualityProfilesProvider);
    final seriesProfilesAsync = ref.watch(seriesQualityProfilesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quality Profiles')),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Radarr Profiles'),
          movieProfilesAsync.when(
            data: (profiles) => _buildProfilesList(profiles),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => ListTile(
              title: Text(
                'Error: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Sonarr Profiles'),
          seriesProfilesAsync.when(
            data: (profiles) => _buildProfilesList(profiles),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => ListTile(
              title: Text(
                'Error: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
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

  Widget _buildProfilesList(List profiles) {
    if (profiles.isEmpty) {
      return const ListTile(
        title: Text('No profiles found or instance not connected'),
      );
    }

    return Column(
      children: profiles
          .map(
            (p) => ListTile(
              leading: const Icon(Icons.high_quality),
              title: Text(p.name),
              trailing: Text(
                'ID: ${p.id}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          )
          .toList(),
    );
  }
}
