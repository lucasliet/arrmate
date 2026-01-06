import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/logger_service.dart';

/// Widget that listens for deep links and handles navigation.
class DeepLinkListener extends StatefulWidget {
  final Widget child;

  const DeepLinkListener({super.key, required this.child});

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link
    // Note: AppLinks automatically handles initial link via the stream usually,
    // but getInitialUri() is also available for cold start check if needed specific logic.
    // Stream is preferred using latest 6.x/7.x best practices.

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    if (!mounted) return;

    // Example: arrmate://movies/123
    // GoRouter can handle this if we configured it, but manual handling gives more control

    // Simplest approach: Just let GoRouter handle the path if it matches our routes
    // Ensure the path is compatible
    final path = uri.path;
    if (path.isNotEmpty) {
      // Assuming arrmate://host/path format, uri.path gives /path
      // If arrmate:///path, uri.path is /path
      logger.debug(
        'Deep link detected: $path with params ${uri.queryParameters}',
      );

      try {
        // Create a valid location string including query params
        final location = Uri(
          path: path,
          queryParameters: uri.queryParameters,
        ).toString();
        context.go(location);
      } catch (e, stack) {
        logger.error('Failed to navigate to deep link', e, stack);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
