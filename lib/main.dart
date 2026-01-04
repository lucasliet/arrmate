import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  try {
    // Initialize notification service
    await container.read(notificationServiceProvider).init();

    // Initialize background sync service
    await container.read(backgroundSyncServiceProvider).init();
  } catch (e, stackTrace) {
    // In a real app, send to Sentry/Crashlytics
    debugPrint('CRITICAL: Failed to initialize services: $e\n$stackTrace');

    // We could use a provider to signal this to the UI
    // container.read(serviceInitializationErrorProvider.notifier).state = e.toString();
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const ArrmateApp()),
  );
}
