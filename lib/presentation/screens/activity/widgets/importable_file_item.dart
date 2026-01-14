import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/models.dart';

class ImportableFileItem extends StatelessWidget {
  final ImportableFile file;
  final bool isSelected;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onEdit;

  const ImportableFileItem({
    super.key,
    required this.file,
    required this.isSelected,
    required this.onChanged,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMapping = file.series != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusMd),
        onTap: () => onChanged(!isSelected),
        child: Padding(
          padding: const EdgeInsets.all(paddingMd),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) => onChanged(value ?? false),
              ),
              const SizedBox(width: paddingSm),
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
                      _buildSubtitle(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (hasMapping) ...[
                      const SizedBox(height: 8),
                      _buildMappingBadge(theme),
                    ],
                    if (file.hasRejections) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: file.rejections
                            .map(_buildRejectionChip)
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: paddingSm),
                IconButton(
                  icon: Icon(
                    hasMapping ? Icons.edit : Icons.add_link,
                    color: hasMapping
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  tooltip: hasMapping ? 'Edit mapping' : 'Map to series',
                  onPressed: onEdit,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMappingBadge(ThemeData theme) {
    final seriesTitle = file.series!.title;
    final episodeCount = file.episodes?.length ?? 0;
    final episodeInfo = episodeCount > 0
        ? file.episodes!.map((e) => e.episodeLabel).join(', ')
        : 'No episodes';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tv, size: 14, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$seriesTitle • $episodeInfo',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
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
  }

  String _buildSubtitle() {
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

  Widget _buildRejectionChip(ImportableFileRejection rejection) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            rejection.reason,
            style: TextStyle(
              color: Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
