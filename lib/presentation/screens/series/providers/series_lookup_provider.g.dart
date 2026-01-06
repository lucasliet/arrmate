// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series_lookup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$seriesLookupHash() => r'3da3498ef1603f530a0ee2deff6d495a166ed048';

/// Notifier for looking up series from an external provider (TVDB via Sonarr).
///
/// Copied from [SeriesLookup].
@ProviderFor(SeriesLookup)
final seriesLookupProvider =
    AutoDisposeAsyncNotifierProvider<SeriesLookup, List<Series>>.internal(
      SeriesLookup.new,
      name: r'seriesLookupProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$seriesLookupHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SeriesLookup = AutoDisposeAsyncNotifier<List<Series>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
