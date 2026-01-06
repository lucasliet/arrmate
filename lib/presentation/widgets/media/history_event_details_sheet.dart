import 'package:flutter/material.dart';
import 'package:arrmate/core/constants/app_constants.dart';
import 'package:arrmate/core/utils/formatters.dart';
import 'package:arrmate/domain/models/models.dart';

/// A modal sheet displaying detailed information about a history event.
class HistoryEventDetailsSheet extends StatelessWidget {
  final HistoryEvent event;

  const HistoryEventDetailsSheet({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(102),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Event Details',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(paddingMd),
                children: [
                  _buildEventHeader(context),
                  const SizedBox(height: 16),
                  _buildSection(context, 'General', [
                    _buildInfoRow(context, 'Event Type', _getEventTypeLabel()),
                    _buildInfoRow(context, 'Date', formatDate(event.date)),
                    if (event.sourceTitle != null)
                      _buildInfoRow(
                        context,
                        'Source Title',
                        event.sourceTitle!,
                      ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection(context, 'Quality', [
                    _buildInfoRow(
                      context,
                      'Quality',
                      event.quality.quality.name,
                    ),
                    if (event.quality.quality.source != null)
                      _buildInfoRow(
                        context,
                        'Source',
                        event.quality.quality.source!,
                      ),
                    if (event.quality.quality.resolution != null)
                      _buildInfoRow(
                        context,
                        'Resolution',
                        '${event.quality.quality.resolution}p',
                      ),
                  ]),
                  if (event.languages != null &&
                      event.languages!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      'Languages',
                      event.languages!
                          .map(
                            (lang) => _buildInfoRow(
                              context,
                              'Language',
                              lang.name ?? 'Unknown',
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (event.data != null && event.data!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDataSection(context),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventHeader(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = _getEventIconAndColor(theme);

    return Container(
      padding: const EdgeInsets.all(paddingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            child: Icon(icon, size: iconSizeLg, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getEventTypeLabel(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDate(event.date),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildDataSection(BuildContext context) {
    final dataRows = event.data!.entries.map((entry) {
      return _buildInfoRow(context, entry.key, entry.value?.toString() ?? '');
    }).toList();

    return _buildSection(context, 'Additional Data', dataRows);
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  (IconData, Color) _getEventIconAndColor(ThemeData theme) {
    switch (event.eventType) {
      case HistoryEventType.grabbed:
        return (Icons.download_outlined, Colors.blue);
      case HistoryEventType.imported:
        return (Icons.check_circle_outline, Colors.green);
      case HistoryEventType.failed:
        return (Icons.error_outline, theme.colorScheme.error);
      case HistoryEventType.deleted:
        return (Icons.delete_outline, Colors.orange);
      case HistoryEventType.renamed:
        return (Icons.drive_file_rename_outline, Colors.purple);
      case HistoryEventType.ignored:
        return (Icons.block_outlined, Colors.grey);
      case HistoryEventType.unknown:
        return (Icons.help_outline, theme.colorScheme.onSurfaceVariant);
    }
  }

  String _getEventTypeLabel() {
    return event.eventType.title;
  }
}
