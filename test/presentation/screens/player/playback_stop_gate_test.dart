import 'dart:async';

import 'package:arrmate/presentation/screens/player/playback_stop_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaybackStopGate', () {
    const shortTimeout = Duration(milliseconds: 20);
    const testLimit = Duration(seconds: 1);

    test('settled completes immediately when nothing is armed', () async {
      // Given
      final gate = PlaybackStopGate();

      // When
      final settled = gate.settled;

      // Then
      await expectLater(settled.timeout(testLimit), completes);
    });

    test('settled waits for the tracked report', () async {
      // Given
      final gate = PlaybackStopGate();
      final report = Completer<void>();
      gate.arm();
      gate.track(report.future);
      var settled = false;
      unawaited(gate.settled.then((_) => settled = true));
      await pumpEventQueue();
      expect(settled, isFalse);

      // When
      report.complete();
      await pumpEventQueue();

      // Then
      expect(settled, isTrue);
    });

    test(
      'settled completes within the timeout when the stop report hangs',
      () async {
        // Given
        final gate = PlaybackStopGate(settleTimeout: shortTimeout);
        final hangingReport = Completer<void>();
        gate.arm();
        gate.track(hangingReport.future);

        // When
        final settled = gate.settled;

        // Then
        await expectLater(settled.timeout(testLimit), completes);
        expect(hangingReport.isCompleted, isFalse);
      },
    );

    test(
      'settled is bounded for a hanging report tracked without arming',
      () async {
        // Given
        final gate = PlaybackStopGate(settleTimeout: shortTimeout);
        final hangingReport = Completer<void>();
        gate.track(hangingReport.future);

        // When
        final settled = gate.settled;

        // Then
        await expectLater(settled.timeout(testLimit), completes);
      },
    );

    test('a new session can be armed after a timed-out one', () async {
      // Given
      final gate = PlaybackStopGate(settleTimeout: shortTimeout);
      gate.arm();
      gate.track(Completer<void>().future);
      await gate.settled.timeout(testLimit);
      final nextReport = Completer<void>();
      gate.arm();
      gate.track(nextReport.future);
      var settled = false;
      unawaited(gate.settled.then((_) => settled = true));
      await pumpEventQueue();
      expect(settled, isFalse);

      // When
      nextReport.complete();
      await pumpEventQueue();

      // Then
      expect(settled, isTrue);
    });
  });
}
