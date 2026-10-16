import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/services/logger_service.dart';
import '../providers/onboarding_provider.dart';
import '../router/app_router.dart';
import 'app_tour_keys.dart';
import 'tour_mockup_provider.dart';
import '../l10n/core_labels.dart';

/// Shows the tour overlay over [targets], reporting the user walking to the
/// end through [onFinish] and the Skip button through [onSkip].
///
/// Injected into [AppTourService] so tests can drive the segment chain without
/// mounting a real coach mark over the root navigator.
typedef TourOverlayPresenter =
    void Function({
      required List<TargetFocus> targets,
      required VoidCallback onFinish,
      required VoidCallback onSkip,
    });

/// Orchestrates the guided tour across multiple screens using
/// [TutorialCoachMark].
///
/// The tour is split into segments that run on different routes. Each segment
/// finishes into the next via [onFinish], and any segment can be aborted via
/// the global Skip button which cancels the whole chain.
///
/// While the tour runs, screens that depend on Radarr, Sonarr or qBittorrent
/// data paint sample content (see [tourActiveProvider]), so every step points
/// at a visible element even on a fresh install with no instance configured.
class AppTourService {
  final Ref _ref;
  final AppTourKeys _keys;

  /// How long a segment waits for its anchor widget to be laid out before
  /// giving up and moving on.
  final Duration _keyTimeout;

  late final TourOverlayPresenter _presenter;

  bool _cancelled = false;

  /// Translations captured when the tour starts, so every coach mark of a run
  /// uses the interface language active at that moment.
  AppLocalizations _l10n = appLocalizationsFor(const Locale('en'));

  AppTourService(
    this._ref,
    this._keys, {
    TourOverlayPresenter? presenter,
    Duration keyTimeout = const Duration(seconds: 3),
  }) : _keyTimeout = keyTimeout {
    _presenter = presenter ?? _showCoachMark;
  }

  /// Starts the full guided tour from the beginning.
  void startFull() {
    logger.info('[AppTourService] Starting full tour');
    _cancelled = false;
    _l10n = readAppLocalizations(_ref);
    _ref.read(tourActiveProvider.notifier).start();
    _runInstanceSegment();
  }

  Future<void> _runInstanceSegment() async {
    if (_cancelled) return;
    final l10n = _l10n;
    await _navigateTo('/settings');
    await _waitForKey(_keys.settingsInstancesHeaderKey);

    _present(
      targets: [
        _target(
          key: _keys.settingsInstancesHeaderKey,
          identify: 'settings_instances',
          title: l10n.tourInstancesTitle,
          body: l10n.tourInstancesBody,
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.settingsAddInstanceKey,
          identify: 'settings_add_instance',
          title: l10n.tourAddInstanceTitle,
          body: l10n.tourAddInstanceBody,
          align: ContentAlign.top,
        ),
      ],
      onFinish: _runInstanceFormSegment,
    );
  }

  Future<void> _runInstanceFormSegment() async {
    if (_cancelled) return;
    final l10n = _l10n;
    await _navigateTo('/settings/instance/new');
    await _waitForKey(_keys.instanceTypeSelectorKey);

    _present(
      targets: [
        _target(
          key: _keys.instanceTypeSelectorKey,
          identify: 'instance_type',
          title: l10n.tourInstanceTypeTitle,
          body: l10n.tourInstanceTypeBody,
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.instanceNameFieldKey,
          identify: 'instance_name',
          title: l10n.tourInstanceNameTitle,
          body: l10n.tourInstanceNameBody,
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.instanceUrlFieldKey,
          identify: 'instance_url',
          title: l10n.tourInstanceUrlTitle,
          body: l10n.tourInstanceUrlBody,
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.instanceApiKeyFieldKey,
          identify: 'instance_api_key',
          title: l10n.tourInstanceApiKeyTitle,
          body: l10n.tourInstanceApiKeyBody,
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.instanceTestConnectionKey,
          identify: 'instance_test',
          title: l10n.tourTestConnectionTitle,
          body: l10n.tourTestConnectionBody,
          align: ContentAlign.top,
        ),
        _target(
          key: _keys.instanceSaveKey,
          identify: 'instance_save',
          title: l10n.tourSaveInstanceTitle,
          body: l10n.tourSaveInstanceBody,
          align: ContentAlign.top,
        ),
      ],
      onFinish: _runDiscoverySegment,
    );
  }

  Future<void> _runDiscoverySegment() async {
    if (_cancelled) return;
    final l10n = _l10n;
    await _navigateTo('/movies');
    await _waitForKey(_keys.moviesSearchKey);

    _present(
      targets: [
        _target(
          key: _keys.moviesLibraryKey,
          identify: 'movies_library',
          title: l10n.tourMoviesLibraryTitle,
          body: l10n.tourMoviesLibraryBody,
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.moviesSearchKey,
          identify: 'movies_search',
          title: l10n.commonSearch,
          body: l10n.tourMoviesSearchBody,
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.moviesSortKey,
          identify: 'movies_sort',
          title: l10n.tourMoviesSortTitle,
          body: l10n.tourMoviesSortBody,
          align: ContentAlign.bottom,
        ),
      ],
      onFinish: _runSeriesSegment,
    );
  }

  Future<void> _runSeriesSegment() async {
    if (_cancelled) return;
    final l10n = _l10n;
    await _navigateTo('/series');
    await _waitForKey(_keys.seriesLibraryKey);

    _present(
      targets: [
        _target(
          key: _keys.seriesLibraryKey,
          identify: 'series_library',
          title: l10n.tourSeriesLibraryTitle,
          body: l10n.tourSeriesLibraryBody,
          align: ContentAlign.bottom,
        ),
      ],
      onFinish: _runCalendarStep,
    );
  }

