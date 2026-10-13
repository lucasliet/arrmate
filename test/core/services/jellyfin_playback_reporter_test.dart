import 'package:arrmate/core/services/jellyfin_playback_reporter.dart';
import 'package:arrmate/data/api/jellyfin_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockJellyfinService extends Mock implements JellyfinService {}

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  group('JellyfinPlaybackReporter', () {
    test(
      'onStart reports an unpaused Progress tick (no Start endpoint)',
      () async {
        // Given
        final service = MockJellyfinService();
        when(
          () => service.reportPlaybackProgress(
            itemId: any(named: 'itemId'),
            mediaSourceId: any(named: 'mediaSourceId'),
            position: any(named: 'position'),
            isPaused: any(named: 'isPaused'),
          ),
        ).thenAnswer((_) async {});
        final reporter = JellyfinPlaybackReporter(
          service,
          itemId: 'item-1',
          mediaSourceId: 'src-1',
        );

        // When
        await reporter.onStart(const Duration(seconds: 90));

        // Then
        // `/Sessions/Playing/Start` 404s on Jellyfin 12, so the opening
        // position travels as Progress; Progress upserts the session on old
        // and new servers alike.
        verify(
          () => service.reportPlaybackProgress(
            itemId: 'item-1',
            mediaSourceId: 'src-1',
            position: const Duration(seconds: 90),
            isPaused: false,
          ),
        ).called(1);
      },
    );
  });
}
