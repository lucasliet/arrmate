import 'package:flutter/widgets.dart';

import 'window_class.dart';

/// Presentation decisions based on the width available to a content widget.
///
/// Runtime capabilities are deliberately independent of these decisions.
@immutable
class ContentLayout {
  /// Creates a layout for [width] logical pixels of available content space.
  const ContentLayout(this.width);

  /// Available width after navigation, content bounds, and local padding.
  final double width;

  /// Minimum content width for the library toolbar and larger detail heroes.
  static const wideToolbarMinWidth = 1200.0;

  /// Maximum width of the main application content.
  static const maximumContentWidth = 1600.0;

  /// Maximum readable width of activity pages.
  static const maximumActivityWidth = 1100.0;

  /// Maximum readable width of an assistant conversation and its controls.
  static const maximumAssistantWidth = 900.0;

  /// Maximum width of an individual assistant message.
  static const maximumMessageWidth = 640.0;

  /// Maximum width of modal sheets, retaining full width on smaller windows.
  static const maximumSheetWidth = 720.0;

  /// Maximum readable width of standard dialogs.
  static const maximumDialogWidth = 560.0;

  /// Returns the nearest layout measured by [AdaptiveLayout].
  static ContentLayout of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_LayoutScope>();
    assert(
      scope != null,
      'ContentLayout.of requires an AdaptiveLayout parent.',
    );
    return scope!.layout;
  }

  /// Window category for this widget's available width.
  WindowClass get windowClass => WindowClass.fromWidth(width);

  /// Whether settings, calendar, and activity use their wide presentation.
  bool get hasWideSections => width >= WindowClass.expandedMinWidth;

  /// Whether library toolbars and media detail heroes use the wide layout.
  bool get hasWideToolbar => width >= wideToolbarMinWidth;

  /// Whether a poster card has enough local space for larger typography.
  bool get hasLargePoster => width >= 180;

  /// Number of metadata columns that fit within the local padded content.
  int get infoColumnCount => hasWideSections ? 3 : (width >= 320 ? 2 : 1);
}

/// Measures parent constraints and shares presentation width with descendants.
///
/// The widget tree stays stable while the window is resized, and the layout
/// never changes platform capability or service selection.
class AdaptiveLayout extends StatelessWidget {
  /// Creates a measured layout whose [builder] runs inside the layout scope.
  const AdaptiveLayout({super.key, required this.builder});

  /// Builds content that can read its measured width with [ContentLayout.of].
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _LayoutScope(
        layout: ContentLayout(constraints.maxWidth),
        child: Builder(builder: builder),
      ),
    );
  }
}

class _LayoutScope extends InheritedWidget {
  const _LayoutScope({required this.layout, required super.child});

  final ContentLayout layout;

  @override
  bool updateShouldNotify(_LayoutScope oldWidget) =>
      layout.width != oldWidget.layout.width;
}
