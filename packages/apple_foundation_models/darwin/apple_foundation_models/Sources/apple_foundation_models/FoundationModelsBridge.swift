import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Generation failure with a stable code shared with the Dart side.
struct FoundationModelsBridgeError: Error {
  let code: String
  let message: String
}

/// Flutter-independent access to the Apple Intelligence system language model.
///
/// Builds made with an SDK that lacks the framework, and devices running an
/// older OS, report the model as unavailable instead of failing to load.
enum FoundationModelsBridge {
  /// Returns the model availability as the Dart enum name.
  static func availability() -> String {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, macOS 26.0, *) {
      return SystemModel.availability()
    }
    return "unsupportedOsVersion"
    #else
    return "unavailable"
    #endif
  }

  /// Answers `prompt` in a fresh session that follows `instructions`.
  static func respond(
    instructions: String,
    prompt: String,
    temperature: Double?,
    maximumResponseTokens: Int?
  ) async throws -> String {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, macOS 26.0, *) {
      return try await SystemModel.respond(
        instructions: instructions,
        prompt: prompt,
        temperature: temperature,
        maximumResponseTokens: maximumResponseTokens
      )
    }
    #endif
    throw FoundationModelsBridgeError(
      code: "unavailable",
      message: "Apple Intelligence requires iOS 26 or macOS 26."
    )
  }
}

#if canImport(FoundationModels)
/// Calls into the Foundation Models framework once the OS is known to have it.
@available(iOS 26.0, macOS 26.0, *)
private enum SystemModel {
  /// Maps the system model availability to the Dart enum name.
  static func availability() -> String {
    switch SystemLanguageModel.default.availability {
    case .available:
      return "available"
    case .unavailable(.deviceNotEligible):
      return "deviceNotEligible"
    case .unavailable(.appleIntelligenceNotEnabled):
      return "appleIntelligenceNotEnabled"
    case .unavailable(.modelNotReady):
      return "modelNotReady"
    default:
      return "unavailable"
    }
  }

  /// Answers `prompt` in a new session, rethrowing failures as
  /// `FoundationModelsBridgeError`s with a stable code.
  static func respond(
    instructions: String,
    prompt: String,
    temperature: Double?,
    maximumResponseTokens: Int?
  ) async throws -> String {
    let session = LanguageModelSession(instructions: instructions)
    let options = GenerationOptions(
      temperature: temperature,
      maximumResponseTokens: maximumResponseTokens
    )
    do {
      let response = try await session.respond(to: prompt, options: options)
      return response.content
    } catch {
      throw FoundationModelsBridgeError(
        code: errorCode(for: error),
        message: error.localizedDescription
      )
    }
  }

  /// Returns the stable code shared with Dart for a generation failure.
  private static func errorCode(for error: Error) -> String {
    if let generationError = error as? LanguageModelSession.GenerationError {
      switch generationError {
      case .exceededContextWindowSize:
        return "context_window_exceeded"
      case .guardrailViolation:
        return "guardrail_violation"
      case .unsupportedLanguageOrLocale:
        return "unsupported_language"
      case .assetsUnavailable:
        return "assets_unavailable"
      case .rateLimited:
        return "rate_limited"
      case .concurrentRequests:
        return "busy"
      case .refusal:
        return "refusal"
      default:
        return "generation_failed"
      }
    }

    // Newer SDKs report failures through other error types; match their case
    // names so the Dart side keeps recovering from context overflows.
    let caseName = Mirror(reflecting: error).children.first?.label
      ?? String(describing: error)
    switch caseName {
    case "contextSizeExceeded", "exceededContextWindowSize":
      return "context_window_exceeded"
    case "guardrailViolation":
      return "guardrail_violation"
    case "unsupportedLanguageOrLocale":
      return "unsupported_language"
    case "assetsUnavailable":
      return "assets_unavailable"
    case "rateLimited":
      return "rate_limited"
    case "concurrentRequests":
      return "busy"
    case "refusal":
      return "refusal"
    default:
      return "generation_failed"
    }
  }
}
#endif
