import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private static let frameDefaultsKey = "mainwindow_frame"
  private static let minimumSaneFrameWidth = 400.0
  private var observerTokens: [NSObjectProtocol] = []

  override func awakeFromNib() {
    do {
      try LegacyPreferencesMigration.migrate(
        home: FileManager.default.homeDirectoryForCurrentUser,
        bundleIdentifier: Bundle.main.bundleIdentifier!,
        defaults: UserDefaults.standard
      )
    } catch {
      let alert = NSAlert()
      alert.messageText = "Não foi possível importar as configurações anteriores"
      alert.informativeText = "Permita o acesso aos dados da instalação anterior e abra o Arrmate novamente. Os dados originais foram preservados."
      alert.runModal()
      exit(EXIT_FAILURE)
    }
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    self.isRestorable = false
    self.restorePersistedFrame()
    self.observeFrameChanges()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  deinit {
    for token in observerTokens {
      NotificationCenter.default.removeObserver(token)
    }
  }

  /// Reapplies the window frame persisted by a previous session, falling back
  /// to a centered default on the first launch. The FlutterViewController
  /// assignment above collapses the window on macOS 26+ (the engine view
  /// starts 1x32), so the frame is always set explicitly here.
  private func restorePersistedFrame() {
    let defaults = UserDefaults.standard
    if let saved = defaults.string(forKey: Self.frameDefaultsKey),
       let frame = Self.parseFrame(saved),
       frame.width >= Self.minimumSaneFrameWidth {
      self.setFrame(frame, display: true)
    } else {
      self.setContentSize(NSSize(width: 1100, height: 720))
      self.center()
    }
  }

  /// Persists the window frame whenever it is meaningfully resized or moved.
  private func observeFrameChanges() {
    let center = NotificationCenter.default
    for name in [
      NSWindow.didEndLiveResizeNotification,
      NSWindow.didMoveNotification,
      NSWindow.didExitFullScreenNotification,
    ] {
      let token = center.addObserver(
        forName: name,
        object: self,
        queue: .main
      ) { [weak self] _ in
        self?.persistFrame()
      }
      observerTokens.append(token)
    }
  }

  /// Saves the current frame, ignoring the collapsed frames the engine view
  /// produces on macOS 26+ so a broken size can never be remembered.
  private func persistFrame() {
    let frame = self.frame
    guard frame.width >= Self.minimumSaneFrameWidth else {
      return
    }
    UserDefaults.standard.set(
      "\(frame.origin.x),\(frame.origin.y),\(frame.width),\(frame.height)",
      forKey: Self.frameDefaultsKey
    )
  }

  /// Parses the "x,y,width,height" frame string written by [persistFrame].
  private static func parseFrame(_ text: String) -> NSRect? {
    let parts = text
      .split(separator: ",")
      .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
    guard parts.count == 4 else {
      return nil
    }
    return NSRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
  }
}
