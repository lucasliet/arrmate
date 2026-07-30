import 'package:arrmate/domain/models/shared/media_custom_format.dart';
import 'package:arrmate/domain/models/shared/media_language.dart';
import 'package:arrmate/domain/models/shared/release.dart';
import 'package:arrmate/domain/models/shared/release_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReleaseQuery', () {
    test('should preserve every option through JSON serialization', () {
      // Given
      const query = ReleaseQuery(
        search: 'remux',
        protocols: {'torrent'},
        indexers: {'Example Indexer'},
        qualities: {'Bluray-1080p'},
        languages: {'English'},
        customFormats: {'HDR'},
        approval: ReleaseApprovalFilter.approved,
        freeleech: ReleaseFreeleechFilter.only,
        releaseType: ReleaseTypeFilter.seasonPacks,
        originalLanguageOnly: true,
        sortOption: ReleaseSortOption.qualityWeight,
        sortAscending: true,
      );

      // When
      final restored = ReleaseQuery.fromJson(query.toJson());

      // Then
      expect(restored, query);
    });

    test('should combine all selected filters', () {
      // Given
      final matching = _release(
        title: 'Example.S01.1080p.REMUX',
        protocol: 'torrent',
        indexer: 'Private Tracker',
        language: 'English',
        customFormat: 'HDR',
        fullSeason: true,
        freeleech: true,
      );
      final nonMatching = _release(
        title: 'Example.S01.720p',
        protocol: 'usenet',
        indexer: 'Public Indexer',
        language: 'Spanish',
        customFormat: 'None',
      );
      const query = ReleaseQuery(
        search: 'remux',
        protocols: {'torrent'},
        indexers: {'Private Tracker'},
        qualities: {'Bluray-1080p'},
        languages: {'English'},
        customFormats: {'HDR'},
        approval: ReleaseApprovalFilter.approved,
        freeleech: ReleaseFreeleechFilter.only,
        releaseType: ReleaseTypeFilter.seasonPacks,
        originalLanguageOnly: true,
      );

      // When
      final results = applyReleaseQuery(
        [nonMatching, matching],
        query,
        originalLanguage: 'English',
      );

      // Then
      expect(results, [matching]);
    });

    test(
      'should sort separate score fields and keep rejected releases last',
      () {
        // Given
        final lower = _release(
          title: 'Lower',
          releaseWeight: 10,
          qualityWeight: 30,
          customFormatScore: 50,
        );
        final higher = _release(
          title: 'Higher',
          releaseWeight: 20,
          qualityWeight: 10,
          customFormatScore: 5,
        );
        final rejected = _release(
          title: 'Rejected',
          releaseWeight: 100,
          rejected: true,
        );

        // When
        final byReleaseWeight = applyReleaseQuery([
          lower,
          rejected,
          higher,
        ], const ReleaseQuery(sortOption: ReleaseSortOption.releaseWeight));
        final byQualityWeight = applyReleaseQuery([
          lower,
          higher,
        ], const ReleaseQuery(sortOption: ReleaseSortOption.qualityWeight));
        final byCustomFormatScore = applyReleaseQuery([
          lower,
          higher,
        ], const ReleaseQuery(sortOption: ReleaseSortOption.customFormatScore));

        // Then
        expect(byReleaseWeight, [higher, lower, rejected]);
        expect(byQualityWeight, [lower, higher]);
        expect(byCustomFormatScore, [lower, higher]);
      },
    );
  });
}

Release _release({
  required String title,
  String protocol = 'torrent',
  String indexer = 'Example Indexer',
  String language = 'English',
  String customFormat = 'HDR',
  bool fullSeason = false,
  bool freeleech = false,
  bool rejected = false,
  int releaseWeight = 0,
  int qualityWeight = 0,
  int customFormatScore = 0,
}) {
  return Release(
    guid: title,
    title: title,
    size: 1024,
    link: '',
    indexer: indexer,
    indexerId: '1',
    protocol: protocol,
    rejected: rejected,
    age: 1,
    indexerFlags: freeleech ? const ['Freeleech'] : const [],
    releaseWeight: releaseWeight,
    qualityWeight: qualityWeight,
    customFormatScore: customFormatScore,
    fullSeason: fullSeason,
    languages: [MediaLanguage(id: 1, name: language)],
    customFormats: [MediaCustomFormat(id: 1, name: customFormat)],
    quality: const ReleaseQuality(
      quality: ReleaseQualityItem(id: 1, name: 'Bluray-1080p'),
      revision: ReleaseQualityRevision(),
    ),
  );
}
