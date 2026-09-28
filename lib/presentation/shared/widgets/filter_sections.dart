import 'package:flutter/material.dart';

/// Renders a single-select section of [ChoiceChip]s for a set of enum values.
class ChoiceSection<T> extends StatelessWidget {
  final String title;
  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  const ChoiceSection({
    super.key,
    required this.title,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: values
                .map(
                  (value) => ChoiceChip(
                    label: Text(labelBuilder(value)),
                    selected: value == selected,
                    onSelected: (_) => onSelected(value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Renders a multi-select section of [FilterChip]s for a set of string values.
class FilterSection extends StatelessWidget {
  final String title;
  final List<String> values;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const FilterSection({
    super.key,
    required this.title,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: values.map((value) {
              return FilterChip(
                label: Text(value),
                selected: selected.contains(value),
                onSelected: (isSelected) {
                  final next = Set<String>.from(selected);
                  isSelected ? next.add(value) : next.remove(value);
                  onChanged(next);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
