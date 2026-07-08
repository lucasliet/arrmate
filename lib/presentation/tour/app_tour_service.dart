import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../core/services/logger_service.dart';
import '../providers/onboarding_provider.dart';
import '../router/app_router.dart';
import 'app_tour_keys.dart';

/// Orchestrates the guided tour across multiple screens using
/// [TutorialCoachMark].
///
/// The tour is split into segments that run on different routes. Each segment
/// finishes into the next via [onFinish], and any segment can be aborted via
/// the global Skip button which cancels the whole chain.
class AppTourService {
  final Ref _ref;
  final AppTourKeys _keys;
  bool _cancelled = false;

  AppTourService(this._ref, this._keys);

  /// Starts the full guided tour from the beginning.
  void startFull() {
    logger.info('[AppTourService] Starting full tour');
    _cancelled = false;
    _runInstanceSegment();
  }

  Future<void> _runInstanceSegment() async {
    if (_cancelled) return;
    await _navigateTo('/settings');
    await _waitForKey(_keys.settingsInstancesHeaderKey);

    _present(
      targets: [
        _target(
          key: _keys.settingsInstancesHeaderKey,
          identify: 'settings_instances',
          title: 'Instances',
          body:
              'Your Radarr, Sonarr, and qBittorrent servers live here. '
              'Let\'s add your first one.',
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.settingsAddInstanceKey,
          identify: 'settings_add_instance',
          title: 'Add Instance',
          body:
              'Tap here to create a new server connection. The next steps '
              'walk through the form.',
          align: ContentAlign.top,
        ),
      ],
      onFinish: _runInstanceFormSegment,
    );
  }

  Future<void> _runInstanceFormSegment() async {
    if (_cancelled) return;
    await _navigateTo('/settings/instance/new');
    await _waitForKey(_keys.instanceTypeSelectorKey);

    _present(
      targets: [
        _target(
          key: _keys.instanceTypeSelectorKey,
          identify: 'instance_type',
          title: 'Choose the server type',
          body:
              'Pick Radarr (movies), Sonarr (series), or qBittorrent '
              '(downloads). Each needs its own connection.',
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.instanceNameFieldKey,
          identify: 'instance_name',
          title: 'Name',
          body:
              'A friendly label so you can tell your servers apart '
              '(e.g. "Home Server").',
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.instanceUrlFieldKey,
          identify: 'instance_url',
          title: 'URL',
          body:
              'Your server address including http(s):// and port, '
              'e.g. http://192.168.1.10:7878.',
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.instanceApiKeyFieldKey,
          identify: 'instance_api_key',
          title: 'API Key',
          body:
              'Radarr/Sonarr require an API key from Settings → General. '
              'qBittorrent uses a Bearer token (v5.2.0+) or Basic Auth.',
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.instanceTestConnectionKey,
          identify: 'instance_test',
          title: 'Test Connection',
          body: 'Verifies the URL and credentials before saving.',
          align: ContentAlign.top,
        ),
        _target(
          key: _keys.instanceSaveKey,
          identify: 'instance_save',
          title: 'Save Instance',
          body:
              'When everything checks out, save to finish setup. You can '
              'add the other servers any time from Settings.',
          align: ContentAlign.top,
        ),
      ],
      onFinish: _runDiscoverySegment,
    );
  }

  Future<void> _runDiscoverySegment() async {
    if (_cancelled) return;
    await _navigateTo('/movies');
    await _waitForKey(_keys.moviesSearchKey);

    _present(
      targets: [
        _target(
          key: _keys.moviesSearchKey,
          identify: 'movies_search',
          title: 'Search',
          body: 'Find movies in your library by title.',
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.moviesSortKey,
          identify: 'movies_sort',
          title: 'Sort & Filter',
          body: 'Reorder and filter your library to browse faster.',
          align: ContentAlign.bottom,
        ),
      ],
      onFinish: _runCalendarStep,
    );
  }

  Future<void> _runCalendarStep() async {
    if (_cancelled) return;
    await _navigateTo('/calendar');
    await _waitForKey(_keys.calendarTitleKey);

    _present(
      targets: [
        _target(
          key: _keys.calendarTitleKey,
          identify: 'calendar',
          title: 'Calendar',
          body: 'Track upcoming movie releases and series episodes.',
          align: ContentAlign.bottom,
        ),
      ],
      onFinish: _runActivityStep,
    );
  }

  Future<void> _runActivityStep() async {
    if (_cancelled) return;
    await _navigateTo('/activity');
    await _waitForKey(_keys.activityTabBarKey);

    _present(
      targets: [
        _target(
          key: _keys.activityTabBarKey,
          identify: 'activity_tabs',
          title: 'Activity',
          body:
              'Monitor your download queue, history, and qBittorrent '
              'torrents here.',
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.navBarKey,
          identify: 'nav_bar',
          title: 'Navigation',
          body:
              'Switch between Movies, Series, Calendar, Activity, and '
              'Settings anytime.',
          align: ContentAlign.top,
        ),
      ],
      onFinish: _finishTour,
    );
  }

  /// Aborts the entire tour chain and marks onboarding complete.
  void _skipAll() {
    logger.info('[AppTourService] Tour skipped by user');
    _cancelled = true;
    _finishTour();
  }

  void _finishTour() {
    logger.info('[AppTourService] Tour finished');
    _ref.read(onboardingProvider.notifier).markComplete();
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      GoRouter.of(context).go('/movies');
    }
  }

  /// Navigates to [route] using the root navigator, waiting one frame so the
  /// target screen mounts before its keys are referenced.
  Future<void> _navigateTo(String route) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    GoRouter.of(context).go(route);
    await _nextFrame;
  }

  /// Waits until the widget referenced by [key] is mounted and laid out,
  /// timing out after [timeout] to avoid hanging the tour.
  Future<void> _waitForKey(
    GlobalKey key, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (AppTourKeys.isReady(key)) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    logger.warning('[AppTourService] Timed out waiting for key $key');
  }

  /// Builds and shows a [TutorialCoachMark] overlay with the shared visual
  /// configuration. The Skip button is always visible and aborts the whole
  /// tour via [_skipAll].
  void _present({
    required List<TargetFocus> targets,
    required VoidCallback onFinish,
  }) {
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      paddingFocus: 10,
      hideSkip: false,
      textSkip: 'Skip',
      alignSkip: Alignment.bottomRight,
      onFinish: onFinish,
      onSkip: () {
        _skipAll();
        return true;
      },
    ).showWithNavigatorStateKey(
      navigatorKey: rootNavigatorKey,
      rootOverlay: true,
    );
  }

  TargetFocus _target({
    required GlobalKey key,
    required String identify,
    required String title,
    required String body,
    required ContentAlign align,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: key,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: align,
          child: _TourBubble(title: title, body: body),
        ),
      ],
    );
  }
}

/// A [Future] that completes after the current frame, used to let a newly
/// pushed route mount before referencing its widget keys.
Future<void> get _nextFrame {
  final completer = Completer<void>();
  WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
  return completer.future;
}

/// Provider for the [AppTourService].
final appTourServiceProvider = Provider<AppTourService>((ref) {
  return AppTourService(ref, ref.read(appTourKeysProvider));
});

/// Bubble rendered inside each coach mark.
class _TourBubble extends StatelessWidget {
  final String title;
  final String body;

  const _TourBubble({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
