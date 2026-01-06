import 'package:flutter/material.dart';

/// Convenience extensions for [BuildContext] to access Theme, MediaQuery, and common UI actions.
extension ContextExtensions on BuildContext {
  /// Returns the [ThemeData] from the current context.
  ThemeData get theme => Theme.of(this);

  /// Returns the [ColorScheme] from the current theme.
  ColorScheme get colorScheme => theme.colorScheme;

  /// Returns the [TextTheme] from the current theme.
  TextTheme get textTheme => theme.textTheme;

  /// Returns the [MediaQueryData] from the current context.
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Returns the screen [Size] from MediaQuery.
  Size get screenSize => mediaQuery.size;

  /// Returns the screen width.
  double get screenWidth => screenSize.width;

  /// Returns the screen height.
  double get screenHeight => screenSize.height;

  /// Returns the padding from MediaQuery (e.g., safe area insets).
  EdgeInsets get padding => mediaQuery.padding;

  /// Returns `true` if the current theme brightness is [Brightness.dark].
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Returns `true` if the screen width is greater than 600 logical pixels.
  bool get isLargeScreen => screenWidth > 600;

  /// Returns `true` if the screen width is greater than 900 logical pixels.
  bool get isExtraLargeScreen => screenWidth > 900;

  /// Shows a [SnackBar] with the given [message].
  ///
  /// [isError] - If true, displays the snackbar with the error color from the color scheme.
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Convenience method to show an error [SnackBar].
  void showErrorSnackBar(String message) =>
      showSnackBar(message, isError: true);

  /// Shows a modal bottom sheet containing the provided [child] widget.
  ///
  /// The sheet is scroll-controlled and respects the safe area.
  Future<T?> showBottomSheet<T>(Widget child) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => child,
    );
  }
}
