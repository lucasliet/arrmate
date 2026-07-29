import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/update_service.dart';

/// Dialog that presents the changelog of the running version when the user
/// has not seen it yet, typically right after installing an update.
class WhatsNewDialog extends ConsumerWidget {
  final AppReleaseInfo release;

  const WhatsNewDialog({super.key, required this.release});

  /// Presents the dialog when a "What's New" release is available.
  static Future<void> showIfNeeded(BuildContext context, WidgetRef ref) async {
    final service = ref.read(updateServiceProvider);
    final release = await service.whatsNewForCurrentVersion();
    if (release == null) return;
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WhatsNewDialog(release: release),
    );
    await service.markVersionSeen(release.version);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: const Icon(Icons.new_releases_rounded),
      title: Text('What\'s New in v${release.version}'),
      content: SizedBox(
        width: double.maxFinite,
        child: release.changelog.isEmpty
            ? const Text('This release does not include release notes.')
            : SingleChildScrollView(
                child: Text(
                  release.changelog,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Dismiss'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _openVersionHistory(context);
          },
          child: const Text('View All Versions'),
        ),
      ],
    );
  }

  void _openVersionHistory(BuildContext context) {
    context.push('/settings/version-history');
  }
}
