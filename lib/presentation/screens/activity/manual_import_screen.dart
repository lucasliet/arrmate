import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../domain/models/models.dart';
import '../../widgets/common_widgets.dart';
import 'providers/manual_import_provider.dart';
import 'widgets/importable_file_item.dart';
import '../../l10n/labels.dart';

/// A modal sheet for manually importing files from a download.
class ManualImportScreen extends ConsumerStatefulWidget {
  /// Queue item whose files will be imported.
  final QueueItem item;

  const ManualImportScreen({super.key, required this.item});

  @override
  ConsumerState<ManualImportScreen> createState() => _ManualImportScreenState();
}

class _ManualImportScreenState extends ConsumerState<ManualImportScreen> {
  final Set<int> _selectedFileIds = {};
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final filesState = ref.watch(manualImportFilesProvider(widget.item));
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppBar(
              title: Text(context.l10n.manualImportTitle),
              automaticallyImplyLeading: false,
              actions: [
                if (_selectedFileIds.isNotEmpty)
                  TextButton(
                    onPressed: _isImporting ? null : _handleImport,
                    child: _isImporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.commonImport),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: filesState.when(
                data: (files) {
                  if (files.isEmpty) {
                    return EmptyState(
                      icon: Icons.file_download_off_outlined,
                      title: context.l10n.manualImportEmptyTitle,
                      subtitle: context.l10n.manualImportEmptySubtitle,
                    );
                  }

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(paddingMd),
                    children: [
                      _buildHeader(theme, files),
                      const SizedBox(height: paddingMd),
                      ...files.map(
                        (file) => ImportableFileItem(
                          file: file,
                          isSelected: _selectedFileIds.contains(file.id),
                          onChanged: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFileIds.add(file.id);
                              } else {
                                _selectedFileIds.remove(file.id);
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () =>
                    LoadingIndicator(message: context.l10n.manualImportLoading),
                error: (error, stack) => ErrorDisplay(
                  message: context.l10n.manualImportLoadFailed,
                  onRetry: () =>
                      ref.refresh(manualImportFilesProvider(widget.item)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, List<ImportableFile> files) {
    final validFiles = files.where((f) => !f.hasRejections).length;
    final rejectedFiles = files.where((f) => f.hasRejections).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.item.localizedDisplayTitle(context.l10n),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: paddingSm),
        Row(
          children: [
            if (validFiles > 0) ...[
              Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                context.l10n.manualImportValidCount(validFiles),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
              ),
            ],
            if (validFiles > 0 && rejectedFiles > 0) const Text(' • '),
            if (rejectedFiles > 0) ...[
              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                context.l10n.manualImportIssueCount(rejectedFiles),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
        if (_selectedFileIds.isNotEmpty) ...[
          const SizedBox(height: paddingSm),
          Text(
            context.l10n.manualImportSelectedCount(_selectedFileIds.length),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleImport() async {
    try {
      final filesState = await ref.read(
        manualImportFilesProvider(widget.item).future,
      );
      final selectedFiles = filesState
          .where((f) => _selectedFileIds.contains(f.id))
          .toList();

      if (selectedFiles.isEmpty) {
        if (mounted) {
          context.showErrorSnackBar(context.l10n.manualImportNoFilesSelected);
        }
        return;
      }

      setState(() => _isImporting = true);

      final controller = ref.read(manualImportControllerProvider(widget.item));
      await controller.importFiles(selectedFiles);

      if (mounted) {
        Navigator.pop(context);
        context.showSnackBar(
          context.l10n.manualImportSuccess(selectedFiles.length),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        context.showErrorSnackBar(
          context.l10n.manualImportFailed(describeError(e, context.l10n)),
        );
      }
    }
  }
}
