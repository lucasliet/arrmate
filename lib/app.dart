import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/widgets/update_dialog.dart';
import 'presentation/providers/update_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/providers/settings_provider.dart';

class ArrmateApp extends ConsumerStatefulWidget {
  const ArrmateApp({super.key});

  @override
  ConsumerState<ArrmateApp> createState() => _ArrmateAppState();
}

class _ArrmateAppState extends ConsumerState<ArrmateApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateProvider.notifier).checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Consumer(
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

        return MaterialApp.router(
          title: 'Arrmate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(settings.colorScheme),
          darkTheme: AppTheme.dark(settings.colorScheme),
          themeMode: settings.appearance.themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
