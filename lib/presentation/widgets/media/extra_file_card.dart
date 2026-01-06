import 'package:flutter/material.dart';
import 'package:arrmate/core/constants/app_constants.dart';
import 'package:arrmate/domain/models/models.dart';

class ExtraFileCard extends StatelessWidget {
  final String relativePath;
  final String? extension;
  final ExtraFileType type;
  final VoidCallback? onTap;

  const ExtraFileCard({
    super.key,
    required this.relativePath,
    this.extension,
    required this.type,
    this.onTap,
  });

  factory ExtraFileCard.fromMovieExtraFile(
    MovieExtraFile file, {
    VoidCallback? onTap,
  }) {
    return ExtraFileCard(
      relativePath: file.relativePath ?? 'Unknown',
      extension: file.extension,
      type: file.type,
      onTap: onTap,
    );
  }

  factory ExtraFileCard.fromSeriesExtraFile(
    SeriesExtraFile file, {
    VoidCallback? onTap,
  }) {
    return ExtraFileCard(
      relativePath: file.relativePath ?? 'Unknown',
      extension: file.extension,
      type: file.type,
      onTap: onTap,
    );
  }

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
          child: Row(
            children: [
              Icon(
                _getIconForType(),
                size: iconSizeMd,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      relativePath,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTypeLabel(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType() {
    switch (type) {
      case ExtraFileType.subtitle:
        return Icons.subtitles_outlined;
      case ExtraFileType.metadata:
        return Icons.info_outline;
      case ExtraFileType.other:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _getTypeLabel() {
    switch (type) {
      case ExtraFileType.subtitle:
        return 'Subtitle';
      case ExtraFileType.metadata:
        return 'Metadata';
      case ExtraFileType.other:
        return 'Other';
    }
  }
}
