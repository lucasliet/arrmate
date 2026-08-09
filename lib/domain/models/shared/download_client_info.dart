import 'package:equatable/equatable.dart';

/// A download client configured in Radarr/Sonarr.
///
/// Only the pieces needed to recognize which download-client categories are
/// managed by the *arr instance are modelled; the full settings payload is
/// intentionally ignored.
class DownloadClientInfo extends Equatable {
  /// Identifier of the download client in Radarr/Sonarr.
  final int id;

  /// User-defined name of the download client.
  final String name;

  /// Implementation key (e.g. `QBittorrent`, `Transmission`).
  final String implementation;

  /// Whether the client is enabled.
  final bool enable;

  /// Protocol handled by the client (`torrent` or `usenet`).
  final String? protocol;

  /// Categories the *arr instance assigns to the downloads it sends to this
  /// client (Radarr's `movieCategory`, Sonarr's `tvCategory`, and the matching
  /// "imported" variants).
  final List<String> categories;

  const DownloadClientInfo({
    required this.id,
    required this.name,
    required this.implementation,
    required this.enable,
    this.protocol,
    this.categories = const [],
  });

  /// Whether this client points at qBittorrent.
  bool get isQBittorrent => implementation.toLowerCase() == 'qbittorrent';

  factory DownloadClientInfo.fromJson(Map<String, dynamic> json) {
    return DownloadClientInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      implementation: json['implementation'] as String? ?? '',
      enable: json['enable'] as bool? ?? false,
      protocol: json['protocol'] as String?,
      categories: _parseCategories(json['fields'] as List<dynamic>?),
    );
  }

  /// Extracts every non-empty value from settings fields whose name ends with
  /// `Category`.
  ///
  /// Matching by suffix keeps Radarr (`movieCategory`) and Sonarr
  /// (`tvCategory`) working without hardcoding either name.
  static List<String> _parseCategories(List<dynamic>? fields) {
    if (fields == null) return const [];
    final categories = <String>[];
    for (final field in fields) {
      if (field is! Map<String, dynamic>) continue;
      final name = field['name'] as String?;
      if (name == null || !name.toLowerCase().endsWith('category')) continue;
      final value = field['value'];
      if (value is! String) continue;
      final category = value.trim();
      if (category.isEmpty || categories.contains(category)) continue;
      categories.add(category);
    }
    return categories;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    implementation,
    enable,
    protocol,
    categories,
  ];
}
