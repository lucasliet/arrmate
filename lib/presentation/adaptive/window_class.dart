/// Responsive window categories selected from available content width.
enum WindowClass {
  /// A single-pane phone layout below 600 logical pixels.
  compact,

  /// A rail-based layout from 600 through 899 logical pixels.
  medium,

  /// A labeled-rail layout from 900 through 1439 logical pixels.
  expanded,

  /// A wide desktop layout at 1440 logical pixels and above.
  large;

  /// Resolves a window class from the width available to the widget.
  static WindowClass fromWidth(double width) {
    if (width < 600) return WindowClass.compact;
    if (width < 900) return WindowClass.medium;
    if (width < 1440) return WindowClass.expanded;
    return WindowClass.large;
  }

  /// Whether this class uses persistent side navigation.
  bool get hasNavigationRail => this != WindowClass.compact;

  /// Whether navigation destinations should display labels.
  bool get hasExtendedNavigation =>
      this == WindowClass.expanded || this == WindowClass.large;
}
