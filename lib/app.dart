import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/widgets/update_dialog.dart';
import 'presentation/providers/update_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/providers/settings_provider.dart';

class ArrmateApp extends ConsumerWidget {
  const ArrmateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          // Listen for update availability
          ref.listen(updateProvider, (previous, next) {
            if (next.status == UpdateStatus.available && previous?.status != UpdateStatus.available) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const UpdateDialog(),
              );
            }
          });

          // Check for updates on startup (subject to daily limit)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(updateProvider.notifier).checkForUpdate();
          });

          return MaterialApp.router(
            title: 'Arrmate',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(settings.colorScheme),
            darkTheme: AppTheme.dark(settings.colorScheme),
            themeMode: settings.appearance.themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
