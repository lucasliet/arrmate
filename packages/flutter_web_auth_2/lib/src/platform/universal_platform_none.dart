// Adapted from https://gist.github.com/rydmike/1771fe24c050ebfe792fa309371154d8

// NOTE:
// Never import this library directly in the application. The PlatformIs
// class and library uses conditional imports to only import this file on
// VM platform builds.

/// UniversalPlatform for just a "none" implementation when the platform
/// cannot be identified for some reason.
class UniversalPlatform {
  UniversalPlatform._();

  /// Is Web?
  static bool get web => false;

  /// Is macOS?
  static bool get macOS => false;

  /// Is Windows?
  static bool get windows => false;

  /// Is Linux?
  static bool get linux => false;

  /// Is Android?
  static bool get android => false;

  /// Is iOS?
  static bool get iOS => false;

  /// Is Fuchsia?
  static bool get fuchsia => false;
}
