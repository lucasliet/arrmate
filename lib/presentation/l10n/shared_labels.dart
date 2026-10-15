import '../../core/l10n/app_locale.dart';
import '../../core/services/purge_service.dart';

/// Localized summary for [PurgeResult].
extension PurgeResultL10n on PurgeResult {
  /// Returns the translated multi-line snackbar summary of this result.
  ///
  /// [label] is the already translated first line announcing the operation.
  String localizedSummary(AppLocalizations l10n, {required String label}) =>
      formatSummary(label: label, l10n: l10n);
}
