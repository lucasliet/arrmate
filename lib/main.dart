import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/background_notification_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/logger_service.dart';
import 'presentation/providers/app_providers.dart';

/// Main entry point for the application.
///
/// Initializes Flutter bindings, sets up the [ProviderContainer] for dependency injection,
/// triggers the initialization of the [NotificationService] and [BackgroundNotificationService],
/// and runs the [ArrmateApp].
///
/// If initialization of critical services fails, it logs a critical error and
/// updates the [initializationErrorProvider] to notify the user.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  try {
    await container.read(notificationServiceProvider).init();
    await BackgroundNotificationService.initialize();
    logger.info('[main] Notification services initialized');
  } catch (e, stackTrace) {
    logger.error(
      '[main] CRITICAL: Failed to initialize services',
      e,
      stackTrace,
    );
    container.read(initializationErrorProvider.notifier).state =
        'Failed to initialize notification services. Some features may not work correctly.';
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const ArrmateApp()),
  );
}
