import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/models.dart';

/// A selectable list item for manual import files, showing file details and quality.
class ImportableFileItem extends StatelessWidget {
  /// The file to display.
  final ImportableFile file;

  /// Whether this file is currently selected for import.
  final bool isSelected;

  /// Callback when the selection state changes.
  final ValueChanged<bool> onChanged;

  const ImportableFileItem({
    super.key,
    required this.file,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
