import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debounces auto-backup triggers so bursts of changes upload once.
class BackupScheduler {
  /// Window that must pass without a new schedule before the action runs.
  final Duration debounce;

  Timer? _timer;

  /// Creates the scheduler, running actions [debounce] after the last trigger.
  BackupScheduler({this.debounce = const Duration(seconds: 30)});

  /// (Re)schedules [action] to run after the debounce window.
  ///
  /// A previously scheduled action that has not run yet is replaced, so a
  /// burst of triggers collapses into a single run.
  void schedule(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(debounce, action);
  }

  /// Cancels any pending action.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether an action is currently scheduled.
  bool get isScheduled => _timer?.isActive ?? false;
}

/// Exposes the app-wide [BackupScheduler] used by automatic backups.
final backupSchedulerProvider = Provider<BackupScheduler>((ref) {
  final scheduler = BackupScheduler();
  ref.onDispose(scheduler.cancel);
  return scheduler;
});
