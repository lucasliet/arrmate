# Native desktop development

Arrmate includes Flutter runners for Windows, Linux, and macOS, generated
with Flutter 3.41.2, the version pinned in CI. These targets execute the
existing Dart application natively. They do not embed a browser or load the
web build. Desktop packaging, installers, signing, and automatic updates are
separate follow-up work.

## Build and run

Build each target on its own operating system. Install Flutter 3.41.2 and run
these commands from the repository root:

```sh
flutter pub get
dart run flutter_launcher_icons
```

| Host | Run | Release build | Output |
| --- | --- | --- | --- |
| Windows | `flutter run -d windows` | `flutter build windows --release` | `build/windows/x64/runner/Release/` |
| Linux | `flutter run -d linux` | `flutter build linux --release` | `build/linux/x64/release/bundle/` |
| macOS | `flutter run -d macos` | `flutter build macos --release` | `build/macos/Build/Products/Release/Arrmate.app` |

Windows and Linux applications require the entire generated bundle, including
the `data` directory and libraries. Copying only the executable is insufficient.
On ARM hosts, use the output directory for the host architecture.

### Windows

Install Visual Studio 2022 with **Desktop development with C++**, the Windows
SDK, CMake tools, and the C++ ATL component required by
`flutter_secure_storage`. Visual Studio Code alone does not provide this
toolchain. Verify the setup with `flutter doctor -v`.

### Linux

On Ubuntu or Debian, install the native toolchain and secure-storage headers:

```sh
sudo apt-get update
sudo apt-get install clang lld llvm cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev
```

The LLVM linker and archiver are needed for Flutter's native-assets build
configuration. The runtime requires GTK 3, `libsecret-1-0`, and an active desktop session
providing the Secret Service API, such as GNOME Keyring or a compatible
KWallet setup. This is needed to persist server credentials. The window icon
uses the existing `assets/images/icon.png` from Flutter's resolved bundle
asset directory.

### macOS

Install Xcode and its command-line tools and CocoaPods. The application ID is
`br.com.lucasliet.arrmate`, matching the mobile targets. The runner includes:

- Network client entitlements in Debug/Profile and Release for service APIs,
  images, ntfy, and the online assistant.
- User-selected file read access for importing torrent files.
- Keychain access groups required by `flutter_secure_storage`.
- HTTP transport support for user-configured self-hosted servers, matching
  the existing iOS configuration, and a local-network usage description.
- Registration of the existing `arrmate://` URL scheme.

Select a development team in Xcode when building with a signing identity.
Public distribution still needs signing and notarization; this change does
not create a distribution configuration or publish an installer.

## Runtime capabilities

Layout decisions and runtime capabilities remain separate. Native desktop
uses the existing IO services, file-system cache, preferences, secure storage,
file selection, and online assistant. CORS, mixed-content rules, and browser
file-input workarounds apply only to the web runtime.

The online assistant remains available on desktop, including models filtered
only for browser CORS. Provider authentication, availability, and free-tier
policies still apply; removing browser restrictions does not fix provider
rejections described in [Web deployment](web-deployment.md).

On-device LiteRT-LM inference is currently Android-only because the vendored
plugin implements only Android. Desktop must retain the online assistant
without offering unsupported local inference. The Android APK updater also
remains Android-only. In-app notifications and ntfy operate while the process
is running; closed-app background delivery is not added by generating runners.

The macOS URL scheme is registered. Windows protocol registration and Linux
desktop-file/URI activation still require platform packaging integration.

## Verification

`build-desktop.yml` builds all three release targets on their respective
GitHub Actions hosts for pull requests, pushes to `main`, and manual runs.
The existing test workflow continues to analyze Dart and run the test suite.
These builds verify compilation; they do not establish interactive runtime
parity or publish packages.

Before declaring a desktop target ready for distribution, check startup,
persisted credentials after a restart, an HTTP LAN server connection,
image caching, torrent-file selection, notification streaming, sharing,
and an assistant request on that operating system.

The shared responsive presentation is documented in
[Desktop and tablet layout](desktop-tablet-layout.md).
