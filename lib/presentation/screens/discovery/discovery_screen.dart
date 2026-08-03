import 'package:flutter/material.dart';

import '../movies/movie_add_sheet.dart';
import '../series/series_add_sheet.dart';

/// Discovery screen for searching and adding the requested media type.
class DiscoveryScreen extends StatelessWidget {
  final String initialType;
  final String? initialQuery;

  /// Creates the discovery screen with an optional initial media type and query.
  const DiscoveryScreen({
    super.key,
    this.initialType = 'movie',
    this.initialQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: initialType == 'series'
          ? SeriesAddSheet(embedded: true, initialQuery: initialQuery)
          : MovieAddSheet(embedded: true, initialQuery: initialQuery),
    );
  }
}
