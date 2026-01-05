// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_episodes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$seasonEpisodesHash() => r'8b8a8db29d2ea8a1617c5a0aeb40b71392a14414';

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

/// See also [seasonEpisodes].
@ProviderFor(seasonEpisodes)
const seasonEpisodesProvider = SeasonEpisodesFamily();

/// See also [seasonEpisodes].
class SeasonEpisodesFamily extends Family<AsyncValue<List<Episode>>> {
  /// See also [seasonEpisodes].
  const SeasonEpisodesFamily();

  /// See also [seasonEpisodes].
  SeasonEpisodesProvider call(int seriesId, int seasonNumber) {
    return SeasonEpisodesProvider(seriesId, seasonNumber);
  }

  @override
  SeasonEpisodesProvider getProviderOverride(
    covariant SeasonEpisodesProvider provider,
  ) {
    return call(provider.seriesId, provider.seasonNumber);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'seasonEpisodesProvider';
}

/// See also [seasonEpisodes].
class SeasonEpisodesProvider extends AutoDisposeFutureProvider<List<Episode>> {
  /// See also [seasonEpisodes].
  SeasonEpisodesProvider(int seriesId, int seasonNumber)
    : this._internal(
        (ref) =>
            seasonEpisodes(ref as SeasonEpisodesRef, seriesId, seasonNumber),
        from: seasonEpisodesProvider,
        name: r'seasonEpisodesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$seasonEpisodesHash,
        dependencies: SeasonEpisodesFamily._dependencies,
        allTransitiveDependencies:
            SeasonEpisodesFamily._allTransitiveDependencies,
        seriesId: seriesId,
        seasonNumber: seasonNumber,
      );

  SeasonEpisodesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.seriesId,
    required this.seasonNumber,
  }) : super.internal();

  final int seriesId;
  final int seasonNumber;

  @override
  Override overrideWith(
    FutureOr<List<Episode>> Function(SeasonEpisodesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SeasonEpisodesProvider._internal(
        (ref) => create(ref as SeasonEpisodesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        seriesId: seriesId,
        seasonNumber: seasonNumber,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Episode>> createElement() {
    return _SeasonEpisodesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SeasonEpisodesProvider &&
        other.seriesId == seriesId &&
        other.seasonNumber == seasonNumber;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, seriesId.hashCode);
    hash = _SystemHash.combine(hash, seasonNumber.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
mixin SeasonEpisodesRef on AutoDisposeFutureProviderRef<List<Episode>> {
  /// The parameter `seriesId` of this provider.
  int get seriesId;

  /// The parameter `seasonNumber` of this provider.
  int get seasonNumber;
}

class _SeasonEpisodesProviderElement
    extends AutoDisposeFutureProviderElement<List<Episode>>
    with SeasonEpisodesRef {
  _SeasonEpisodesProviderElement(super.provider);

  @override
  int get seriesId => (origin as SeasonEpisodesProvider).seriesId;
  @override
  int get seasonNumber => (origin as SeasonEpisodesProvider).seasonNumber;
}
