import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/backup_service.dart';
import '../../providers/backup_provider.dart';

/// Settings screen for backup and restore of app data.
///
/// Native platforms offer Google Drive and a local JSON file. The web build
/// offers only the local file.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupProvider);
    final supportsGoogleDrive = ref.watch(googleDriveBackupSupportedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (supportsGoogleDrive && !state.isConfigured) ...[
            _buildNotConfiguredCard(context),
            const SizedBox(height: 12),
          ] else if (supportsGoogleDrive) ...[
            if (state.isSignedIn) ...[
              _buildAccountCard(context, state),
              if (state.hasRemoteBackupToRestore)
                _buildRemoteBackupCard(context, ref, state),
              _buildActionsCard(context, ref, state),
            ] else
              _buildSignInCard(context, ref, state),
            const SizedBox(height: 8),
            Text(
              context.l10n.backupAutomaticNote,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildLocalBackupCard(context, ref, state),
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
                    context.l10n.backupDriveUnavailableTitle,
                    style: context.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.backupDriveUnavailableMessage,
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

  Widget _buildSignInCard(
    BuildContext context,
    WidgetRef ref,
    BackupState state,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
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
            Text(
              context.l10n.backupDriveTitle,
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.backupDriveDescription,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('backupSignInButton'),
              onPressed: () => ref.read(backupProvider.notifier).signIn(),
              icon: const Icon(Icons.login),
              label: Text(context.l10n.backupSignInWithGoogle),
            ),
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

  Widget _buildAccountCard(BuildContext context, BackupState state) {
    final lastBackupAt = state.lastBackupAt ?? state.remoteBackupAt;
    final lastBackup = lastBackupAt == null
        ? context.l10n.backupNever
        : _formatTimestamp(lastBackupAt);

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
                        context.l10n.backupLastBackup(lastBackup),
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

  Widget _buildRemoteBackupCard(
    BuildContext context,
    WidgetRef ref,
    BackupState state,
  ) {
    return Card(
      key: const Key('backupRemoteBackupCard'),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      color: context.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_download_outlined,
                  color: context.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.backupFoundTitle,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: context.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.backupFoundMessage(
                _formatTimestamp(state.remoteBackupAt!),
              ),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('backupRemoteRestoreButton'),
              onPressed: state.isWorking
                  ? null
                  : () => _startRestore(context, ref),
              icon: const Icon(Icons.restore),
              label: Text(context.l10n.commonRestore),
            ),
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
            title: Text(context.l10n.backupNow),
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
            title: Text(context.l10n.backupRestoreBackupMenu),
            onTap: state.isWorking ? null : () => _startRestore(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(context.l10n.backupSignOut),
            onTap: () => ref.read(backupProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalBackupCard(
    BuildContext context,
    WidgetRef ref,
    BackupState state,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            key: const Key('backupExportFileButton'),
            leading: const Icon(Icons.ios_share),
            title: Text(context.l10n.backupExportToFile),
            subtitle: Text(context.l10n.backupExportToFileSubtitle),
            onTap: state.isWorking ? null : () => _exportToFile(context, ref),
          ),
          ListTile(
            key: const Key('backupImportFileButton'),
            leading: const Icon(Icons.folder_open),
            title: Text(context.l10n.backupRestoreFromFile),
            onTap: state.isWorking
                ? null
                : () => _startFileRestore(context, ref),
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
    final confirmed = await _confirmRestore(context, payload);
    if (!confirmed || !context.mounted) return;
    await _restoreConfirmed(context, ref, payload);
  }

  Future<void> _startFileRestore(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(backupProvider.notifier);
    final payload = await notifier.importFilePreview();
    if (!context.mounted) return;
    if (payload == null) {
      _showErrorSnackBar(context, ref);
      return;
    }
    final confirmed = await _confirmRestore(context, payload);
    if (!confirmed || !context.mounted) return;
    await _restoreConfirmed(context, ref, payload);
  }

  Future<void> _exportToFile(BuildContext context, WidgetRef ref) async {
    final fileName = await ref.read(backupProvider.notifier).exportToFile();
    if (!context.mounted) return;
    if (fileName != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.backupExported(fileName)),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    _showErrorSnackBar(context, ref);
  }

  Future<bool> _confirmRestore(
    BuildContext context,
    BackupPayload payload,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('backupRestoreConfirmDialog'),
        title: Text(dialogContext.l10n.backupRestoreConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dialogContext.l10n.backupCreated(
                _formatTimestamp(payload.createdAt),
              ),
            ),
            const SizedBox(height: 4),
            Text(dialogContext.l10n.backupAppVersion(payload.appVersion)),
            const SizedBox(height: 4),
            Text(dialogContext.l10n.backupPlatform(payload.platform)),
            const SizedBox(height: 4),
            Text(dialogContext.l10n.backupInstanceCount(payload.instanceCount)),
            const SizedBox(height: 12),
            Text(
              dialogContext.l10n.backupRestoreReplaceWarning,
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('backupRestoreConfirmButton'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.commonRestore),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _restoreConfirmed(
    BuildContext context,
    WidgetRef ref,
    BackupPayload payload,
  ) async {
    final restored = await ref
        .read(backupProvider.notifier)
        .restoreFrom(payload);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? context.l10n.backupRestored
              : context.l10n.backupRestoreFailed,
        ),
        backgroundColor: restored ? Colors.green : context.colorScheme.error,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, WidgetRef ref) {
    final error = ref.read(backupProvider).errorMessage;
    if (error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: context.colorScheme.error,
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    return DateFormat('d MMM y HH:mm').format(value);
  }
}
