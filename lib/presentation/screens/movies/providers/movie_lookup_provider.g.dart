// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_lookup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$movieLookupHash() => r'40ffe400e5d16cd8b9f71ed794a2da221be57f0b';

/// See also [MovieLookup].
@ProviderFor(MovieLookup)
final movieLookupProvider =
    AutoDisposeAsyncNotifierProvider<MovieLookup, List<Movie>>.internal(
      MovieLookup.new,
      name: r'movieLookupProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$movieLookupHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MovieLookup = AutoDisposeAsyncNotifier<List<Movie>>;
