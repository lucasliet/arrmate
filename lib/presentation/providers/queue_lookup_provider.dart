import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/activity/providers/activity_provider.dart';

/// Lookup that exposes the set of movie and series identifiers that currently
/// have an active queue item, derived from the aggregated [queueProvider].
///
/// Identifiers are the Arr internal ids: [QueueItem.movieId] maps to
/// [Movie.guid] and [QueueItem.seriesId] maps to [Series.id].
class QueueMediaLookup {
  final Set<int> movieIds;
  final Set<int> seriesIds;

  const QueueMediaLookup({this.movieIds = const {}, this.seriesIds = const {}});

  bool hasMovie(int? movieId) => movieId != null && movieIds.contains(movieId);

  bool hasSeries(int? seriesId) =>
      seriesId != null && seriesIds.contains(seriesId);
}

final queueMediaLookupProvider = Provider<AsyncValue<QueueMediaLookup>>((ref) {
  final queueAsync = ref.watch(queueProvider);
  return queueAsync.whenData((items) {
    final movieIds = <int>{};
    final seriesIds = <int>{};
    for (final item in items) {
      final movieId = item.movieId ?? item.movie?.guid;
      if (movieId != null) {
        movieIds.add(movieId);
        continue;
      }
      final seriesId = item.seriesId ?? item.series?.id;
      if (seriesId != null) {
        seriesIds.add(seriesId);
      }
    }
    return QueueMediaLookup(movieIds: movieIds, seriesIds: seriesIds);
  });
});
