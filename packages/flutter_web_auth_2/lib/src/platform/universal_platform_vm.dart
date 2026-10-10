// Adapted from https://gist.github.com/rydmike/1771fe24c050ebfe792fa309371154d8

import 'dart:io';

// NOTE:
// Never import this library directly in the application. The PlatformIs
// class and library uses conditional imports to only import this file on
// VM platform builds.

/// UniversalPlatform for Flutter VM builds.
///
/// We are using Dart VM builds, so we use dart:io Platform to
/// get the current platform.
class UniversalPlatform {
  UniversalPlatform._();

  /// Is Web?
  static bool get web => false;

  /// Is macOS?
  static bool get macOS => Platform.isMacOS;

  /// Is Windows?
  static bool get windows => Platform.isWindows;

  /// Is Linux?
  static bool get linux => Platform.isLinux;

  /// Is Android?
  static bool get android => Platform.isAndroid;

  /// Is iOS?
  static bool get iOS => Platform.isIOS;

  /// Is Fuchsia?
  static bool get fuchsia => Platform.isFuchsia;
}
