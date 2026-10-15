import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../domain/models/models.dart';

/// A dropdown menu for selecting tags.
class TagMenu extends StatelessWidget {
  final List<Tag> tags;
  final Set<int> selectedTagIds;
  final ValueChanged<Set<int>> onSelectionChanged;

  /// Label of the menu button; defaults to the translated "Select Tags".
  final String? buttonLabel;

  const TagMenu({
    super.key,
    required this.tags,
    required this.selectedTagIds,
    required this.onSelectionChanged,
    this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final buttonLabel = this.buttonLabel ?? context.l10n.widgetsSelectTags;
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
                : context.l10n.widgetsTagButtonWithCount(
                    buttonLabel,
                    selectedTagIds.length,
                  ),
          ),
        );
      },
      menuChildren: [
        if (tags.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(context.l10n.widgetsNoTagsAvailable),
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
