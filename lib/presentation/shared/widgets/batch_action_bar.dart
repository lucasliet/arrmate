import 'package:flutter/material.dart';

/// A bottom action bar shown when items are selected in a list/grid.
///
/// Displays the selection count and a row of [BatchAction] buttons. Typically
/// used for batch Monitor / Unmonitor / Delete operations.
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
            Row(
              children: actions
                  .map(
                    (action) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _buildAction(context, action, theme),
                      ),
                    ),
                  )
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
    if (action.submenu != null && action.submenu!.isNotEmpty) {
      return _buildSubmenuAction(context, action, theme);
    }
    final isDestructive = action.isDestructive;
    return TextButton(
      onPressed: action.onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            action.icon,
            color: isDestructive ? theme.colorScheme.error : null,
          ),
          const SizedBox(height: 4),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDestructive ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmenuAction(
    BuildContext context,
    BatchAction action,
    ThemeData theme,
  ) {
    final isDestructive = action.isDestructive;
    return TextButton(
      onPressed: () => showBatchActionSubmenu(context, action, theme),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            action.icon,
            color: isDestructive ? theme.colorScheme.error : null,
          ),
          const SizedBox(height: 4),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDestructive ? theme.colorScheme.error : null,
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            Icons.arrow_drop_down,
            color: isDestructive
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Shows a modal bottom sheet listing the submenu options of [parent].
///
/// Tapping an item invokes its [BatchAction.onPressed] callback and dismisses
/// the sheet.
Future<void> showBatchActionSubmenu(
  BuildContext context,
  BatchAction parent,
  ThemeData theme,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                parent.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final sub in parent.submenu!)
              ListTile(
                leading: Icon(
                  sub.icon,
                  color: sub.isDestructive ? theme.colorScheme.error : null,
                ),
                title: Text(
                  sub.label,
                  style: sub.isDestructive
                      ? TextStyle(color: theme.colorScheme.error)
                      : null,
                ),
                onTap: sub.onPressed == null
                    ? null
                    : () {
                        Navigator.of(sheetContext).pop();
                        sub.onPressed!();
                      },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// Describes a single action button in a [BatchActionBar].
///
/// When [submenu] is non-null and non-empty, tapping the button opens a modal
/// bottom sheet listing those options; in that case [onPressed] may be null.
class BatchAction {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final List<BatchAction>? submenu;

  const BatchAction({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isDestructive = false,
    this.submenu,
  });
}
