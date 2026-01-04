import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  
  // Initialize notification service
  await container.read(notificationServiceProvider).init();
  
  // Initialize background sync service
  await container.read(backgroundSyncServiceProvider).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ArrmateApp(),
    ),
  );
}
