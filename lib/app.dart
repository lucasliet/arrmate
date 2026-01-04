import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/router/app_router.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/providers/settings_provider.dart';

class ArrmateApp extends ConsumerWidget {
  const ArrmateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Arrmate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.colorScheme),
      darkTheme: AppTheme.dark(settings.colorScheme),
      themeMode: settings.appearance.themeMode,
      routerConfig: appRouter,
    );
  }
}
