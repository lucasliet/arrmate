# flutter_web_auth_2 (vendored)

Copy of [`flutter_web_auth_2`](https://pub.dev/packages/flutter_web_auth_2)
5.1.0 (MIT, see `LICENSE`) used by the Google sign-in on iOS and Android.

The only change is that the Linux and Windows implementation was removed, along
with its `desktop_webview_window` and `window_to_front` dependencies. Those
register native plugins that make `flutter build linux` require WebKitGTK and
libsoup, and the app never calls this plugin on desktop (it opens the system
browser there). The Android, iOS, macOS and web code is untouched.
