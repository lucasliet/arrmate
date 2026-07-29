import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/logger_service.dart';

/// Reconciles the identifier-in-host form (`arrmate://movies/123`) with the
/// authority-less form (`arrmate:///movies/123`) so both resolve to the same
/// GoRouter location.
String deepLinkToLocation(Uri uri) {
  final segments = <String>[
    if (uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments,
  ].where((segment) => segment.isNotEmpty).toList();

  if (segments.isEmpty) return '';

  final path = '/${segments.join('/')}';
  if (uri.queryParameters.isEmpty) return path;
  return Uri(path: path, queryParameters: uri.queryParameters).toString();
}

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

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleLink(initialUri);
      }
    } catch (e, stack) {
      logger.warning(
        '[DeepLinkListener] No initial deep link resolved',
        e,
        stack,
      );
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    if (!mounted) return;

    final location = deepLinkToLocation(uri);
    if (location.isEmpty) return;

    logger.debug(
      '[DeepLinkListener] Deep link detected: $location '
      'with params ${uri.queryParameters}',
    );

    try {
      context.go(location);
    } catch (e, stack) {
      logger.error(
        '[DeepLinkListener] Failed to navigate to deep link',
        e,
        stack,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
