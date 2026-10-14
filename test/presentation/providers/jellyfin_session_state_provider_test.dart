import 'package:arrmate/presentation/providers/jellyfin_session_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('jellyfinSessionExpiredProvider', () {
    test('starts with no expired instances', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      final expired = container.read(jellyfinSessionExpiredProvider);

      // Then
      expect(expired, isEmpty);
      expect(
        container
            .read(jellyfinSessionExpiredProvider.notifier)
            .isExpired('jellyfin-home'),
        isFalse,
      );
    });

    test('markExpired flags only the given instance', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(jellyfinSessionExpiredProvider.notifier);

      // When
      notifier.markExpired('jellyfin-home');
      notifier.markExpired('jellyfin-home');

      // Then
      expect(container.read(jellyfinSessionExpiredProvider), {
        'jellyfin-home',
      });
      expect(notifier.isExpired('jellyfin-home'), isTrue);
      expect(notifier.isExpired('jellyfin-other'), isFalse);
    });

    test('clear forgets only the given instance', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(jellyfinSessionExpiredProvider.notifier)
        ..markExpired('jellyfin-home')
        ..markExpired('jellyfin-other');

      // When
      notifier.clear('jellyfin-home');
      notifier.clear('unknown-instance');

      // Then
      expect(container.read(jellyfinSessionExpiredProvider), {
        'jellyfin-other',
      });
      expect(notifier.isExpired('jellyfin-home'), isFalse);
    });
  });
}
