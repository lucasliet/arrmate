import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../domain/models/models.dart';
import '../../widgets/common_widgets.dart';
import 'providers/manual_import_controller.dart';
import 'widgets/import_mapping_modal.dart';
import 'widgets/importable_file_item.dart';

class ManualImportScreen extends ConsumerStatefulWidget {
  final String downloadId;
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
    final controllerState = ref.watch(
      manualImportControllerNotifierProvider(widget.downloadId),
    );
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
              title: const Text('Manual Import'),
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
              child: controllerState.when(
                data: (state) {
                  if (state.files.isEmpty) {
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
                      _buildHeader(theme, state.files),
                      const SizedBox(height: paddingMd),
                      ...state.files.map(
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
                          onEdit: () => _openMappingModal(file),
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
                  onRetry: () => ref.invalidate(
                    manualImportControllerNotifierProvider(widget.downloadId),
                  ),
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
    final mappedFiles = files.where((f) => f.series != null).length;

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
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            if (validFiles > 0)
              _buildStatBadge(
                Icons.check_circle_outline,
                '$validFiles valid',
                Colors.green,
              ),
            if (rejectedFiles > 0)
              _buildStatBadge(
                Icons.warning_amber_rounded,
                '$rejectedFiles with issues',
                Colors.orange,
              ),
            if (mappedFiles > 0)
              _buildStatBadge(
                Icons.link,
                '$mappedFiles mapped',
                theme.colorScheme.primary,
              ),
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

  Widget _buildStatBadge(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  void _openMappingModal(ImportableFile file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ImportMappingModal(
        file: file,
        onApply: (updatedFile) {
          ref
              .read(
                manualImportControllerNotifierProvider(
                  widget.downloadId,
                ).notifier,
              )
              .updateFile(file.id, updatedFile);
        },
        onApplyToSimilar: () {
          ref
              .read(
                manualImportControllerNotifierProvider(
                  widget.downloadId,
                ).notifier,
              )
              .applyMappingToSimilar(file.id);
        },
      ),
    );
  }

  Future<void> _handleImport() async {
    final controller = ref.read(
      manualImportControllerNotifierProvider(widget.downloadId).notifier,
    );

    final warnings = controller.validateBeforeImport(_selectedFileIds.toList());
    if (warnings.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Warnings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The following issues were found:'),
              const SizedBox(height: 8),
              ...warnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $w', style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Continue anyway?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import Anyway'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    try {
      setState(() => _isImporting = true);

      await controller.commitImport(_selectedFileIds.toList());

      if (mounted) {
        Navigator.pop(context);
        context.showSnackBar(
          '${_selectedFileIds.length} file(s) imported successfully',
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
