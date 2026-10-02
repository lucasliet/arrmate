# Native desktop development

Arrmate includes Flutter runners for Windows, Linux, and macOS, generated
with Flutter 3.41.2, the version pinned in CI. These targets execute the
existing Dart application natively. They do not embed a browser or load the
web build. Tagged releases package the complete desktop bundles alongside
Android and iOS. Installers, signing, and automatic desktop updates remain
separate work.

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

Install Xcode 26.1.1 or newer, its command-line tools, and CocoaPods. The
current `connectivity_plus` plugin requires this SDK to compile its guarded
satellite-network API. CI uses `macos-15` with the latest stable installed
Xcode. The application ID is `br.com.lucasliet.arrmate`, matching the mobile
targets. The runner includes:

- Network client entitlements in Debug/Profile and Release for service APIs,
  images, ntfy, and the online assistant.
- User-selected file read access for importing torrent files.
- Keychain access groups required by `flutter_secure_storage`.
- HTTP transport support for user-configured self-hosted servers, matching
  the existing iOS configuration, and a local-network usage description.
- Registration of the existing `arrmate://` URL scheme.

Select a development team in Xcode when building with a signing identity.
The release archive contains the application bundle. Signing, notarization,
and a disk-image installer are not configured.

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

`build-desktop.yml` builds all three desktop targets on their respective
GitHub Actions hosts for pull requests, pushes to `main`, and manual runs.
The existing test workflow continues to analyze Dart and run the test suite.
These checks verify compilation and do not establish interactive runtime
parity.

## Release packaging

`release.yml` publishes versions when a `v*` tag is pushed. After resolving the
tag to an immutable source revision, it calls the reusable `build.yml`
workflow while release notes are generated independently. That build workflow
runs Android, iOS, and the desktop matrix in parallel; the matrix reuses
`build-desktop.yml`. A single publication job waits for every build, downloads
their artifacts, creates the AltStore source, and publishes the complete
release together.

| Platform | Release asset |
| --- | --- |
| Android | `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk` |
| iOS | `arrmate.ipa`, `altstore.json` |
| Windows x64 | `arrmate-windows-x64.zip` |
| Linux x64 | `arrmate-linux-x64.tar.gz` |
| macOS | `arrmate-macos.zip` |

Desktop archives include Flutter assets and libraries. Extract the complete
archive before launching the executable or app bundle. Linux still requires
the runtime libraries and Secret Service session described above.

To rebuild an existing version after changing the release workflow, run the
**Release** workflow manually from `main` and supply its existing tag in the
`tag` input. The workflow builds that tag's source and updates its release;
it does not release the current `main` application code.

Before declaring a desktop target ready for distribution, check startup,
persisted credentials after a restart, an HTTP LAN server connection,
image caching, torrent-file selection, notification streaming, sharing,
and an assistant request on that operating system.

The shared responsive presentation is documented in
[Desktop and tablet layout](desktop-tablet-layout.md).
