import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/platform/platform_capabilities.dart';
import 'presentation/widgets/update_dialog.dart';
import 'presentation/widgets/whats_new_dialog.dart';
import 'presentation/widgets/deep_link_listener.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'presentation/providers/update_provider.dart';
import 'presentation/router/app_router.dart';
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

class _ArrmateAppState extends ConsumerState<ArrmateApp> {
  bool _tourTriggered = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(onboardingProvider, _onOnboardingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final capabilities = ref.read(platformCapabilitiesProvider);
      if (!kDebugMode && capabilities.supportsAppUpdates) {
        ref.read(updateProvider.notifier).checkForUpdate();
      }

      final navContext = rootNavigatorKey.currentContext;
      if (navContext != null) {
        unawaited(WhatsNewDialog.showIfNeeded(navContext, ref));
      }
    });
  }

  void _onOnboardingChanged(OnboardingState? previous, OnboardingState next) {
    if (_tourTriggered || !next.isLoaded || next.isComplete) return;
    if (rootNavigatorKey.currentContext == null) return;
    _tourTriggered = true;
    ref.read(appTourServiceProvider).startFull();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    final capabilities = ref.watch(platformCapabilitiesProvider);
    final application = MaterialApp.router(
      title: 'Arrmate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.colorScheme),
      darkTheme: AppTheme.dark(settings.colorScheme),
      themeMode: settings.appearance.themeMode,
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
