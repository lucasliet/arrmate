import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_locale.dart';
import '../providers/locale_provider.dart';
import '../providers/settings_provider.dart';

/// Full-screen first-boot prompt asking which language the app should use.
///
/// The choice is preselected from the device language and the prompt itself
/// switches language as the user taps an option, so each choice previews the
/// interface it leads to. It cannot be dismissed without choosing.
class LanguagePickerDialog extends ConsumerStatefulWidget {
  const LanguagePickerDialog({super.key});

  /// Shows the prompt when [languagePromptPendingProvider] is set and waits
  /// for the user to confirm a language.
  ///
  /// Returns immediately when the prompt is not pending.
  static Future<void> showIfNeeded(BuildContext context, WidgetRef ref) async {
    if (!ref.read(languagePromptPendingProvider)) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => const LanguagePickerDialog(),
    );
  }

  @override
  ConsumerState<LanguagePickerDialog> createState() =>
      _LanguagePickerDialogState();
}

class _LanguagePickerDialogState extends ConsumerState<LanguagePickerDialog> {
  late AppLanguage _selected;

  @override
  void initState() {
    super.initState();
    _selected = AppLanguage.fromDeviceLocales(ref.read(deviceLocalesProvider));
  }

  Future<void> _confirm() async {
    await ref.read(settingsProvider.notifier).setLanguage(_selected);
    ref.read(languagePromptPendingProvider.notifier).state = false;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appLocalizationsFor(_selected.locale!);

    return PopScope(
      canPop: false,
      child: Dialog.fullscreen(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(paddingLg),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(radiusLg),
                    child: Image.asset(
                      'assets/images/icon.png',
                      width: 72,
                      height: 72,
                    ),
                  ),
                  const SizedBox(height: paddingLg),
                  Text(
                    l10n.languagePromptTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: paddingSm),
                  Text(
                    l10n.languagePromptSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: paddingLg),
                  RadioGroup<AppLanguage>(
                    groupValue: _selected,
                    onChanged: (value) {
                      if (value != null) setState(() => _selected = value);
                    },
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final language in AppLanguage.explicit)
                            RadioListTile<AppLanguage>(
                              key: ValueKey('language_${language.name}'),
                              value: language,
                              title: Text(language.nativeName!),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: paddingLg),
                  FilledButton(
                    key: const ValueKey('language_continue'),
                    onPressed: _confirm,
                    child: Text(l10n.commonContinue),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