  Future<void> _runCalendarStep() async {
    if (_cancelled) return;
    final l10n = _l10n;
    await _navigateTo('/calendar');
    await _waitForKey(_keys.calendarTitleKey);

    _present(
      targets: [
        _target(
          key: _keys.calendarTitleKey,
          identify: 'calendar',
          title: l10n.labelTabCalendar,
          body: l10n.tourCalendarBody,
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.calendarListKey,
          identify: 'calendar_events',
          title: l10n.tourCalendarEventsTitle,
          body: l10n.tourCalendarEventsBody,
          align: ContentAlign.bottom,
        ),
      ],
      onFinish: _runActivityStep,
    );
  }

  Future<void> _runActivityStep() async {
    if (_cancelled) return;
    final l10n = _l10n;
    await _navigateTo('/activity');
    await _waitForKey(_keys.activityTabBarKey);

    _present(
      targets: [
        _target(
          key: _keys.activityTabBarKey,
          identify: 'activity_tabs',
          title: l10n.labelTabActivity,
          body: l10n.tourActivityBody,
          align: ContentAlign.bottom,
        ),
        _target(
          key: _keys.activityQueueKey,
          identify: 'activity_queue',
          title: l10n.tourActivityQueueTitle,
          body: l10n.tourActivityQueueBody,
          align: ContentAlign.bottom,
        ),
      ],
      onFinish: _runTorrentsStep,
    );
  }

  Future<void> _runTorrentsStep() async {
    if (_cancelled) return;
    final l10n = _l10n;
    await _selectTorrentsTab();
    await _waitForKey(_keys.activityTorrentKey);

    _present(
      targets: [
        _target(
          key: _keys.activityTorrentKey,
          identify: 'activity_torrents',
          title: l10n.tourTorrentsTitle,
          body: l10n.tourTorrentsBody,
          align: ContentAlign.bottom,
        ),
      ],
      onFinish: _runNavigationStep,
    );
  }

  Future<void> _runNavigationStep() async {
    if (_cancelled) return;
    final l10n = _l10n;
    await _waitForKey(_keys.navBarKey);

    _present(
      targets: [
        _target(
          key: _keys.navBarKey,
          identify: 'nav_bar',
          title: l10n.tourNavigationTitle,
          body: l10n.tourNavigationBody,
          align: _keys.navBarKey.currentWidget is NavigationRail
              ? ContentAlign.right
              : ContentAlign.top,
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
    _ref.read(tourActiveProvider.notifier).stop();
    _ref.read(onboardingProvider.notifier).markComplete();
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      GoRouter.of(context).go('/movies');
    }
  }

  /// Moves the activity screen to its torrents tab, when that tab exists.
  ///
  /// The tab bar lives under the screen's [DefaultTabController], so its key
  /// gives access to the controller without the tour reaching into the screen
  /// state. The torrents tab is always the last one, and is only built when a
  /// qBittorrent instance is configured or the tour is mocking it.
  Future<void> _selectTorrentsTab() async {
    if (!AppTourKeys.isReady(_keys.activityTorrentsTabKey)) return;
    final context = _keys.activityTabBarKey.currentContext;
    if (context == null) return;
    final controller = DefaultTabController.maybeOf(context);
    if (controller == null) return;
    controller.animateTo(controller.length - 1);
    // Let the tab transition settle, otherwise the coach mark would measure
    // the torrent card while it is still sliding into place.
    await Future<void>.delayed(kTabScrollDuration);
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
  /// timing out after [_keyTimeout] to avoid hanging the tour.
  Future<void> _waitForKey(GlobalKey key) async {
    final deadline = DateTime.now().add(_keyTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (AppTourKeys.isReady(key)) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    logger.warning('[AppTourService] Timed out waiting for key $key');
  }

  /// Hands the segment's [targets] to the overlay presenter.
  ///
  /// Targets whose widget is not on screen are dropped, so a step never
  /// highlights an empty region; when nothing is left, the segment hands over
  /// to the next one instead of showing an empty overlay.
  void _present({
    required List<TargetFocus> targets,
    required VoidCallback onFinish,
  }) {
    final visibleTargets = targets.where(_isVisible).toList();
    if (visibleTargets.isEmpty) {
      logger.warning(
        '[AppTourService] Skipping segment: no visible targets on screen',
      );
      onFinish();
      return;
    }

    _presenter(targets: visibleTargets, onFinish: onFinish, onSkip: _skipAll);
  }

  /// Default presenter: a [TutorialCoachMark] over the root navigator, with the
  /// shared visual configuration and an always visible Skip button.
  void _showCoachMark({
    required List<TargetFocus> targets,
    required VoidCallback onFinish,
    required VoidCallback onSkip,
  }) {
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      paddingFocus: 10,
      hideSkip: false,
      textSkip: _l10n.tourSkip,
      alignSkip: Alignment.bottomRight,
      onFinish: onFinish,
      onSkip: () {
        onSkip();
        return true;
      },
    ).showWithNavigatorStateKey(
      navigatorKey: rootNavigatorKey,
      rootOverlay: true,
    );
  }

  /// Whether [target] points at a widget currently mounted and laid out.
  bool _isVisible(TargetFocus target) {
    final key = target.keyTarget;
    return key != null && AppTourKeys.isReady(key);
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
