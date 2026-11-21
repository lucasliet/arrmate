import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/file_dialog.dart';
import '../../../../domain/models/models.dart';
import '../../../l10n/labels.dart';
import '../providers/qbittorrent_provider.dart';
import 'category_autocomplete_field.dart';
import 'tags_autocomplete_field.dart';

class AddTorrentSheet extends ConsumerStatefulWidget {
  const AddTorrentSheet({super.key});

  @override
  ConsumerState<AddTorrentSheet> createState() => _AddTorrentSheetState();
}

class _AddTorrentSheetState extends ConsumerState<AddTorrentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _urlsController = TextEditingController();
  final _savePathController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _startPaused = false;
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  List<String> _selectedTags = [];

  @override
  void dispose() {
    _urlsController.dispose();
    _savePathController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickTorrentFile() async {
    try {
      final result = await guardFileDialog(
        () => FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['torrent'],
          // The web has no file path, only the contents.
          withData: kIsWeb,
        ),
      );
      final file = result?.files.single;
      if (file != null && (file.bytes != null || _pathOf(file) != null)) {
        setState(() {
          _selectedFile = file;
          _urlsController.clear(); // Clear URLs if file selected
        });
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          context.l10n.torrentPickFileFailed(describeError(e, context.l10n)),
        );
      }
    }
  }

  /// Returns the local path of [file], or null on the web, where the path
  /// of a picked file is a blob URL that cannot be read as a file.
  String? _pathOf(PlatformFile file) => kIsWeb ? null : file.path;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one source provided
    if (_selectedFile == null && _urlsController.text.trim().isEmpty) {
      context.showErrorSnackBar(context.l10n.torrentAddSourceRequired);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final selectedFile = _selectedFile;
      final request = AddTorrentRequest(
        urls: _urlsController.text.trim().isNotEmpty
            ? _urlsController.text.trim()
            : null,
        torrentFilePath: selectedFile == null ? null : _pathOf(selectedFile),
        torrentFileBytes: selectedFile?.bytes,
        torrentFileName: selectedFile?.name,
        savepath: _savePathController.text.trim().isNotEmpty
            ? _savePathController.text.trim()
            : null,
        category: _categoryController.text.trim().isNotEmpty
            ? _categoryController.text.trim()
            : null,
        tags: _selectedTags.isNotEmpty ? _selectedTags.join(',') : null,
        paused: _startPaused,
      );

      final notifier = ref.read(qbittorrentTorrentsProvider.notifier);

      if (request.hasTorrentFile) {
        await notifier.addTorrentFile(request);
      } else {
        await notifier.addTorrentUrl(request);
      }

      if (mounted) {
        final l10n = context.l10n;
        Navigator.pop(context);
        context.showSnackBar(l10n.torrentAdded);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          context.l10n.torrentAddFailed(describeError(e, context.l10n)),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basic validation: either file path or text must not be empty (handled on submit too, but validator helps)

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppBar(
              title: Text(context.l10n.torrentAddTorrent),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.torrentAddSource,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // File Picker Button
                      if (_selectedFile case final file?) ...[
                        Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(file.name),
                            subtitle: switch (_pathOf(file)) {
                              final path? => Text(path),
                              null => null,
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(() => _selectedFile = null),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(child: Text(context.l10n.torrentAddOr)),
                        const SizedBox(height: 16),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: _urlsController.text.isEmpty
                              ? _pickTorrentFile
                              : null, // Disable if text has content
                          icon: const Icon(Icons.file_upload),
                          label: Text(context.l10n.torrentSelectFile),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // URLs Input
                      if (_selectedFile == null)
                        TextFormField(
                          controller: _urlsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: context.l10n.torrentUrlsLabel,
                            hintText: context.l10n.torrentUrlsHint,
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          onChanged: (_) =>
                              setState(() {}), // rebuild to toggle file button
                        ),

                      const SizedBox(height: 24),
                      Text(
                        context.l10n.torrentAddOptions,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _savePathController,
                        decoration: InputDecoration(
                          labelText: context.l10n.torrentSavePathOptional,
                          prefixIcon: const Icon(Icons.folder_open),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      CategoryAutocompleteField(
                        controller: _categoryController,
                        onFetchCategories: () async {
                          final notifier = ref.read(
                            qbittorrentTorrentsProvider.notifier,
                          );
                          return await notifier.fetchCategories();
                        },
                      ),
                      const SizedBox(height: 12),

                      TagsAutocompleteField(
                        selectedTags: _selectedTags,
                        onTagsChanged: (tags) {
                          setState(() => _selectedTags = tags);
                        },
                        onFetchTags: () async {
                          final notifier = ref.read(
                            qbittorrentTorrentsProvider.notifier,
                          );
                          return await notifier.fetchTags();
                        },
                      ),
                      const SizedBox(height: 12),

                      SwitchListTile(
                        title: Text(context.l10n.torrentStartPaused),
                        value: _startPaused,
                        onChanged: (val) => setState(() => _startPaused = val),
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 24),

                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(context.l10n.torrentAddTorrent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
