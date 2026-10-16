import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../l10n/labels.dart';
import '../../providers/advanced_providers.dart';

/// Lists available quality profiles from connected instances.
class QualityProfilesScreen extends ConsumerWidget {
  const QualityProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieProfilesAsync = ref.watch(movieQualityProfilesProvider);
    final seriesProfilesAsync = ref.watch(seriesQualityProfilesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.qualityProfilesTitle)),
      body: ListView(
        children: [
          _buildSectionHeader(context, context.l10n.qualityProfilesRadarr),
          movieProfilesAsync.when(
            data: (profiles) => _buildProfilesList(context, profiles),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => ListTile(
              title: Text(
                context.l10n.commonErrorWithDetails(
                  describeError(err, context.l10n),
                ),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, context.l10n.qualityProfilesSonarr),
          seriesProfilesAsync.when(
            data: (profiles) => _buildProfilesList(context, profiles),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => ListTile(
              title: Text(
                context.l10n.commonErrorWithDetails(
                  describeError(err, context.l10n),
                ),
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

  Widget _buildProfilesList(BuildContext context, List profiles) {
    if (profiles.isEmpty) {
      return ListTile(title: Text(context.l10n.qualityProfilesEmpty));
    }

    return Column(
      children: profiles
          .map(
            (p) => ListTile(
              leading: const Icon(Icons.high_quality),
              title: Text(p.name),
              trailing: Text(
                context.l10n.qualityProfilesId('${p.id}'),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          )
          .toList(),
    );
  }
}
