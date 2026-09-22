import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/logger_service.dart';
import 'presentation/providers/notifications_provider.dart';
import 'presentation/router/app_router.dart';

/// Main entry point for the application.
///
/// Initializes Flutter bindings, sets up the [ProviderContainer] for dependency injection,
/// triggers the initialization of the [InAppNotificationService], and runs the [ArrmateApp].
///
/// Optional service failures are logged without preventing application startup.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final homeTabName = prefs.getString('home_tab');
  final homeTab = homeTabName != null
      ? AppTab.values.firstWhere(
          (e) => e.name == homeTabName,
          orElse: () => AppTab.movies,
        )
      : AppTab.movies;

  initializeRouter(homeTab.path);

  final container = ProviderContainer();

  try {
    await container.read(inAppNotificationServiceProvider).init();
    logger.info('[main] In-app notification service initialized');
  } catch (e, stackTrace) {
    logger.warning(
      '[main] Optional notification service initialization failed',
      e,
      stackTrace,
    );
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const ArrmateApp()),
  );
}
