import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/logger_service.dart';

/// The custom URI scheme handled by the app's deep links.
const String kDeepLinkScheme = 'arrmate';

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

/// Validates that [uri] targets the app scheme and matches a known route
/// grammar. Returns the normalized GoRouter location when valid, otherwise
/// `null` so the caller can reject the link instead of navigating to a
/// fallback with silently zeroed identifiers.
String? validateDeepLink(Uri uri) {
  if (uri.scheme != kDeepLinkScheme) return null;

  final location = deepLinkToLocation(uri);
  if (location.isEmpty) return null;

  final path = Uri.parse(location).path;
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;

  switch (segments.first) {
    case 'movies':
      if (segments.length == 2 && _isPositiveInt(segments[1])) return location;
      return segments.length == 1 ? location : null;
    case 'series':
      if (segments.length == 2 && _isPositiveInt(segments[1])) return location;
      if (segments.length == 4 &&
          segments[2] == 'season' &&
          _isNonNegativeInt(segments[1]) &&
          _isNonNegativeInt(segments[3])) {
        return location;
      }
      if (segments.length == 6 &&
          segments[2] == 'season' &&
          segments[4] == 'episode' &&
          _isNonNegativeInt(segments[1]) &&
          _isNonNegativeInt(segments[3]) &&
          _isPositiveInt(segments[5])) {
        return location;
      }
      return segments.length == 1 ? location : null;
    case 'settings':
      if (segments.length == 3 && segments[1] == 'instance') return location;
      if (segments.length <= 2) return location;
      return null;
    case 'calendar':
    case 'activity':
    case 'discover':
    case 'search':
    case 'notifications':
      return segments.length == 1 ? location : null;
    default:
      return null;
  }
}

bool _isPositiveInt(String value) {
  final parsed = int.tryParse(value);
  return parsed != null && parsed > 0;
}

bool _isNonNegativeInt(String value) {
  final parsed = int.tryParse(value);
  return parsed != null && parsed >= 0;
}

/// Widget that listens for deep links and handles navigation.
///
/// Subscribes to [AppLinks.uriLinkStream] as the single source of truth: on
/// `app_links` 7.0.0 the stream delivers both the initial (cold start) link
/// and every subsequent link, so calling [AppLinks.getInitialLink] separately
/// would duplicate navigation. The subscription is created synchronously in
/// [initState] to avoid losing an intent delivered before an async gap.
class DeepLinkListener extends StatefulWidget {
  final Widget child;

  const DeepLinkListener({super.key, required this.child});

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleLink,
      onError: (Object error, StackTrace stack) {
        logger.warning(
          '[DeepLinkListener] Stream error while listening for deep links',
          error,
          stack,
        );
      },
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _handleLink(Uri uri) {
    if (!mounted) return;

    final location = validateDeepLink(uri);
    if (location == null) {
      logger.warning('[DeepLinkListener] Rejected unsupported deep link: $uri');
      return;
    }

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
