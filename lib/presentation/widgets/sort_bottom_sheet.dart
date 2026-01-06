import 'package:flutter/material.dart';

/// A customizable bottom sheet for sorting and filtering lists.
class SortBottomSheet<T extends Enum, F extends Enum> extends StatelessWidget {
  /// The title of the sheet.
  final String title;

  /// The current sort option.
  final T currentSort;

  /// Whether the sort is ascending.
  final bool isAscending;

  /// The current filter option.
  final F currentFilter;

  /// List of available sort options.
  final List<T> sortOptions;

  /// List of available filter options.
  final List<F> filterOptions;

  /// Builder for sort option labels.
  final String Function(T) sortLabelBuilder;

  /// Builder for filter option labels.
  final String Function(F) filterLabelBuilder;

  /// Callback when sort option changes.
  final Function(T) onSortChanged;

  /// Callback when sort order changes.
  final Function(bool) onAscendingChanged;

  /// Callback when filter option changes.
  final Function(F) onFilterChanged;

  const SortBottomSheet({
    super.key,
    required this.title,
    required this.currentSort,
    required this.isAscending,
    required this.currentFilter,
    required this.sortOptions,
    required this.filterOptions,
    required this.sortLabelBuilder,
    required this.filterLabelBuilder,
    required this.onSortChanged,
    required this.onAscendingChanged,
    required this.onFilterChanged,
  });

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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
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
              child: Text(title, style: theme.textTheme.titleLarge),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _buildSectionHeader(context, 'Sort By'),
                  RadioGroup<T>(
                    groupValue: currentSort,
                    onChanged: (value) {
                      if (value != null) {
                        onSortChanged(value);
                        Navigator.pop(context);
                      }
                    },
                    child: Column(
                      children: sortOptions
                          .map(
                            (option) => RadioListTile<T>(
                              title: Text(sortLabelBuilder(option)),
                              value: option,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const Divider(),
                  _buildSectionHeader(context, 'Order'),
                  RadioGroup<bool>(
                    groupValue: isAscending,
                    onChanged: (value) {
                      if (value != null) {
                        onAscendingChanged(value);
                        Navigator.pop(context);
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          title: const Text('Ascending'),
                          value: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                        ),
                        RadioListTile<bool>(
                          title: const Text('Descending'),
                          value: false,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  _buildSectionHeader(context, 'Filter'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: filterOptions.map((filter) {
                        final isSelected = filter == currentFilter;
                        return FilterChip(
                          label: Text(filterLabelBuilder(filter)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              onFilterChanged(filter);
                              Navigator.pop(context);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
