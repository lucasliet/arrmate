import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../player/playback_stop_gate.dart';
import 'providers/watching_provider.dart';

/// Refreshes Continue Watching when the router leaves `/player`.
///
/// Browser Back on web updates the reported location without reliably
/// disposing the player route. The in-app back button pops through the
/// navigator, which updates [GoRouter.routerDelegate] before the reported
/// location catches up. The refresh listens to both. A real player registers
/// its Stopped report on [playbackStopGateProvider]; this widget waits for
/// that report before invalidating. The web fallback never registers a
/// report, so the refresh runs on the next frame.
class WatchingRouteRefresh extends ConsumerStatefulWidget {
  /// Creates a refresh listener around [child].
  const WatchingRouteRefresh({super.key, required this.child});

  /// Subtree that stays mounted while `/player` is shown above the shell.
  final Widget child;

  @override
  ConsumerState<WatchingRouteRefresh> createState() =>
      _WatchingRouteRefreshState();
}

class _WatchingRouteRefreshState extends ConsumerState<WatchingRouteRefresh> {
  GoRouter? _router;
  bool _reportedOnPlayer = false;
  bool _displayedOnPlayer = false;
  bool _leaveScheduled = false;
  int _leaveGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (identical(router, _router)) {
      return;
    }
    _stopListening();
    _router = router;
    if (router != null) {
      _remember(router);
    }
    router?.routeInformationProvider.addListener(_onRouteChanged);
    router?.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  void _stopListening() {
    _router?.routeInformationProvider.removeListener(_onRouteChanged);
    _router?.routerDelegate.removeListener(_onRouteChanged);
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _remember(GoRouter router) {
    _reportedOnPlayer = _isPlayerPath(
      router.routeInformationProvider.value.uri.path,
    );
    _displayedOnPlayer = _matchListShowsPlayer(
      router.routerDelegate.currentConfiguration,
    );
    _leaveScheduled = false;
  }

  void _onRouteChanged() {
    final router = _router;
    if (router == null || !mounted) {
      return;
    }
    final reported = _isPlayerPath(
      router.routeInformationProvider.value.uri.path,
    );
    final displayed = _matchListShowsPlayer(
      router.routerDelegate.currentConfiguration,
    );
    final entered =
        (reported && !_reportedOnPlayer) || (displayed && !_displayedOnPlayer);
    if (entered) {
      _leaveScheduled = false;
    }
    final reportedLeft = _reportedOnPlayer && !reported;
    final displayedLeft = _displayedOnPlayer && !displayed;
    _reportedOnPlayer = reported;
    _displayedOnPlayer = displayed;
    if (_leaveScheduled || (!reportedLeft && !displayedLeft)) {
      return;
    }
    _leaveScheduled = true;
    final generation = ++_leaveGeneration;
    final gate = ref.read(playbackStopGateProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAfterStop(container, gate, generation);
    });
  }

  /// Invalidates Continue Watching once [gate] has finished its stop report.
  Future<void> _refreshAfterStop(
    ProviderContainer container,
    PlaybackStopGate gate,
    int generation,
  ) async {
    await gate.settled;
    if (!mounted || generation != _leaveGeneration) {
      return;
    }
    container.invalidate(watchingItemsProvider);
  }
}

/// Whether [path] is the player route, ignoring a trailing slash.
bool _isPlayerPath(String path) {
  return _stripTrailingSlash(path) == '/player';
}

/// Whether [list] still contains the pushed `/player` page.
///
/// [RouteMatchList.uri] omits [ImperativeRouteMatch] entries, so a `push` of
/// `/player` leaves the URI on the shell location. The imperative match is
/// the page that is actually on screen.
bool _matchListShowsPlayer(RouteMatchList list) {
  return _isPlayerPath(list.uri.path) || _matchesShowPlayer(list.matches);
}

bool _matchesShowPlayer(List<RouteMatchBase> matches) {
  for (final match in matches) {
    if (match is ImperativeRouteMatch && _matchListShowsPlayer(match.matches)) {
      return true;
    }
    if (match is ShellRouteMatch && _matchesShowPlayer(match.matches)) {
      return true;
    }
    if (match is RouteMatch && match.route.path == '/player') {
      return true;
    }
  }
  return false;
}

String _stripTrailingSlash(String path) {
  if (path.length > 1 && path.endsWith('/')) {
    return path.substring(0, path.length - 1);
  }
  return path;
}
