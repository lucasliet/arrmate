import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/logger_service.dart';
import 'presentation/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  try {
    await container.read(notificationServiceProvider).init();
    logger.info('Notification service initialized');
  } catch (e, stackTrace) {
    logger.error('CRITICAL: Failed to initialize services', e, stackTrace);
    container.read(initializationErrorProvider.notifier).state =
        'Failed to initialize notification services. Some features may not work correctly.';
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const ArrmateApp()),
  );
}
