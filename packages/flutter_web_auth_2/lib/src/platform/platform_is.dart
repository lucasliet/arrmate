// Adapted from https://gist.github.com/rydmike/1771fe24c050ebfe792fa309371154d8

import 'package:flutter_web_auth_2/src/platform/universal_platform_none.dart'
    if (dart.library.io) 'package:flutter_web_auth_2/src/platform/universal_platform_vm.dart'
    if (dart.library.js_interop) 'package:flutter_web_auth_2/src/platform/universal_platform_web.dart';

/// A universal platform checker.
///
/// Can be used to check active physical Flutter platform on all platforms.
///
/// To check what host platform the app is running on use:
///
/// * PlatformIs.android
/// * PlatformIs.iOS
/// * PlatformIs.macOS
/// * PlatformIs.windows
/// * PlatformIs.linux
/// * PlatformIs.fuchsia
///
/// To check the device type use:
///
/// * PlatformIs.mobile  (Android or iOS)
/// * PlatformIs.desktop (Windows, macOS or Linux)
///
/// Currently Fuchsia is not considered mobile nor desktop, even if it
/// might be so in the future.
///
/// To check if the Flutter application is running on Web you can use:
///
/// * PlatformIs.web
///
/// Alternatively the Flutter foundation compile time constant kIsWeb also
/// works well for that.
///
/// The platform checks are supported independently on web. You can use
/// PlatformIs windows, iOS, macOS, Android and Linux to check what the host
/// platform is when you are running a Flutter Web application.
///
/// Checking if we are running on a Fuchsia host in a Web browser, is not yet
/// fully supported. If running in a Web browser on Fuchsia, PlatformIs.web
/// will be true, but PlatformIs.fuchsia will be false. Future versions, when
/// Fuchsia is released, may fix this.
class PlatformIs {
  PlatformIs._();

  /// Is Web?
  static bool get web => UniversalPlatform.web;

  /// Is macOS?
  static bool get macOS => UniversalPlatform.macOS;

  /// Is Windows?
  static bool get windows => UniversalPlatform.windows;

  /// Is Linux?
  static bool get linux => UniversalPlatform.linux;

  /// Is Android?
  static bool get android => UniversalPlatform.android;

  /// Is iOS?
  static bool get iOS => UniversalPlatform.iOS;

  /// Is Fuchsia?
  static bool get fuchsia => UniversalPlatform.fuchsia;

  /// Is Mobile?
  static bool get mobile => PlatformIs.iOS || PlatformIs.android;

  /// Is Desktop?
  static bool get desktop =>
      PlatformIs.macOS || PlatformIs.windows || PlatformIs.linux;
}
