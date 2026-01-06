// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$episodeHistoryHash() => r'8e83e60259e1eefd06b6f43369d63422a2d1174c';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [episodeHistory].
@ProviderFor(episodeHistory)
const episodeHistoryProvider = EpisodeHistoryFamily();

/// See also [episodeHistory].
class EpisodeHistoryFamily extends Family<AsyncValue<List<HistoryEvent>>> {
  /// See also [episodeHistory].
  const EpisodeHistoryFamily();

  /// See also [episodeHistory].
  EpisodeHistoryProvider call(int episodeId) {
    return EpisodeHistoryProvider(episodeId);
  }

  @override
  EpisodeHistoryProvider getProviderOverride(
    covariant EpisodeHistoryProvider provider,
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
  String? get name => r'episodeHistoryProvider';
}

/// See also [episodeHistory].
class EpisodeHistoryProvider
    extends AutoDisposeFutureProvider<List<HistoryEvent>> {
  /// See also [episodeHistory].
  EpisodeHistoryProvider(int episodeId)
    : this._internal(
        (ref) => episodeHistory(ref as EpisodeHistoryRef, episodeId),
        from: episodeHistoryProvider,
        name: r'episodeHistoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$episodeHistoryHash,
        dependencies: EpisodeHistoryFamily._dependencies,
        allTransitiveDependencies:
            EpisodeHistoryFamily._allTransitiveDependencies,
        episodeId: episodeId,
      );

  EpisodeHistoryProvider._internal(
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
    FutureOr<List<HistoryEvent>> Function(EpisodeHistoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EpisodeHistoryProvider._internal(
        (ref) => create(ref as EpisodeHistoryRef),
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
  AutoDisposeFutureProviderElement<List<HistoryEvent>> createElement() {
    return _EpisodeHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EpisodeHistoryProvider && other.episodeId == episodeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, episodeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EpisodeHistoryRef on AutoDisposeFutureProviderRef<List<HistoryEvent>> {
  /// The parameter `episodeId` of this provider.
  int get episodeId;
}

class _EpisodeHistoryProviderElement
    extends AutoDisposeFutureProviderElement<List<HistoryEvent>>
    with EpisodeHistoryRef {
  _EpisodeHistoryProviderElement(super.provider);

  @override
  int get episodeId => (origin as EpisodeHistoryProvider).episodeId;
}

String _$episodeFileHash() => r'25613461fa7e72dc2eea21459164f3abd68b07ae';

/// See also [episodeFile].
@ProviderFor(episodeFile)
const episodeFileProvider = EpisodeFileFamily();

/// See also [episodeFile].
class EpisodeFileFamily extends Family<AsyncValue<MediaFile>> {
  /// See also [episodeFile].
  const EpisodeFileFamily();

  /// See also [episodeFile].
  EpisodeFileProvider call(int fileId) {
    return EpisodeFileProvider(fileId);
  }

  @override
  EpisodeFileProvider getProviderOverride(
    covariant EpisodeFileProvider provider,
  ) {
    return call(provider.fileId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'episodeFileProvider';
}

/// See also [episodeFile].
class EpisodeFileProvider extends AutoDisposeFutureProvider<MediaFile> {
  /// See also [episodeFile].
  EpisodeFileProvider(int fileId)
    : this._internal(
        (ref) => episodeFile(ref as EpisodeFileRef, fileId),
        from: episodeFileProvider,
        name: r'episodeFileProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$episodeFileHash,
        dependencies: EpisodeFileFamily._dependencies,
        allTransitiveDependencies: EpisodeFileFamily._allTransitiveDependencies,
        fileId: fileId,
      );

  EpisodeFileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.fileId,
  }) : super.internal();

  final int fileId;

  @override
  Override overrideWith(
    FutureOr<MediaFile> Function(EpisodeFileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EpisodeFileProvider._internal(
        (ref) => create(ref as EpisodeFileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        fileId: fileId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<MediaFile> createElement() {
    return _EpisodeFileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EpisodeFileProvider && other.fileId == fileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, fileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EpisodeFileRef on AutoDisposeFutureProviderRef<MediaFile> {
  /// The parameter `fileId` of this provider.
  int get fileId;
}

class _EpisodeFileProviderElement
    extends AutoDisposeFutureProviderElement<MediaFile>
    with EpisodeFileRef {
  _EpisodeFileProviderElement(super.provider);

  @override
  int get fileId => (origin as EpisodeFileProvider).fileId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
