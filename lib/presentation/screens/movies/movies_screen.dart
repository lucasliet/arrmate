import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/common_widgets.dart';
import 'providers/movies_provider.dart';
import 'widgets/movie_card.dart';

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesState = ref.watch(moviesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(moviesProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Movies'),
              floating: true,
              snap: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // TODO: Implement search
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search not implemented yet')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () {
                    // TODO: Implement sort
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sort not implemented yet')),
                    );
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: moviesState.when(
                data: (movies) {
                  if (movies.isEmpty) {
                    return const SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.movie_outlined,
                        title: 'No movies found',
                        subtitle: 'Add movies to your Radarr library to see them here.',
                      ),
                    );
                  }

                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 120, // Adjust for density
                      childAspectRatio: 2 / 3,
                      crossAxisSpacing: 12, // gridSpacing from constants? Use 8 or 12
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final movie = movies[index];
                        return MovieCard(
                          movie: movie,
                          onTap: () {
                            context.go('/movies/${movie.id}');
                          },
                        );
                      },
                      childCount: movies.length,
                    ),
                  );
                },
                error: (error, stack) => SliverFillRemaining(
                  child: ErrorDisplay(
                    message: error.toString(),
                    onRetry: () => ref.read(moviesProvider.notifier).refresh(),
                  ),
                ),
                loading: () => const SliverFillRemaining(
                  child: LoadingIndicator(message: 'Loading movies...'),
                ),
              ),
            ),
             // Bottom padding for navigation bar usually handled by Scaffold/SafeArea but in CustomScrollView we might want some extra
             const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
          ],
        ),
      ),
    );
  }
}
