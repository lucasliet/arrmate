import 'package:arrmate/presentation/providers/onboarding_provider.dart';
import 'package:arrmate/presentation/tour/app_tour_keys.dart';
import 'package:arrmate/presentation/tour/app_tour_service.dart';
import 'package:arrmate/presentation/tour/tour_mockup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Captures what each segment presents and lets the test act as the user
/// walking through or skipping the coach mark.
class _RecordingPresenter {
  /// Identifiers presented by each segment, in order.
  final List<List<String>> steps = [];

  VoidCallback? _onFinish;
  VoidCallback? _onSkip;

  void call({
    required List<TargetFocus> targets,
    required VoidCallback onFinish,
    required VoidCallback onSkip,
  }) {
    steps.add(targets.map((target) => '${target.identify}').toList());
    _onFinish = onFinish;
    _onSkip = onSkip;
  }

  /// Identifiers of the most recently presented segment.
  List<String> get lastStep => steps.last;

  /// Walks to the end of the current segment.
  void finish() => _onFinish!();

  /// Taps the Skip button of the current segment.
  void skip() => _onSkip!();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('should raise the mockup flag and open the first segment', (
    tester,
  ) async {
    // Given
    final harness = await _pumpHarness(tester);

    // When
    harness.service.startFull();

    // Then
    expect(harness.container.read(tourActiveProvider), isTrue);
    await _advance(tester);
    expect(harness.presenter.lastStep, [
      'settings_instances',
      'settings_add_instance',
    ]);
  });

  testWidgets('should drop the mockup flag when the tour is skipped', (
    tester,
  ) async {
    // Given
    final harness = await _pumpHarness(tester);
    harness.service.startFull();
    await _advance(tester);

    // When
    harness.presenter.skip();
    await _advance(tester);

    // Then
    expect(harness.container.read(tourActiveProvider), isFalse);
    expect(harness.container.read(onboardingProvider).isComplete, isTrue);
    expect(harness.presenter.steps, hasLength(1));
  });

  testWidgets('should not resume a skipped tour from a stale callback', (
    tester,
  ) async {
    // Given
    final harness = await _pumpHarness(tester);
    harness.service.startFull();
    await _advance(tester);
    harness.presenter.skip();
    await _advance(tester);

    // When
    harness.presenter.finish();
    await _advance(tester);

    // Then
    expect(harness.presenter.steps, hasLength(1));
    expect(harness.container.read(tourActiveProvider), isFalse);
  });

  testWidgets('should drop the mockup flag when the tour is completed', (
    tester,
  ) async {
    // Given
    final harness = await _pumpHarness(tester);

    // When
    harness.service.startFull();
    await _walkToTheEnd(tester, harness);

    // Then
    expect(harness.container.read(tourActiveProvider), isFalse);
    expect(harness.container.read(onboardingProvider).isComplete, isTrue);
  });

  testWidgets('should cover every mocked screen before finishing', (
    tester,
  ) async {
    // Given
    final harness = await _pumpHarness(tester);

    // When
    harness.service.startFull();
    await _walkToTheEnd(tester, harness);

    // Then
    final presented = harness.presenter.steps.expand((step) => step).toList();
    expect(presented, [
      'settings_instances',
      'settings_add_instance',
      'instance_type',
      'instance_name',
      'instance_url',
      'instance_api_key',
      'instance_test',
      'instance_save',
      'movies_library',
      'movies_search',
      'movies_sort',
      'series_library',
      'calendar',
      'calendar_events',
      'activity_tabs',
      'activity_queue',
      'activity_torrents',
      'nav_bar',
    ]);
  });

  testWidgets('should drop a step whose target is not on screen', (
    tester,
  ) async {
    // Given
    final keys = AppTourKeys();
    final harness = await _pumpHarness(
      tester,
      keys: keys,
      unmounted: {keys.moviesLibraryKey},
    );

    // When
    harness.service.startFull();
    await _advanceTo(tester, harness, segment: 3);

    // Then
    expect(harness.presenter.lastStep, ['movies_search', 'movies_sort']);
  });

