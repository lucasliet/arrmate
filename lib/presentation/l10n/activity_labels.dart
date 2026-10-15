import '../widgets/instance_load_failure_banner.dart';

/// Localization helpers for the Activity (queue/history) area.
extension InstanceLoadFailureL10n on InstanceLoadFailure {
  /// Returns a copy of this failure whose [InstanceLoadFailure.message] is
  /// replaced by the already translated [message].
  ///
  /// Providers keep an English message for logs and tests; screens swap it
  /// for the copy in the current language before showing the banner.
  InstanceLoadFailure withMessage(String message) => InstanceLoadFailure(
    instanceId: instanceId,
    instanceType: instanceType,
    instanceLabel: instanceLabel,
    message: message,
  );
}
