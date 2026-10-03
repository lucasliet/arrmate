import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            ? 'Baixando Atualização'
            : (isInstalling ? 'Instalando...' : 'Nova Versão Disponível'),
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
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Preparando a atualização...'),
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
                const Text(
                  'O aplicativo será fechado e reiniciado para concluir a atualização.',
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Versão: ${info.version}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text('Changelog:', style: theme.textTheme.titleSmall),
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
                updateState.errorMessage ?? 'Ocorreu um erro inesperado.',
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
                child: const Text('Mais Tarde'),
              ),
              FilledButton(
                onPressed: () {
                  logger.info('[UpdateDialog] Update requested');
                  ref.read(updateProvider.notifier).startUpdate();
                },
                child: Text(
                  desktopUpdate ? 'Atualizar e reiniciar' : 'Atualizar Agora',
                ),
              ),
            ],
    );
  }
}
