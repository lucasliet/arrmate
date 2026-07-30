import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../core/services/logger_service.dart';

/// The custom URI scheme handled by the app's deep links.
const String kDeepLinkScheme = 'arrmate';

const Set<String> _settingsRoutes = {
  'assistant',
  'logs',
  'health',
  'system-overview',
  'version-history',
  'diagnostics',
  'quality-profiles',
  'notifications',
};

/// Reconciles the identifier-in-host form (`arrmate://movies/123`) with the
/// authority-less form (`arrmate:///movies/123`) so both resolve to the same
/// GoRouter location.
String deepLinkToLocation(Uri uri) {
  final segments = <String>[
    if (uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments,
  ].where((segment) => segment.isNotEmpty).toList();

  if (segments.isEmpty) return '';

  return Uri(
    pathSegments: ['', ...segments],
    queryParameters: uri.hasQuery ? uri.queryParametersAll : null,
  ).toString();
}

/// Validates that [uri] targets the app scheme and matches a known route
/// grammar. Returns the normalized GoRouter location when valid, otherwise
/// `null` so the caller can reject the link instead of navigating to a
/// fallback with silently zeroed identifiers.
String? validateDeepLink(Uri uri) {
  if (uri.scheme != kDeepLinkScheme) return null;

  final location = deepLinkToLocation(uri);
  if (location.isEmpty) return null;

  final normalizedUri = Uri.tryParse(location);
  if (normalizedUri == null) return null;
  final segments = normalizedUri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.isEmpty) return null;

  switch (segments.first) {
    case 'movies':
      if (segments.length == 2 && _isPositiveInt(segments[1])) return location;
      return segments.length == 1 ? location : null;
    case 'series':
      if (segments.length == 2 && _isPositiveInt(segments[1])) return location;
      if (segments.length == 4 &&
          segments[2] == 'season' &&
          _isPositiveInt(segments[1]) &&
          _isNonNegativeInt(segments[3])) {
        return location;
      }
      if (segments.length == 6 &&
          segments[2] == 'season' &&
          segments[4] == 'episode' &&
          _isPositiveInt(segments[1]) &&
          _isNonNegativeInt(segments[3]) &&
          _isPositiveInt(segments[5])) {
        return location;
      }
      return segments.length == 1 ? location : null;
    case 'settings':
      if (segments.length == 1) return location;
      if (segments.length == 2 && _settingsRoutes.contains(segments[1])) {
        return location;
      }
      if (segments.length == 3 && segments[1] == 'instance') {
        return location;
      }
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
  /// The widget tree kept under the global deep-link subscription.
  final Widget child;

  /// Navigates to a validated application location.
  final ValueChanged<String> onNavigate;

  /// Optional link stream used by focused widget tests.
  final Stream<Uri>? linkStream;

  const DeepLinkListener({
    super.key,
    required this.child,
    required this.onNavigate,
    this.linkStream,
  });

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
    _linkSubscription = (widget.linkStream ?? _appLinks.uriLinkStream).listen(
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
      logger.warning(
        '[DeepLinkListener] Rejected unsupported deep link for scheme: '
        '${uri.scheme}',
      );
      return;
    }

    final routePath = Uri.tryParse(location)?.path ?? '/';
    logger.debug('[DeepLinkListener] Deep link detected for route: $routePath');

    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) => _navigate(location));
    // addPostFrameCallback does not request a new frame. A link can arrive
    // between frames, so schedule one to guarantee the deferred navigation runs.
    binding.scheduleFrame();
  }

  void _navigate(String location) {
    if (!mounted) return;

    try {
      widget.onNavigate(location);
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
