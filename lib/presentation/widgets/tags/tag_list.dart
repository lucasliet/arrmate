import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../domain/models/models.dart';

/// A list widget for displaying and selecting tags.
class TagList extends StatelessWidget {
  final List<Tag> tags;
  final Set<int> selectedTagIds;
  final ValueChanged<Set<int>> onSelectionChanged;

  const TagList({
    super.key,
    required this.tags,
    required this.selectedTagIds,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.l10n.widgetsNoTagsAvailable),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final isSelected = selectedTagIds.contains(tag.id);

        return CheckboxListTile(
          title: Text(tag.label),
          value: isSelected,
          onChanged: (value) {
            final newSelection = Set<int>.from(selectedTagIds);
            if (value == true) {
              newSelection.add(tag.id);
            } else {
              newSelection.remove(tag.id);
            }
            onSelectionChanged(newSelection);
          },
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }
}
