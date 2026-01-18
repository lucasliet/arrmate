// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_import_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$manualImportControllerNotifierHash() =>
    r'593c3cd8f9e93233be1000c837ac748707eba137';

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

abstract class _$ManualImportControllerNotifier
    extends BuildlessAutoDisposeAsyncNotifier<ManualImportState> {
  late final String downloadId;

  FutureOr<ManualImportState> build(String downloadId);
}

/// See also [ManualImportControllerNotifier].
@ProviderFor(ManualImportControllerNotifier)
const manualImportControllerNotifierProvider =
    ManualImportControllerNotifierFamily();

/// See also [ManualImportControllerNotifier].
class ManualImportControllerNotifierFamily
    extends Family<AsyncValue<ManualImportState>> {
  /// See also [ManualImportControllerNotifier].
  const ManualImportControllerNotifierFamily();

  /// See also [ManualImportControllerNotifier].
  ManualImportControllerNotifierProvider call(String downloadId) {
    return ManualImportControllerNotifierProvider(downloadId);
  }

  @override
  ManualImportControllerNotifierProvider getProviderOverride(
    covariant ManualImportControllerNotifierProvider provider,
  ) {
    return call(provider.downloadId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'manualImportControllerNotifierProvider';
}

/// See also [ManualImportControllerNotifier].
class ManualImportControllerNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ManualImportControllerNotifier,
          ManualImportState
        > {
  /// See also [ManualImportControllerNotifier].
  ManualImportControllerNotifierProvider(String downloadId)
    : this._internal(
        () => ManualImportControllerNotifier()..downloadId = downloadId,
        from: manualImportControllerNotifierProvider,
        name: r'manualImportControllerNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$manualImportControllerNotifierHash,
        dependencies: ManualImportControllerNotifierFamily._dependencies,
        allTransitiveDependencies:
            ManualImportControllerNotifierFamily._allTransitiveDependencies,
        downloadId: downloadId,
      );

  ManualImportControllerNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.downloadId,
  }) : super.internal();

  final String downloadId;

  @override
  FutureOr<ManualImportState> runNotifierBuild(
    covariant ManualImportControllerNotifier notifier,
  ) {
    return notifier.build(downloadId);
  }

  @override
  Override overrideWith(ManualImportControllerNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ManualImportControllerNotifierProvider._internal(
        () => create()..downloadId = downloadId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        downloadId: downloadId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    ManualImportControllerNotifier,
    ManualImportState
  >
  createElement() {
    return _ManualImportControllerNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ManualImportControllerNotifierProvider &&
        other.downloadId == downloadId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, downloadId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ManualImportControllerNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<ManualImportState> {
  /// The parameter `downloadId` of this provider.
  String get downloadId;
}

class _ManualImportControllerNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ManualImportControllerNotifier,
          ManualImportState
        >
    with ManualImportControllerNotifierRef {
  _ManualImportControllerNotifierProviderElement(super.provider);

  @override
  String get downloadId =>
      (origin as ManualImportControllerNotifierProvider).downloadId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
