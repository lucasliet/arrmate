// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'releases_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$movieReleasesHash() => r'e160a1fbbe9fe84fb55dc2a6ba37f03ea44c03aa';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Fetches current releases (search results) for a movie.
///
/// Copied from [movieReleases].
@ProviderFor(movieReleases)
const movieReleasesProvider = MovieReleasesFamily();

/// Fetches current releases (search results) for a movie.
///
/// Copied from [movieReleases].
class MovieReleasesFamily extends Family<AsyncValue<List<Release>>> {
  /// Fetches current releases (search results) for a movie.
  ///
  /// Copied from [movieReleases].
  const MovieReleasesFamily();

  /// Fetches current releases (search results) for a movie.
  ///
  /// Copied from [movieReleases].
  MovieReleasesProvider call(int movieId) {
    return MovieReleasesProvider(movieId);
  }

  @override
  MovieReleasesProvider getProviderOverride(
    covariant MovieReleasesProvider provider,
  ) {
    return call(provider.movieId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'movieReleasesProvider';
}

/// Fetches current releases (search results) for a movie.
///
/// Copied from [movieReleases].
class MovieReleasesProvider extends AutoDisposeFutureProvider<List<Release>> {
  /// Fetches current releases (search results) for a movie.
  ///
  /// Copied from [movieReleases].
  MovieReleasesProvider(int movieId)
    : this._internal(
        (ref) => movieReleases(ref as MovieReleasesRef, movieId),
        from: movieReleasesProvider,
        name: r'movieReleasesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$movieReleasesHash,
        dependencies: MovieReleasesFamily._dependencies,
        allTransitiveDependencies:
            MovieReleasesFamily._allTransitiveDependencies,
        movieId: movieId,
      );

  MovieReleasesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.movieId,
  }) : super.internal();

  final int movieId;

  @override
  Override overrideWith(
    FutureOr<List<Release>> Function(MovieReleasesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MovieReleasesProvider._internal(
        (ref) => create(ref as MovieReleasesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        movieId: movieId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Release>> createElement() {
    return _MovieReleasesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MovieReleasesProvider && other.movieId == movieId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, movieId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
mixin MovieReleasesRef on AutoDisposeFutureProviderRef<List<Release>> {
  /// The parameter `movieId` of this provider.
  int get movieId;
}

class _MovieReleasesProviderElement
    extends AutoDisposeFutureProviderElement<List<Release>>
    with MovieReleasesRef {
  _MovieReleasesProviderElement(super.provider);

  @override
  int get movieId => (origin as MovieReleasesProvider).movieId;
}

String _$episodeReleasesHash() => r'8df9aae327862f0b4854e4febdccdd8e3f108a20';

/// Fetches current releases (search results) for an episode.
///
/// Copied from [episodeReleases].
@ProviderFor(episodeReleases)
const episodeReleasesProvider = EpisodeReleasesFamily();

/// Fetches current releases (search results) for an episode.
///
/// Copied from [episodeReleases].
class EpisodeReleasesFamily extends Family<AsyncValue<List<Release>>> {
  /// Fetches current releases (search results) for an episode.
  ///
  /// Copied from [episodeReleases].
  const EpisodeReleasesFamily();

  /// Fetches current releases (search results) for an episode.
  ///
  /// Copied from [episodeReleases].
  EpisodeReleasesProvider call(int episodeId) {
    return EpisodeReleasesProvider(episodeId);
  }

  @override
  EpisodeReleasesProvider getProviderOverride(
    covariant EpisodeReleasesProvider provider,
  ) {
    return call(provider.episodeId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'episodeReleasesProvider';
}

/// Fetches current releases (search results) for an episode.
///
/// Copied from [episodeReleases].
class EpisodeReleasesProvider extends AutoDisposeFutureProvider<List<Release>> {
  /// Fetches current releases (search results) for an episode.
  ///
  /// Copied from [episodeReleases].
  EpisodeReleasesProvider(int episodeId)
    : this._internal(
        (ref) => episodeReleases(ref as EpisodeReleasesRef, episodeId),
        from: episodeReleasesProvider,
        name: r'episodeReleasesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$episodeReleasesHash,
        dependencies: EpisodeReleasesFamily._dependencies,
        allTransitiveDependencies:
            EpisodeReleasesFamily._allTransitiveDependencies,
        episodeId: episodeId,
      );

  EpisodeReleasesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.episodeId,
  }) : super.internal();

  final int episodeId;

  @override
  Override overrideWith(
    FutureOr<List<Release>> Function(EpisodeReleasesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EpisodeReleasesProvider._internal(
        (ref) => create(ref as EpisodeReleasesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        episodeId: episodeId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Release>> createElement() {
    return _EpisodeReleasesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EpisodeReleasesProvider && other.episodeId == episodeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, episodeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
mixin EpisodeReleasesRef on AutoDisposeFutureProviderRef<List<Release>> {
  /// The parameter `episodeId` of this provider.
  int get episodeId;
}

class _EpisodeReleasesProviderElement
    extends AutoDisposeFutureProviderElement<List<Release>>
    with EpisodeReleasesRef {
  _EpisodeReleasesProviderElement(super.provider);

  @override
  int get episodeId => (origin as EpisodeReleasesProvider).episodeId;
}

String _$releaseActionsHash() => r'63270c2b784eae59f0e5918d1e5e0fcb606b4fa8';

/// Controller for handling release actions like downloading.
///
/// Copied from [ReleaseActions].
@ProviderFor(ReleaseActions)
final releaseActionsProvider =
    AutoDisposeNotifierProvider<ReleaseActions, void>.internal(
      ReleaseActions.new,
      name: r'releaseActionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$releaseActionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReleaseActions = AutoDisposeNotifier<void>;
