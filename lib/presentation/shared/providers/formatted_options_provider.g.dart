// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'formatted_options_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$movieQualityProfilesHash() =>
    r'9d169371b12d92693988704753c69759cd5f1b93';

/// Fetches available quality profiles for movies (Radarr).
///
/// Copied from [movieQualityProfiles].
@ProviderFor(movieQualityProfiles)
final movieQualityProfilesProvider =
    AutoDisposeFutureProvider<List<QualityProfile>>.internal(
      movieQualityProfiles,
      name: r'movieQualityProfilesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$movieQualityProfilesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MovieQualityProfilesRef =
    AutoDisposeFutureProviderRef<List<QualityProfile>>;
String _$movieRootFoldersHash() => r'34669b943fbdf0ade8885a988a13f34a80d519c0';

/// Fetches configured root folders for movies (Radarr).
///
/// Copied from [movieRootFolders].
@ProviderFor(movieRootFolders)
final movieRootFoldersProvider =
    AutoDisposeFutureProvider<List<RootFolder>>.internal(
      movieRootFolders,
      name: r'movieRootFoldersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$movieRootFoldersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MovieRootFoldersRef = AutoDisposeFutureProviderRef<List<RootFolder>>;
String _$seriesQualityProfilesHash() =>
    r'e36a80c0448a94185a1b7c5e4c4c10971f0eec23';

/// Fetches available quality profiles for series (Sonarr).
///
/// Copied from [seriesQualityProfiles].
@ProviderFor(seriesQualityProfiles)
final seriesQualityProfilesProvider =
    AutoDisposeFutureProvider<List<QualityProfile>>.internal(
      seriesQualityProfiles,
      name: r'seriesQualityProfilesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$seriesQualityProfilesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SeriesQualityProfilesRef =
    AutoDisposeFutureProviderRef<List<QualityProfile>>;
String _$seriesRootFoldersHash() => r'd5ab4d8474d7e562e98a69bf319db2cf914a3845';

/// Fetches configured root folders for series (Sonarr).
///
/// Copied from [seriesRootFolders].
@ProviderFor(seriesRootFolders)
final seriesRootFoldersProvider =
    AutoDisposeFutureProvider<List<RootFolder>>.internal(
      seriesRootFolders,
      name: r'seriesRootFoldersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$seriesRootFoldersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SeriesRootFoldersRef = AutoDisposeFutureProviderRef<List<RootFolder>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
