import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_locale.dart';
import 'core/platform/platform_capabilities.dart';
import 'presentation/widgets/language_picker_dialog.dart';
import 'presentation/widgets/update_dialog.dart';
import 'presentation/widgets/whats_new_dialog.dart';
import 'presentation/widgets/deep_link_listener.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/providers/backup_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/update_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/theme/app_scroll_behavior.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/tour/app_tour_service.dart';

/// The root widget of the application.
///
/// This widget sets up the [MaterialApp] with the router, theme, and global providers.
/// It also handles global initialization checks (like updates and startup errors).
class ArrmateApp extends ConsumerStatefulWidget {
  const ArrmateApp({super.key});

  @override
  ConsumerState<ArrmateApp> createState() => _ArrmateAppState();
}

class _ArrmateAppState extends ConsumerState<ArrmateApp>
    with WidgetsBindingObserver {
  bool _tourTriggered = false;

  /// Whether the startup prompts that must precede the tour (language
  /// choice) have been resolved.
  bool _startupPromptsDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(onboardingProvider, _onOnboardingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final capabilities = ref.read(platformCapabilitiesProvider);
      if (!kDebugMode && capabilities.supportsAppUpdates) {
        ref.read(updateProvider.notifier).checkForUpdate();
      }

      unawaited(_runStartupPrompts());

      if (!kIsWeb) {
        final initError = ref.read(initializationErrorProvider);
        if (initError != null) {
          _showErrorDialog(initError);
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    ref.invalidate(deviceLocalesProvider);
  }

  /// Shows the first-boot language prompt, then the changelog, and only then
  /// lets the onboarding tour start so it runs in the chosen language.
  Future<void> _runStartupPrompts() async {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext != null) {
      await LanguagePickerDialog.showIfNeeded(navContext, ref);
      final whatsNewContext = rootNavigatorKey.currentContext;
      if (whatsNewContext != null && whatsNewContext.mounted) {
        unawaited(WhatsNewDialog.showIfNeeded(whatsNewContext, ref));
      }
    }
    if (!mounted) return;
    _startupPromptsDone = true;
    _onOnboardingChanged(null, ref.read(onboardingProvider));
  }

  void _onOnboardingChanged(OnboardingState? previous, OnboardingState next) {
    if (!_startupPromptsDone) return;
    if (_tourTriggered || !next.isLoaded || next.isComplete) return;
    if (rootNavigatorKey.currentContext == null) return;
    _tourTriggered = true;
    ref.read(appTourServiceProvider).startFull();
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    final navContext = rootNavigatorKey.currentContext ?? context;
    showDialog(
      context: navContext,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).appInitErrorTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).commonDismiss),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    ref.watch(automaticBackupListenerProvider);
    final locale = ref.watch(currentLocaleProvider);

    final capabilities = ref.watch(platformCapabilitiesProvider);
    final application = MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.colorScheme),
      darkTheme: AppTheme.dark(settings.colorScheme),
      themeMode: settings.appearance.themeMode,
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: appRouter,
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, child) {
            // Listen for update availability inside the MaterialApp context
            ref.listen(updateProvider, (previous, next) {
              if (kDebugMode || !capabilities.supportsAppUpdates) {
                return;
              }

              if (next.status == UpdateStatus.available &&
                  previous?.status != UpdateStatus.available) {
                final navContext = rootNavigatorKey.currentContext;
                if (navContext != null) {
                  showDialog(
                    context: navContext,
                    barrierDismissible: false,
                    builder: (context) => const UpdateDialog(),
                  );
                }
              }
            });

            return child!;
          },
          child: child,
        );
      },
    );
    if (capabilities.isWeb) return application;
    return DeepLinkListener(onNavigate: appRouter.go, child: application);
  }
}
