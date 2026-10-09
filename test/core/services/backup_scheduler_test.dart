import 'package:arrmate/core/services/backup_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BackupScheduler scheduler;

  setUp(() {
    scheduler = BackupScheduler(debounce: const Duration(milliseconds: 10));
  });

  tearDown(() {
    scheduler.cancel();
  });

  group('BackupScheduler', () {
    test('shouldRunAction_afterDebounceWindowElapses', () async {
      // Given
      var runs = 0;

      // When
      scheduler.schedule(() => runs++);
      expect(scheduler.isScheduled, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Then
      expect(runs, 1);
      expect(scheduler.isScheduled, isFalse);
    });

    test(
      'shouldRunActionOnlyOnce_whenRescheduledBeforeWindowElapses',
      () async {
        // Given
        var runs = 0;

        // When
        scheduler.schedule(() => runs++);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        scheduler.schedule(() => runs++);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Then
        expect(runs, 1);
        expect(scheduler.isScheduled, isFalse);
      },
    );

    test('shouldNotRunAction_whenCancelledBeforeWindowElapses', () async {
      // Given
      var runs = 0;
      scheduler.schedule(() => runs++);

      // When
      scheduler.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Then
      expect(runs, 0);
      expect(scheduler.isScheduled, isFalse);
    });
  });
}
