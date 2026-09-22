import 'package:flutter/material.dart';

/// Centers content and prevents desktop pages from becoming excessively wide.
class ContentConstraint extends StatelessWidget {
  /// Creates a constrained content region.
  const ContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = 1440,
    this.padding = const EdgeInsets.all(16),
  });

  /// Content displayed inside the constraint.
  final Widget child;

  /// Maximum width of the content region.
  final double maxWidth;

  /// Padding within the content region.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(padding: padding, child: child),
    ),
  );
}
