import 'package:flutter/material.dart';
import 'package:arrmate/core/constants/app_constants.dart';
import 'package:arrmate/core/utils/formatters.dart';
import 'package:arrmate/domain/models/models.dart';

class MediaFileCard extends StatelessWidget {
  final MediaFile file;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MediaFileCard({
    super.key,
    required this.file,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.movie_outlined,
                    size: iconSizeMd,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.relativePath ?? file.path ?? 'Unknown File',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _buildSubtitle(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      color: theme.colorScheme.error,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (file.customFormats != null &&
                  file.customFormats!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: file.customFormats!.map((format) {
                    return _buildCustomFormatBadge(context, format);
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];

    if (file.quality?.quality.name != null) {
      parts.add(file.quality!.quality.name);
    }

    if (file.languages != null && file.languages!.isNotEmpty) {
      parts.add(file.languages!.first.name);
    }

    parts.add(formatBytes(file.size));

    return formatListWithSeparator(parts);
  }

  Widget _buildCustomFormatBadge(
    BuildContext context,
    MediaCustomFormat format,
  ) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        format.name,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ).copyWith(color: color),
      ),
    );
  }
}
