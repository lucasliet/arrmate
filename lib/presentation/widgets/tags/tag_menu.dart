import 'package:flutter/material.dart';

import '../../../domain/models/models.dart';

/// A dropdown menu for selecting tags.
class TagMenu extends StatelessWidget {
  final List<Tag> tags;
  final Set<int> selectedTagIds;
  final ValueChanged<Set<int>> onSelectionChanged;
  final String buttonLabel;

  const TagMenu({
    super.key,
    required this.tags,
    required this.selectedTagIds,
    required this.onSelectionChanged,
    this.buttonLabel = 'Select Tags',
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return OutlinedButton.icon(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.label_outline),
          label: Text(
            selectedTagIds.isEmpty
                ? buttonLabel
                : '$buttonLabel (${selectedTagIds.length})',
          ),
        );
      },
      menuChildren: [
        if (tags.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No tags available'),
          )
        else
          ...tags.map((tag) {
            final isSelected = selectedTagIds.contains(tag.id);
            return CheckboxMenuButton(
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
              child: Text(tag.label),
            );
          }),
      ],
    );
  }
}
