import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../domain/models/qbittorrent/qbittorrent_models.dart';
import '../../../l10n/labels.dart';

import '../providers/torrent_file_providers.dart';

class ChangeLocationSheet extends ConsumerStatefulWidget {
  final Torrent torrent;

  const ChangeLocationSheet({super.key, required this.torrent});

  @override
  ConsumerState<ChangeLocationSheet> createState() =>
      _ChangeLocationSheetState();
}

class _ChangeLocationSheetState extends ConsumerState<ChangeLocationSheet> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.torrent.savePath);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(torrentActionProvider.notifier).setTorrentLocation([
          widget.torrent.hash,
        ], _controller.text);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.torrentLocationMoved),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.torrentMoveFailed(describeError(e, context.l10n)),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(torrentActionProvider).isLoading;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.torrentChangeSaveLocation,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.torrentChangeSaveLocationWarning,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.orange),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: context.l10n.torrentNewLocation,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.folder),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.torrentEnterValidPath;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(context.l10n.commonCancel),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(context.l10n.torrentMove),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
