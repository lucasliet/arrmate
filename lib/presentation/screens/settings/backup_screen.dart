import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../providers/backup_provider.dart';

/// Settings screen for Google Drive backup and restore of app data.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!state.isConfigured)
            _buildNotConfiguredCard(context)
          else ...[
            if (state.isSignedIn) ...[
              _buildAccountCard(context, state),
              _buildActionsCard(context, ref, state),
            ] else
              _buildSignInCard(context, ref),
            const SizedBox(height: 8),
            Text(
              'Automatic backups run about 30 seconds after you change '
              'instances or settings, while signed in. Some settings (like '
              'the home tab) apply fully after restarting the app.',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotConfiguredCard(BuildContext context) {
    return Card(
      key: const Key('backupNotConfiguredCard'),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 32,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup not available',
                    style: context.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This build was compiled without Google credentials. '
                    'Ask the developer to build with the Google OAuth '
                    'configuration, or run locally with the --dart-define '
                    'flags.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
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

  Widget _buildSignInCard(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 32,
              color: context.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text('Google Drive backup', style: context.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Your settings, preferences and configured instances '
              "(including their API keys) are stored in the app's private "
              'folder on your Google Drive, invisible to other apps.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('backupSignInButton'),
              onPressed: () => ref.read(backupProvider.notifier).signIn(),
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, BackupState state) {
    final lastBackup = state.lastBackupAt == null
        ? 'never'
        : _formatTimestamp(state.lastBackupAt!);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 32,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.accountEmail ?? '',
                        style: context.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last backup: $lastBackup',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (state.statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.statusMessage!,
                key: const Key('backupStatusMessage'),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.primary,
                ),
              ),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                key: const Key('backupErrorMessage'),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(
    BuildContext context,
    WidgetRef ref,
    BackupState state,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            key: const Key('backupNowButton'),
            leading: const Icon(Icons.backup),
            title: const Text('Back up now'),
            trailing: state.isWorking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: state.isWorking
                ? null
                : () => ref.read(backupProvider.notifier).backupNow(),
          ),
          ListTile(
            key: const Key('backupRestoreButton'),
            leading: const Icon(Icons.restore),
            title: const Text('Restore backup…'),
            onTap: state.isWorking ? null : () => _startRestore(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => ref.read(backupProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }

  Future<void> _startRestore(BuildContext context, WidgetRef ref) async {
    final payload = await ref
        .read(backupProvider.notifier)
        .fetchBackupPreview();
    if (!context.mounted || payload == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('backupRestoreConfirmDialog'),
        title: const Text('Restore backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Created: ${_formatTimestamp(payload.createdAt)}'),
            const SizedBox(height: 4),
            Text('App version: ${payload.appVersion}'),
            const SizedBox(height: 4),
            Text('Platform: ${payload.platform}'),
            const SizedBox(height: 4),
            Text('Instances: ${payload.instanceCount}'),
            const SizedBox(height: 12),
            Text(
              'This replaces the settings and instances currently on this '
              'device.',
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('backupRestoreConfirmButton'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final restored = await ref
        .read(backupProvider.notifier)
        .restoreFrom(payload);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(restored ? 'Backup restored' : 'Restore failed'),
        backgroundColor: restored ? Colors.green : context.colorScheme.error,
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    return DateFormat('d MMM y HH:mm').format(value);
  }
}
