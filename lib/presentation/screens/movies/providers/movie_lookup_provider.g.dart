// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_lookup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$movieLookupHash() => r'40ffe400e5d16cd8b9f71ed794a2da221be57f0b';

/// Notifier for looking up movies from an external provider (TMDB via Radarr).
///
/// Copied from [MovieLookup].
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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
