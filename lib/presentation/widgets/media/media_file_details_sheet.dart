import 'package:flutter/material.dart';
import 'package:arrmate/core/constants/app_constants.dart';
import 'package:arrmate/core/utils/formatters.dart';
import 'package:arrmate/domain/models/models.dart';

/// A modal sheet displaying detailed information about a media file.
class MediaFileDetailsSheet extends StatelessWidget {
  final MediaFile file;
  final VoidCallback? onDelete;

  const MediaFileDetailsSheet({super.key, required this.file, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppBar(
              title: const Text('File Details'),
              automaticallyImplyLeading: false,
              actions: [
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete?.call();
                    },
                    tooltip: 'Delete File',
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(paddingMd),
                children: [
                  _buildSection(context, 'General', [
                    _buildInfoRow(
                      context,
                      'Path',
                      file.relativePath ?? file.path ?? 'Unknown',
                    ),
                    _buildInfoRow(context, 'Size', formatBytes(file.size)),
                    _buildInfoRow(
                      context,
                      'Date Added',
                      formatDate(file.dateAdded),
                    ),
                  ]),
                  if (file.quality != null) ...[
                    const SizedBox(height: 16),
                    _buildSection(context, 'Quality', [
                      _buildInfoRow(
                        context,
                        'Quality',
                        file.quality!.quality.name,
                      ),
                      if (file.quality!.quality.source != null)
                        _buildInfoRow(
                          context,
                          'Source',
                          file.quality!.quality.source!,
                        ),
                      if (file.quality!.quality.resolution != null)
                        _buildInfoRow(
                          context,
                          'Resolution',
                          '${file.quality!.quality.resolution}p',
                        ),
                      _buildInfoRow(
                        context,
                        'Revision',
                        'v${file.quality!.revision}',
                      ),
                    ]),
                  ],
                  if (file.mediaInfo != null) ...[
                    const SizedBox(height: 16),
                    _buildMediaInfoSection(context),
                  ],
                  if (file.languages != null && file.languages!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      'Languages',
                      file.languages!
                          .map(
                            (lang) =>
                                _buildInfoRow(context, 'Language', lang.name),
                          )
                          .toList(),
                    ),
                  ],
                  if (file.customFormats != null &&
                      file.customFormats!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCustomFormatsSection(context),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildMediaInfoSection(BuildContext context) {
    final mediaInfo = file.mediaInfo!;
    final infoRows = <Widget>[];

    if (mediaInfo.videoCodec != null) {
      infoRows.add(
        _buildInfoRow(context, 'Video Codec', mediaInfo.videoCodec!),
      );
    }
    if (mediaInfo.resolution != null) {
      infoRows.add(_buildInfoRow(context, 'Resolution', mediaInfo.resolution!));
    }
    if (mediaInfo.videoFps != null) {
      infoRows.add(
        _buildInfoRow(context, 'Frame Rate', '${mediaInfo.videoFps} fps'),
      );
    }
    if (mediaInfo.videoBitrate != null) {
      infoRows.add(
        _buildInfoRow(
          context,
          'Video Bitrate',
          '${mediaInfo.videoBitrate} kbps',
        ),
      );
    }
    if (mediaInfo.videoBitDepth != null) {
      infoRows.add(
        _buildInfoRow(context, 'Bit Depth', '${mediaInfo.videoBitDepth} bit'),
      );
    }
    if (mediaInfo.videoDynamicRange != null) {
      infoRows.add(
        _buildInfoRow(context, 'Dynamic Range', mediaInfo.videoDynamicRange!),
      );
    }
    if (mediaInfo.videoDynamicRangeType != null) {
      infoRows.add(
        _buildInfoRow(context, 'HDR Type', mediaInfo.videoDynamicRangeType!),
      );
    }
    if (mediaInfo.scanType != null) {
      infoRows.add(_buildInfoRow(context, 'Scan Type', mediaInfo.scanType!));
    }
    if (mediaInfo.runTime != null) {
      infoRows.add(_buildInfoRow(context, 'Duration', mediaInfo.runTime!));
    }
    if (mediaInfo.audioCodec != null) {
      infoRows.add(
        _buildInfoRow(context, 'Audio Codec', mediaInfo.audioCodec!),
      );
    }
    if (mediaInfo.audioChannels != null) {
      infoRows.add(
        _buildInfoRow(context, 'Audio Channels', '${mediaInfo.audioChannels}'),
      );
    }
    if (mediaInfo.audioBitrate != null) {
      infoRows.add(
        _buildInfoRow(
          context,
          'Audio Bitrate',
          '${mediaInfo.audioBitrate} kbps',
        ),
      );
    }
    if (mediaInfo.audioStreamCount != null) {
      infoRows.add(
        _buildInfoRow(
          context,
          'Audio Streams',
          '${mediaInfo.audioStreamCount}',
        ),
      );
    }
    if (mediaInfo.audioLanguages != null) {
      infoRows.add(
        _buildInfoRow(context, 'Audio Languages', mediaInfo.audioLanguages!),
      );
    }
    if (mediaInfo.subtitles != null) {
      infoRows.add(_buildInfoRow(context, 'Subtitles', mediaInfo.subtitles!));
    }

    return _buildSection(context, 'Media Info', infoRows);
  }

  Widget _buildCustomFormatsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Formats',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...file.customFormats!.map((format) {
              final color = theme.colorScheme.primary;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(radiusSm),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  format.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
        if (file.customFormatScore != null) ...[
          const SizedBox(height: 8),
          Text(
            'Score: ${formatCustomScore(file.customFormatScore!)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
