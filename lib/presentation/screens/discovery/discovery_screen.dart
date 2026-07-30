import 'package:flutter/material.dart';

import '../movies/movie_add_sheet.dart';
import '../series/series_add_sheet.dart';

/// Unified discovery screen for searching and adding movies or series.
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
    final initialIndex = initialType == 'series' ? 1 : 0;
    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Discover'),
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.movie_outlined), text: 'Movies'),
              Tab(icon: Icon(Icons.tv_outlined), text: 'Series'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MovieAddSheet(embedded: true, initialQuery: initialQuery),
            SeriesAddSheet(embedded: true, initialQuery: initialQuery),
          ],
        ),
      ),
    );
  }
}
