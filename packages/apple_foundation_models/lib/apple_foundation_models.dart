import 'package:flutter/services.dart';

/// Availability of the Apple Intelligence system language model.
enum AppleFoundationModelsAvailability {
  /// The model is ready to generate responses.
  available,

  /// The device hardware does not support Apple Intelligence.
  deviceNotEligible,

  /// Apple Intelligence is supported but turned off in system settings.
  appleIntelligenceNotEnabled,

  /// The model assets are still downloading or otherwise not ready.
  modelNotReady,

  /// The operating system predates the Foundation Models framework.
  unsupportedOsVersion,

  /// The model is unavailable for another reason, including platforms
  /// without the framework.
  unavailable;

  /// Parses the availability reported by the native plugin.
  static AppleFoundationModelsAvailability fromWire(String? value) {
    return AppleFoundationModelsAvailability.values.firstWhere(
      (availability) => availability.name == value,
      orElse: () => AppleFoundationModelsAvailability.unavailable,
    );
  }
}

/// Failure categories reported by the native generation call.
enum AppleFoundationModelsError {
  /// Instructions, prompt and response exceeded the model context window.
  contextWindowExceeded('context_window_exceeded'),

  /// The system safety guardrails blocked the prompt or the response.
  guardrailViolation('guardrail_violation'),

  /// The model does not support the requested language or locale.
  unsupportedLanguage('unsupported_language'),

  /// The model assets required by the session are unavailable.
  assetsUnavailable('assets_unavailable'),

  /// The system rate limited the request.
  rateLimited('rate_limited'),

  /// The model was still answering a previous request.
  busy('busy'),

  /// The model refused to answer.
  refusal('refusal'),

  /// The framework is not available on this device or build.
  unavailable('unavailable'),

  /// The native call received malformed arguments.
  invalidArguments('invalid_arguments'),

  /// The generation failed for an unclassified reason.
  generationFailed('generation_failed');

  const AppleFoundationModelsError(this.code);

  /// Stable code exchanged with the native plugin.
  final String code;

  /// Parses an error code reported by the native plugin.
  static AppleFoundationModelsError fromCode(String code) {
    return AppleFoundationModelsError.values.firstWhere(
      (error) => error.code == code,
      orElse: () => AppleFoundationModelsError.generationFailed,
    );
  }
}

/// Error thrown when the system language model fails to respond.
class AppleFoundationModelsException implements Exception {
  /// Creates an exception for [error] with an optional native [message].
  const AppleFoundationModelsException(this.error, [this.message]);

  /// Failure category.
  final AppleFoundationModelsError error;

  /// Developer-facing description reported by the framework, if any.
  final String? message;

  @override
  String toString() =>
      'AppleFoundationModelsException(${error.code}): $message';
}

/// Dart entry point to Apple's on-device Foundation Models framework.
///
/// Every [respond] call runs in a fresh native session, so callers own the
/// conversation history and decide how much of it fits the model context.
class AppleFoundationModels {
  /// Creates a client bound to the plugin method [channel].
  const AppleFoundationModels({
    MethodChannel channel = const MethodChannel('apple_foundation_models'),
  }) : _channel = channel;

  final MethodChannel _channel;

  /// Returns whether the system language model can be used right now.
  ///
  /// Platforms without the native plugin report
  /// [AppleFoundationModelsAvailability.unavailable].
  Future<AppleFoundationModelsAvailability> availability() async {
    try {
      final value = await _channel.invokeMethod<String>('availability');
      return AppleFoundationModelsAvailability.fromWire(value);
    } on MissingPluginException {
      return AppleFoundationModelsAvailability.unavailable;
    }
  }

  /// Generates a response to [prompt] following [instructions].
  ///
  /// [temperature] ranges from 0 to 1 and [maximumResponseTokens] caps the
  /// response length. Throws [AppleFoundationModelsException] on failure.
  Future<String> respond({
    required String instructions,
    required String prompt,
    double? temperature,
    int? maximumResponseTokens,
  }) async {
    try {
      final content = await _channel.invokeMethod<String>('respond', {
        'instructions': instructions,
        'prompt': prompt,
        'temperature': temperature,
        'maximumResponseTokens': maximumResponseTokens,
      });
      if (content == null) {
        throw const AppleFoundationModelsException(
          AppleFoundationModelsError.generationFailed,
          'The model returned no content.',
        );
      }
      return content;
    } on PlatformException catch (e) {
      throw AppleFoundationModelsException(
        AppleFoundationModelsError.fromCode(e.code),
        e.message,
      );
    } on MissingPluginException catch (e) {
      throw AppleFoundationModelsException(
        AppleFoundationModelsError.unavailable,
        e.message,
      );
    }
  }
}
