import 'package:flutter/material.dart';
import 'package:arrmate/core/constants/app_constants.dart';
import 'package:arrmate/core/utils/formatters.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:timeago/timeago.dart' as timeago;

class HistoryEventCard extends StatelessWidget {
  final HistoryEvent event;
  final VoidCallback? onTap;

  const HistoryEventCard({super.key, required this.event, this.onTap});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventIcon(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildEventTypeBadge(context),
                        const Spacer(),
                        Text(
                          timeago.format(event.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.sourceTitle ?? 'Unknown',
                      style: theme.textTheme.bodyMedium,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventIcon(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = _getEventIconAndColor(theme);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: iconSizeMd, color: color),
    );
  }

  (IconData, Color) _getEventIconAndColor(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    switch (event.eventType) {
      case HistoryEventType.grabbed:
        return (Icons.download_outlined, colorScheme.primary);
      case HistoryEventType.imported:
        return (Icons.check_circle_outline, colorScheme.tertiary);
      case HistoryEventType.failed:
        return (Icons.error_outline, colorScheme.error);
      case HistoryEventType.deleted:
        return (Icons.delete_outline, colorScheme.secondary);
      case HistoryEventType.renamed:
        return (Icons.drive_file_rename_outline, colorScheme.inversePrimary);
      case HistoryEventType.ignored:
        return (Icons.block_outlined, colorScheme.outline);
      case HistoryEventType.unknown:
        return (Icons.help_outline, colorScheme.onSurfaceVariant);
    }
  }

  Widget _buildEventTypeBadge(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getEventIconAndColor(theme).$2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getEventTypeLabel(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getEventTypeLabel() {
    switch (event.eventType) {
      case HistoryEventType.grabbed:
        return 'GRABBED';
      case HistoryEventType.imported:
        return 'IMPORTED';
      case HistoryEventType.failed:
        return 'FAILED';
      case HistoryEventType.deleted:
        return 'DELETED';
      case HistoryEventType.renamed:
        return 'RENAMED';
      case HistoryEventType.ignored:
        return 'IGNORED';
      case HistoryEventType.unknown:
        return 'UNKNOWN';
    }
  }

  String _buildSubtitle() {
    final parts = <String>[];

    parts.add(event.quality.quality.name);

    if (event.languages case final languages? when languages.isNotEmpty) {
      final langName = languages.first.name;
      if (langName != null && langName.isNotEmpty) {
        parts.add(langName);
      }
    }

    return formatListWithSeparator(parts);
  }
}
