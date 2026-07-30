import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/models.dart';
import '../../widgets/common_widgets.dart';
import 'providers/series_provider.dart';
import 'season_details_screen.dart';

/// Resolves a season details view from [seriesId] and [seasonNumber], loading
/// the full series data when needed. Used by calendar navigation and deep links.
class SeasonRouteScreen extends ConsumerWidget {
  final int seriesId;
  final int seasonNumber;

  const SeasonRouteScreen({
    super.key,
    required this.seriesId,
    required this.seasonNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesDetailsProvider(seriesId));

    return seriesAsync.when(
      data: (series) {
        final season = series.seasons
            .where((season) => season.seasonNumber == seasonNumber)
            .firstWhere(
              (_) => true,
              orElse: () =>
                  Season(seasonNumber: seasonNumber, monitored: false),
            );
        return SeasonDetailsScreen(series: series, season: season);
      },
      loading: () =>
          const Scaffold(body: LoadingIndicator(message: 'Loading season...')),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Season')),
        body: ErrorDisplay(
          message: 'Failed to load the season: $error',
          onRetry: () => ref.invalidate(seriesDetailsProvider(seriesId)),
        ),
      ),
    );
  }
}
