import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../domain/models/models.dart';
import '../../widgets/common_widgets.dart';
import 'providers/manual_import_provider.dart';
import 'widgets/importable_file_item.dart';

/// A modal sheet for manually importing files from a download.
class ManualImportScreen extends ConsumerStatefulWidget {
  /// The ID of the download to import files from.
  final String downloadId;

  /// The title of the import operation/download.
  final String title;

  const ManualImportScreen({
    super.key,
    required this.downloadId,
    required this.title,
  });

  @override
  ConsumerState<ManualImportScreen> createState() => _ManualImportScreenState();
}

class _ManualImportScreenState extends ConsumerState<ManualImportScreen> {
  final Set<int> _selectedFileIds = {};
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final filesState = ref.watch(manualImportFilesProvider(widget.downloadId));
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
              title: Text('Manual Import'),
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
                        : const Text('Import'),
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
                      title: 'No Importable Files',
                      subtitle:
                          'There are no files available for manual import.',
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
                loading: () => const LoadingIndicator(
                  message: 'Loading importable files...',
                ),
                error: (error, stack) => ErrorDisplay(
                  message: 'Failed to load importable files',
                  onRetry: () =>
                      ref.refresh(manualImportFilesProvider(widget.downloadId)),
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
          widget.title,
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
                '$validFiles valid',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
              ),
            ],
            if (validFiles > 0 && rejectedFiles > 0) const Text(' • '),
            if (rejectedFiles > 0) ...[
              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                '$rejectedFiles with issues',
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
            '${_selectedFileIds.length} file(s) selected',
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
        manualImportFilesProvider(widget.downloadId).future,
      );
      final selectedFiles = filesState
          .where((f) => _selectedFileIds.contains(f.id))
          .toList();

      if (selectedFiles.isEmpty) {
        if (mounted) {
          context.showErrorSnackBar('No files selected');
        }
        return;
      }

      setState(() => _isImporting = true);

      final controller = ref.read(
        manualImportControllerProvider(widget.downloadId),
      );
      await controller.importFiles(selectedFiles);

      if (mounted) {
        Navigator.pop(context);
        context.showSnackBar(
          '${selectedFiles.length} file(s) imported successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        context.showErrorSnackBar('Failed to import: $e');
      }
    }
  }
}
