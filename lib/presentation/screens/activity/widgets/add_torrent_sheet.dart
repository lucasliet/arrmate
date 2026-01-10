import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../domain/models/models.dart';
import '../providers/qbittorrent_provider.dart';

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
  final _tagsController = TextEditingController();

  bool _startPaused = false;
  String? _selectedFilePath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _urlsController.dispose();
    _savePathController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickTorrentFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['torrent'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _urlsController.clear(); // Clear URLs if file selected
        });
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to pick file: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one source provided
    if (_selectedFilePath == null && _urlsController.text.trim().isEmpty) {
      context.showErrorSnackBar(
        'Please provide URLs or select a .torrent file',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = AddTorrentRequest(
        urls: _urlsController.text.trim().isNotEmpty
            ? _urlsController.text.trim()
            : null,
        torrentFilePath: _selectedFilePath,
        savepath: _savePathController.text.trim().isNotEmpty
            ? _savePathController.text.trim()
            : null,
        category: _categoryController.text.trim().isNotEmpty
            ? _categoryController.text.trim()
            : null,
        tags: _tagsController.text.trim().isNotEmpty
            ? _tagsController.text.trim()
            : null,
        paused: _startPaused,
      );

      final notifier = ref.read(qbittorrentTorrentsProvider.notifier);

      if (request.torrentFilePath != null) {
        await notifier.addTorrentFile(request);
      } else {
        await notifier.addTorrentUrl(request);
      }

      if (mounted) {
        Navigator.pop(context);
        context.showSnackBar('Torrent added successfully');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to add torrent: ${e.toString()}');
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
              title: const Text('Add Torrent'),
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
                        'Source',
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // File Picker Button
                      if (_selectedFilePath != null) ...[
                        Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(_selectedFilePath!.split('/').last),
                            subtitle: Text(_selectedFilePath!),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(() => _selectedFilePath = null),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Center(child: Text('OR')),
                        const SizedBox(height: 16),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: _urlsController.text.isEmpty
                              ? _pickTorrentFile
                              : null, // Disable if text has content
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Select .torrent File'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // URLs Input
                      if (_selectedFilePath == null)
                        TextFormField(
                          controller: _urlsController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Magnet Link or URLs',
                            hintText:
                                'Paste magnet links or HTTP URLs here\nOne per line',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          onChanged: (_) =>
                              setState(() {}), // rebuild to toggle file button
                        ),

                      const SizedBox(height: 24),
                      Text(
                        'Options',
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _savePathController,
                        decoration: const InputDecoration(
                          labelText: 'Save Path (Optional)',
                          prefixIcon: Icon(Icons.folder_open),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category (Optional)',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (Optional)',
                          hintText: 'Comma separated',
                          prefixIcon: Icon(Icons.label),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      SwitchListTile(
                        title: const Text('Start Paused'),
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
                            : const Text('Add Torrent'),
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
