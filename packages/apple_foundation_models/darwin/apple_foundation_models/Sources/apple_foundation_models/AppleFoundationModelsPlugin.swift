import Foundation

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

/// Exposes the Apple Intelligence system language model to Dart.
public final class AppleFoundationModelsPlugin: NSObject, FlutterPlugin {
  /// Registers the `apple_foundation_models` method channel with Flutter.
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let messenger = registrar.messenger()
    #else
    let messenger = registrar.messenger
    #endif
    let channel = FlutterMethodChannel(
      name: "apple_foundation_models",
      binaryMessenger: messenger
    )
    registrar.addMethodCallDelegate(AppleFoundationModelsPlugin(), channel: channel)
  }

  /// Dispatches `availability` and `respond` calls coming from Dart.
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "availability":
      result(FoundationModelsBridge.availability())
    case "respond":
      respond(arguments: call.arguments, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Validates the `respond` arguments and answers asynchronously, reporting
  /// failures as `FlutterError`s whose codes the Dart side maps to errors.
  private func respond(arguments: Any?, result: @escaping FlutterResult) {
    guard
      let arguments = arguments as? [String: Any],
      let instructions = arguments["instructions"] as? String,
      let prompt = arguments["prompt"] as? String
    else {
      result(
        FlutterError(
          code: "invalid_arguments",
          message: "Both instructions and prompt are required.",
          details: nil
        )
      )
      return
    }
    let temperature = arguments["temperature"] as? Double
    let maximumResponseTokens = arguments["maximumResponseTokens"] as? Int

    Task { @MainActor in
      do {
        let content = try await FoundationModelsBridge.respond(
          instructions: instructions,
          prompt: prompt,
          temperature: temperature,
          maximumResponseTokens: maximumResponseTokens
        )
        result(content)
      } catch let error as FoundationModelsBridgeError {
        result(FlutterError(code: error.code, message: error.message, details: nil))
      } catch {
        result(
          FlutterError(
            code: "generation_failed",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }
}
