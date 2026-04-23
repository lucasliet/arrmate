import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../providers/assistant_provider.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantProvider);
    final notifier = ref.read(assistantProvider.notifier);

    ref.listen<AssistantState>(assistantProvider, (prev, next) {
      if (prev?.isDownloading != next.isDownloading) {
        if (next.isDownloading) {
          _showDownloadDialog(context, next);
        } else if (!next.isDownloading && prev?.isDownloading == true) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }

      if (next.messages.length != prev?.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildModelSelector(context, notifier, state),
                const Divider(height: 1),
                Expanded(child: _messages(state)),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                _input(notifier, state),
              ],
            ),
    );
  }

  Widget _buildModelSelector(
    BuildContext context,
    AssistantNotifier notifier,
    AssistantState state,
  ) {
    final theme = Theme.of(context);
    final hasModel = state.hasModel;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              hasModel ? Icons.smart_toy : Icons.smart_toy_outlined,
              color: hasModel ? theme.colorScheme.primary : null,
            ),
            title: Text(
              state.selectedModel?.label ?? 'No model selected',
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(
              hasModel
                  ? _formatModelSize(state.selectedModel!.sizeBytes)
                  : 'Import or download a model to start',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: state.isDownloading
                    ? null
                    : () => _showCatalog(context, notifier, state),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download'),
              ),
              OutlinedButton.icon(
                onPressed: state.isImporting ? null : notifier.importModel,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Import'),
              ),
              if (state.installedModels.length > 1)
                OutlinedButton.icon(
                  onPressed: () => _showInstalled(context, notifier, state),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Switch'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _messages(AssistantState state) {
    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              state.hasModel ? 'Ask about the app' : 'Select a model first',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final m = state.messages[index];
        final isUser = m.role == AssistantMessageRole.user;
        final theme = Theme.of(context);

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              m.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUser
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _input(AssistantNotifier notifier, AssistantState state) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Ask about Arrmate...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(notifier, state),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: state.isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            onPressed: state.isGenerating || !state.hasModel
                ? null
                : () => _sendMessage(notifier, state),
          ),
        ],
      ),
    );
  }

  void _sendMessage(AssistantNotifier notifier, AssistantState state) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    notifier.sendMessage(text);
  }

  void _showDownloadDialog(BuildContext context, AssistantState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DownloadProgressDialog(),
    );
  }

  void _showCatalog(
    BuildContext context,
    AssistantNotifier notifier,
    AssistantState state,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Download Model', style: theme.textTheme.titleLarge),
          ),
          const Divider(height: 1),
          ...state.catalog.map((m) {
            final isInstalled = state.installedModels.any(
              (installed) => installed.id == m.id,
            );

            return ListTile(
              leading: Icon(
                isInstalled ? Icons.check_circle : Icons.download,
                color: isInstalled ? theme.colorScheme.primary : null,
              ),
              title: Text(m.title),
              subtitle: Text(m.description),
              trailing: isInstalled
                  ? Text(
                      'Installed',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                notifier.downloadModel(m);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showInstalled(
    BuildContext context,
    AssistantNotifier notifier,
    AssistantState state,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Switch Model', style: theme.textTheme.titleLarge),
          ),
          const Divider(height: 1),
          ...state.installedModels.map((m) {
            final isSelected = m.id == state.selectedModelId;

            return ListTile(
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
              title: Text(m.label),
              subtitle: Text(_formatModelSize(m.sizeBytes)),
              onTap: isSelected
                  ? null
                  : () {
                      Navigator.pop(context);
                      notifier.selectModel(m.id);
                    },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatModelSize(int bytes) {
    return formatBytes(bytes);
  }
}

class _DownloadProgressDialog extends ConsumerWidget {
  const _DownloadProgressDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assistantProvider);
    final notifier = ref.read(assistantProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: state.error != null,
      child: AlertDialog(
        title: Text(
          'Downloading Model',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: state.downloadProgress > 0
                  ? state.downloadProgress / 100
                  : null,
              backgroundColor: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                state.downloadProgress > 0
                    ? '${state.downloadProgress.toStringAsFixed(1)}%'
                    : 'Starting download...',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(state.error!, style: TextStyle(color: colorScheme.error)),
            ],
          ],
        ),
        actions: [
          if (state.error != null)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            )
          else
            TextButton(
              onPressed: () {
                notifier.cancelDownload();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }
}
