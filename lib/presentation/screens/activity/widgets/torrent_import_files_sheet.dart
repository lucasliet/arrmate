import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/models.dart';
import '../../../widgets/common_widgets.dart';
import '../providers/torrent_import_provider.dart';

/// Bottom sheet for mapping and importing torrent files to a movie or series.
class TorrentImportFilesSheet extends ConsumerStatefulWidget {
  final Torrent torrent;
  final bool isMovie;
  final Movie? movie;
  final Series? series;

  const TorrentImportFilesSheet({
    super.key,
    required this.torrent,
    required this.isMovie,
    this.movie,
    this.series,
  });

  @override
  ConsumerState<TorrentImportFilesSheet> createState() =>
      _TorrentImportFilesSheetState();
}

class _TorrentImportFilesSheetState
    extends ConsumerState<TorrentImportFilesSheet> {
  final Map<int, ImportableFile> _fileMappings = {};
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final params = ImportByFolderParams(
      folderPath: widget.torrent.savePath,
      isMovie: widget.isMovie,
    );
    final filesState = ref.watch(importableFilesByFolderProvider(params));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              AppBar(
                title: Text(
                  widget.isMovie ? 'Import to Movie' : 'Import to Series',
                ),
                automaticallyImplyLeading: false,
                actions: [
                  if (_fileMappings.isNotEmpty)
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
              _buildHeader(theme),
              const Divider(height: 1),
              Expanded(
                child: filesState.when(
                  data: (files) {
                    if (files.isEmpty) {
                      return EmptyState(
                        icon: Icons.file_download_off_outlined,
                        title: 'No Files Found',
                        subtitle:
                            'No importable files found in ${widget.torrent.savePath}',
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(paddingMd),
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        return _buildFileItem(file, theme);
                      },
                    );
                  },
                  loading: () =>
                      const LoadingIndicator(message: 'Loading files...'),
                  error: (error, stack) => ErrorDisplay(
                    message: 'Failed to load files: $error',
                    onRetry: () =>
                        ref.refresh(importableFilesByFolderProvider(params)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final targetName = widget.isMovie
        ? widget.movie?.title ?? 'Unknown Movie'
        : widget.series?.title ?? 'Unknown Series';

    return Padding(
      padding: const EdgeInsets.all(paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.isMovie ? Icons.movie_outlined : Icons.tv_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  targetName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select files to import. Tap on a file to configure its mapping.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_fileMappings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_fileMappings.length} file(s) selected for import',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileItem(ImportableFile file, ThemeData theme) {
    final isSelected = _fileMappings.containsKey(file.id);
    final hasMapping =
        file.movie != null ||
        (file.series != null && file.episodes?.isNotEmpty == true);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusMd),
        onTap: () => _toggleFileSelection(file),
        child: Padding(
          padding: const EdgeInsets.all(paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleFileSelection(file),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name ?? file.relativePath ?? 'Unknown',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _buildSubtitle(file),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasMapping) ...[
                const SizedBox(height: 8),
                _buildMappingInfo(file, theme),
              ],
              if (file.hasRejections) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: file.rejections.map((r) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              r.reason,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMappingInfo(ImportableFile file, ThemeData theme) {
    String mapping;
    if (widget.isMovie && file.movie != null) {
      mapping = file.movie!.title;
    } else if (!widget.isMovie && file.episodes?.isNotEmpty == true) {
      final eps = file.episodes!;
      if (eps.length == 1) {
        mapping =
            'S${eps.first.seasonNumber.toString().padLeft(2, '0')}'
            'E${eps.first.episodeNumber.toString().padLeft(2, '0')}';
      } else {
        final first = eps.first;
        final last = eps.last;
        mapping =
            'S${first.seasonNumber.toString().padLeft(2, '0')}'
            'E${first.episodeNumber.toString().padLeft(2, '0')}'
            '-E${last.episodeNumber.toString().padLeft(2, '0')}';
      }
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            mapping,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(ImportableFile file) {
    final parts = <String>[];

    if (file.quality?.quality.name != null) {
      parts.add(file.quality!.quality.name);
    }

    parts.add(formatBytes(file.size));

    if (file.releaseGroup != null) {
      parts.add(file.releaseGroup!);
    }

    return formatListWithSeparator(parts);
  }

  void _toggleFileSelection(ImportableFile file) {
    setState(() {
      if (_fileMappings.containsKey(file.id)) {
        _fileMappings.remove(file.id);
      } else {
        var mappedFile = file;
        if (widget.isMovie && widget.movie != null && file.movie == null) {
          mappedFile = ImportableFile(
            id: file.id,
            name: file.name,
            path: file.path,
            relativePath: file.relativePath,
            size: file.size,
            quality: file.quality,
            languages: file.languages,
            releaseGroup: file.releaseGroup,
            downloadId: file.downloadId,
            rejections: file.rejections,
            movie: widget.movie,
            series: file.series,
            episodes: file.episodes,
          );
        }
        _fileMappings[file.id] = mappedFile;
      }
    });
  }

  Future<void> _handleImport() async {
    if (_fileMappings.isEmpty) {
      context.showErrorSnackBar('No files selected');
      return;
    }

    setState(() => _isImporting = true);

    try {
      final controller = ref.read(
        torrentImportControllerProvider(widget.isMovie),
      );
      await controller.importFiles(_fileMappings.values.toList());

      if (mounted) {
        Navigator.pop(context);
        context.showSnackBar(
          '${_fileMappings.length} file(s) imported successfully',
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
