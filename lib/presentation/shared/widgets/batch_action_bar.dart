import 'package:flutter/material.dart';

/// A bottom action bar shown when items are selected in a list/grid.
///
/// Displays the selection count and a row of [BatchAction] buttons. Typically
/// used for batch Delete / Delete files / Purge operations.
class BatchActionBar extends StatelessWidget {
  final int selectedCount;
  final List<BatchAction> actions;

  const BatchActionBar({
    super.key,
    required this.selectedCount,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '$selectedCount selected',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            OverflowBar(
              spacing: 4,
              overflowSpacing: 4,
              overflowAlignment: OverflowBarAlignment.center,
              alignment: MainAxisAlignment.spaceEvenly,
              children: actions
                  .map((action) => _buildAction(context, action, theme))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    BatchAction action,
    ThemeData theme,
  ) {
    final isDestructive = action.isDestructive;
    return TextButton.icon(
      onPressed: action.onPressed,
      icon: Icon(
        action.icon,
        color: isDestructive ? theme.colorScheme.error : null,
      ),
      label: Text(
        action.label,
        style: isDestructive ? TextStyle(color: theme.colorScheme.error) : null,
      ),
    );
  }
}

/// Describes a single action button in a [BatchActionBar].
class BatchAction {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;

  const BatchAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });
}
