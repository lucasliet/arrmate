import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Scroll behavior that lets a mouse drag lists the way a finger does.
///
/// [MaterialScrollBehavior] already drags from touch, stylus, and trackpad.
/// A plain mouse is left out, so pull-to-refresh on desktop never starts:
/// the pointer drags the window instead of the list.
class AppScrollBehavior extends MaterialScrollBehavior {
  /// Creates the app scroll behavior.
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.mouse,
    PointerDeviceKind.unknown,
  };
}
