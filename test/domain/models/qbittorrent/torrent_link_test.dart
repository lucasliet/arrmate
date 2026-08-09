import 'package:arrmate/domain/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TorrentLinkStatus', () {
    test('should flag only the orphan status as critical', () {
      // Given / When / Then
      expect(TorrentLinkStatus.orphan.isCritical, isTrue);
      expect(TorrentLinkStatus.linked.isCritical, isFalse);
      expect(TorrentLinkStatus.fileMissing.isCritical, isFalse);
      expect(TorrentLinkStatus.external.isCritical, isFalse);
      expect(TorrentLinkStatus.unknown.isCritical, isFalse);
    });

    test('should resolve the orphan color from the error role', () {
      // Given
      const colorScheme = ColorScheme.light();

      // When / Then
      expect(TorrentLinkStatus.orphan.color(colorScheme), colorScheme.error);
      expect(TorrentLinkStatus.linked.color(colorScheme), colorScheme.primary);
    });
  });

  group('TorrentLink', () {
    test('should label a linked movie with its title', () {
      // Given
      const link = TorrentLink(
        status: TorrentLinkStatus.linked,
        movieId: 7,
        mediaTitle: 'Arrival',
        sourceTitle: 'Arrival.2016.1080p',
      );

      // When / Then
      expect(link.displayLabel, 'Arrival');
      expect(link.hasMedia, isTrue);
    });

    test('should label a linked episode with its series and episode code', () {
      // Given
      const link = TorrentLink(
        status: TorrentLinkStatus.linked,
        seriesId: 3,
        episodeId: 42,
        seasonNumber: 1,
        episodeNumber: 5,
        mediaTitle: 'Severance',
      );

      // When / Then
      expect(link.episodeLabel, 'S01E05');
      expect(link.displayLabel, 'Severance · S01E05');
    });

    test('should fall back to the release title when the media is unnamed', () {
      // Given
      const link = TorrentLink(
        status: TorrentLinkStatus.fileMissing,
        movieId: 9,
        sourceTitle: 'Dune.Part.Two.2024.2160p',
      );

      // When / Then
      expect(link.displayLabel, 'Dune.Part.Two.2024.2160p');
    });

    test('should use the status label when there is no media at all', () {
      // Given / When / Then
      expect(
        const TorrentLink(status: TorrentLinkStatus.orphan).displayLabel,
        'Orphan',
      );
      expect(
        const TorrentLink(status: TorrentLinkStatus.external).displayLabel,
        'Not in library',
      );
      expect(TorrentLink.unknown.status, TorrentLinkStatus.unknown);
    });

    test('should keep the media data when the status is replaced', () {
      // Given
      const link = TorrentLink(
        status: TorrentLinkStatus.fileMissing,
        instanceId: 'radarr-home',
        movieId: 7,
        mediaTitle: 'Arrival',
      );

      // When
      final relinked = link.copyWithStatus(TorrentLinkStatus.linked);

      // Then
      expect(relinked.status, TorrentLinkStatus.linked);
      expect(relinked.movieId, 7);
      expect(relinked.mediaTitle, 'Arrival');
      expect(relinked.instanceId, 'radarr-home');
    });
  });
}
