import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/l10n/app_locale.dart';
import 'core/platform/platform_capabilities.dart';
import 'core/services/legacy_web_google_token_cleanup.dart';
import 'core/services/logger_service.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/notifications_provider.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/router/app_router.dart';

/// Main entry point for the application.
///
/// Initializes Flutter bindings, sets up the [ProviderContainer] for dependency injection,
/// triggers the initialization of the [InAppNotificationService], and runs the [ArrmateApp].
///
/// Optional service failures are logged without preventing application startup.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The media engine has native libraries and must not be touched on web.
  var mediaKitAvailable = !kIsWeb;
  if (!kIsWeb) {
    try {
      MediaKit.ensureInitialized();
    } catch (e, stackTrace) {
      mediaKitAvailable = false;
      logger.warning(
        '[main] MediaKit initialization failed; internal video player disabled',
        e,
        stackTrace,
      );
    }
  }

  final prefs = await SharedPreferences.getInstance();
  if (kIsWeb) {
    await clearLegacyWebGoogleOAuthTokens(prefs);
  }
  final homeTabName = prefs.getString('home_tab');
  final homeTab = homeTabName != null
      ? AppTab.values.firstWhere(
          (e) => e.name == homeTabName,
          orElse: () => AppTab.movies,
        )
      : AppTab.movies;

  initializeRouter(homeTab.path);

  final storedLanguage = prefs.getString(appLocalePreferenceKey);
  final initialLanguage = AppLanguage.fromStorage(storedLanguage);
  // Only a fresh install is asked for its language: existing installs keep
  // following the device language until changed in Settings.
  final languagePromptPending =
      storedLanguage == null &&
      !(prefs.getBool(OnboardingNotifier.kOnboardingCompleteKey) ?? false);

  final defaultCapabilities = PlatformCapabilities.current();
  final container = ProviderContainer(
    overrides: [
      initialLanguageProvider.overrideWithValue(initialLanguage),
      languagePromptPendingProvider.overrideWith(
        (ref) => languagePromptPending,
      ),
      if (!kIsWeb && !mediaKitAvailable)
        platformCapabilitiesProvider.overrideWithValue(
          PlatformCapabilities(
            isWeb: defaultCapabilities.isWeb,
            supportsAppUpdates: defaultCapabilities.supportsAppUpdates,
            supportsBackgroundNotifications:
                defaultCapabilities.supportsBackgroundNotifications,
            localAssistantRuntime: defaultCapabilities.localAssistantRuntime,
            supportsFileSystemCache:
                defaultCapabilities.supportsFileSystemCache,
            supportsBrowserFileInput:
                defaultCapabilities.supportsBrowserFileInput,
            supportsInternalVideoPlayer: false,
          ),
        ),
    ],
  );

  try {
    await container.read(inAppNotificationServiceProvider).init();
    logger.info('[main] In-app notification service initialized');
  } catch (e, stackTrace) {
    if (kIsWeb) {
      logger.warning(
        '[main] Optional notification service initialization failed',
        e,
        stackTrace,
      );
    } else {
      logger.error(
        '[main] CRITICAL: Failed to initialize services',
        e,
        stackTrace,
      );
      container.read(initializationErrorProvider.notifier).state = container
          .read(appLocalizationsProvider)
          .appInitNotificationServicesFailed;
    }
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const ArrmateApp()),
  );
}