  testWidgets('should skip a segment with no target on screen', (tester) async {
    // Given
    final keys = AppTourKeys();
    final harness = await _pumpHarness(
      tester,
      keys: keys,
      unmounted: {keys.seriesLibraryKey},
    );

    // When
    harness.service.startFull();
    await _advanceTo(tester, harness, segment: 4);

    // Then the series segment handed over to the calendar instead of showing
    // an overlay with nothing to highlight.
    expect(harness.presenter.lastStep, ['calendar', 'calendar_events']);
  });

  testWidgets('should open the torrents tab before its step', (tester) async {
    // Given
    final harness = await _pumpHarness(tester);
    final controller = DefaultTabController.of(
      tester.element(find.byType(TabBar)),
    );
    expect(controller.index, 0);

    // When
    harness.service.startFull();
    await _advanceTo(tester, harness, segment: 7);

    // Then
    expect(harness.presenter.lastStep, ['activity_torrents']);
    expect(controller.index, 2);
  });
}

/// Wiring shared by the tests: the service under test, the container holding
/// its providers, and the presenter standing in for the coach mark.
class _Harness {
  final AppTourService service;
  final ProviderContainer container;
  final _RecordingPresenter presenter;

  const _Harness(this.service, this.container, this.presenter);
}

/// Mounts every tour target and returns the service driving them.
///
/// Keys listed in [unmounted] are left off the tree so the service sees them
/// as missing targets. The key timeout is zeroed because a missing key would
/// otherwise hold the segment for three seconds.
Future<_Harness> _pumpHarness(
  WidgetTester tester, {
  AppTourKeys? keys,
  Set<GlobalKey> unmounted = const {},
}) async {
  final tourKeys = keys ?? AppTourKeys();
  final presenter = _RecordingPresenter();
  final container = ProviderContainer(
    overrides: [
      appTourKeysProvider.overrideWithValue(tourKeys),
      appTourServiceProvider.overrideWith(
        (ref) => AppTourService(
          ref,
          tourKeys,
          presenter: presenter.call,
          keyTimeout: Duration.zero,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  Widget target(GlobalKey key) => unmounted.contains(key)
      ? const SizedBox(width: 8, height: 8)
      : SizedBox(key: key, width: 8, height: 8);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              target(tourKeys.settingsInstancesHeaderKey),
              target(tourKeys.settingsAddInstanceKey),
              target(tourKeys.instanceTypeSelectorKey),
              target(tourKeys.instanceNameFieldKey),
              target(tourKeys.instanceUrlFieldKey),
              target(tourKeys.instanceApiKeyFieldKey),
              target(tourKeys.instanceTestConnectionKey),
              target(tourKeys.instanceSaveKey),
              target(tourKeys.moviesSearchKey),
              target(tourKeys.moviesSortKey),
              target(tourKeys.moviesLibraryKey),
              target(tourKeys.seriesLibraryKey),
              target(tourKeys.calendarTitleKey),
              target(tourKeys.calendarListKey),
              target(tourKeys.activityQueueKey),
              target(tourKeys.activityTorrentKey),
              target(tourKeys.navBarKey),
              SizedBox(
                height: 48,
                child: TabBar(
                  key: tourKeys.activityTabBarKey,
                  tabs: [
                    const Tab(text: 'Queue'),
                    const Tab(text: 'History'),
                    Tab(key: tourKeys.activityTorrentsTabKey, text: 'Torrents'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  return _Harness(container.read(appTourServiceProvider), container, presenter);
}

/// Lets the pending segment settle, including the torrents tab transition.
Future<void> _advance(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(kTabScrollDuration);
  await tester.pumpAndSettle();
}

/// Walks the tour until [segment] segments have been presented.
Future<void> _advanceTo(
  WidgetTester tester,
  _Harness harness, {
  required int segment,
}) async {
  await _advance(tester);
  while (harness.presenter.steps.length < segment) {
    harness.presenter.finish();
    await _advance(tester);
  }
}

/// Walks every remaining segment until the tour stops presenting steps.
Future<void> _walkToTheEnd(WidgetTester tester, _Harness harness) async {
  await _advance(tester);
  var presented = harness.presenter.steps.length;
  while (true) {
    harness.presenter.finish();
    await _advance(tester);
    if (harness.presenter.steps.length == presented) return;
    presented = harness.presenter.steps.length;
  }
}
