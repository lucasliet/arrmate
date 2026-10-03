import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
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
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
