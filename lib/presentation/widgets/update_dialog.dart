import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/extensions/context_extensions.dart';
import '../l10n/core_labels.dart' show UpdateStateL10n;
import '../providers/update_provider.dart';
import '../../core/services/logger_service.dart';
import '../../core/platform/platform_capabilities.dart';

/// Dialog displayed when an application update is available.
class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    if (updateState.info == null) return const SizedBox.shrink();

    final info = updateState.info!;
    final isDownloading = updateState.status == UpdateStatus.downloading;
    final isInstalling = updateState.status == UpdateStatus.installing;
    final desktopUpdate =
        ref.watch(platformCapabilitiesProvider).supportsAppUpdates &&
        defaultTargetPlatform != TargetPlatform.android;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(
        isDownloading
            ? l10n.updateDownloadingTitle
            : (isInstalling
                  ? l10n.updateInstallingTitle
                  : l10n.updateAvailableTitle),
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isInstalling) ...[
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.updatePreparing),
                  ],
                ),
              ),
            ] else if (isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: updateState.progress / 100,
                backgroundColor: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${updateState.progress.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ] else ...[
              if (desktopUpdate) ...[
                Text(l10n.updateRestartNotice),
                const SizedBox(height: 12),
              ],
              Text(
                l10n.updateVersion(info.version),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.updateChangelog, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(info.changelog, style: theme.textTheme.bodySmall),
              ),
            ],
            if (updateState.status == UpdateStatus.error) ...[
              const SizedBox(height: 12),
              Text(
                updateState.localizedErrorMessage(l10n) ??
                    l10n.updateUnexpectedError,
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: (isDownloading || isInstalling)
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.updateLater),
              ),
              FilledButton(
                onPressed: () {
                  logger.info('[UpdateDialog] Update requested');
                  ref.read(updateProvider.notifier).startUpdate();
                },
                child: Text(
                  desktopUpdate ? l10n.updateAndRestart : l10n.updateNow,
                ),
              ),
            ],
    );
  }
}
