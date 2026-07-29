import 'package:flutter/material.dart';

import '../../../core/utils/media_external_links.dart';

/// Displays automatic search and external media links in a compact menu.
class MediaQuickActionsMenu extends StatelessWidget {
  /// External destinations available for the media item.
  final List<MediaExternalLink> links;

  /// Runs an automatic search for the media item.
  final Future<void> Function() onAutomaticSearch;

  /// Opens a selected external destination.
  final Future<void> Function(Uri uri) onOpenExternal;

  /// Color used by the menu icon.
  final Color? iconColor;

  const MediaQuickActionsMenu({
    super.key,
    required this.links,
    required this.onAutomaticSearch,
    required this.onOpenExternal,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Quick actions',
      icon: Icon(Icons.more_vert, color: iconColor),
      onSelected: (value) async {
        if (value == _automaticSearchValue) {
          await onAutomaticSearch();
          return;
        }
        final link = links.firstWhere((link) => link.label == value);
        await onOpenExternal(link.uri);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _automaticSearchValue,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.travel_explore),
            title: Text('Automatic Search'),
          ),
        ),
        const PopupMenuDivider(),
        for (final link in links)
          PopupMenuItem(
            value: link.label,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.open_in_new),
              title: Text('Open in ${link.label}'),
            ),
          ),
      ],
    );
  }

  static const _automaticSearchValue = '__automatic_search__';
}
