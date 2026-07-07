import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/logger_service.dart';

/// Provider that tracks whether the first-run guided tour has been completed.
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(() {
      return OnboardingNotifier();
    });

/// State for the onboarding tour flag.
class OnboardingState {
  /// Whether the persisted flag has finished loading from SharedPreferences.
  final bool isLoaded;

  /// Whether the onboarding tour has been completed or skipped.
  final bool isComplete;

  const OnboardingState({this.isLoaded = false, this.isComplete = false});

  OnboardingState copyWith({bool? isLoaded, bool? isComplete}) {
    return OnboardingState(
      isLoaded: isLoaded ?? this.isLoaded,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

/// Manages the persisted [kOnboardingCompleteKey] flag using SharedPreferences.
///
/// Exposes an [OnboardingState] so callers can distinguish "still loading"
/// from "loaded and not complete", preventing the tour from firing on every
/// cold start before prefs resolve.
class OnboardingNotifier extends Notifier<OnboardingState> {
  static const String kOnboardingCompleteKey = 'onboarding_complete';

  @override
  OnboardingState build() {
    _load();
    return const OnboardingState();
  }

  /// Loads the persisted onboarding flag from SharedPreferences.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = OnboardingState(
      isLoaded: true,
      isComplete: prefs.getBool(kOnboardingCompleteKey) ?? false,
    );
  }

  /// Marks the onboarding as complete and persists the flag.
  Future<void> markComplete() async {
    logger.info('[OnboardingNotifier] Marking onboarding as complete');
    state = state.copyWith(isLoaded: true, isComplete: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingCompleteKey, true);
  }
}
