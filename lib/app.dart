import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/widgets/update_dialog.dart';
import 'presentation/providers/update_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/app_providers.dart'; // Added this import

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

      // Check for initialization errors
      final initError = ref.read(initializationErrorProvider);
      if (initError != null) {
        _showErrorDialog(initError);
      }
    });
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    final navContext = rootNavigatorKey.currentContext ?? context;
    showDialog(
      context: navContext,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
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
  }
}
