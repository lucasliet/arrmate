import 'package:equatable/equatable.dart';

/// Represents a single peer connected to a torrent in qBittorrent.
class TorrentPeer extends Equatable {
  /// The peer IP address (used as the map key in the API response).
  final String ip;

  /// The peer port.
  final int port;

  /// The connection type (e.g. "BT").
  final String connection;

  /// The ISO 3166-1 alpha-2 country code (e.g. "BR").
  final String? countryCode;

  /// The resolved country name.
  final String? country;

  /// The client software name reported by the peer.
  final String? client;

  /// The client software version reported by the peer.
  final String? clientVersion;

  /// The qBittorrent connection flags (e.g. "D", "U").
  final String? flags;

  /// The peer's download progress for this torrent (0.0 to 1.0).
  final double progress;

  /// The download speed from this peer, in bytes/s.
  final int dlSpeed;

  /// The upload speed to this peer, in bytes/s.
  final int upSpeed;

  /// Total bytes downloaded from this peer.
  final int downloaded;

  /// Total bytes uploaded to this peer.
  final int uploaded;

  /// The peer relevance (0.0 to 1.0).
  final double relevance;

  const TorrentPeer({
    required this.ip,
    required this.port,
    required this.connection,
    required this.progress,
    required this.dlSpeed,
    required this.upSpeed,
    required this.downloaded,
    required this.uploaded,
    required this.relevance,
    this.countryCode,
    this.country,
    this.client,
    this.clientVersion,
    this.flags,
  });

  /// Whether this peer is actively downloading from us.
  bool get isUploading => upSpeed > 0;

  /// Whether we are actively downloading from this peer.
  bool get isDownloading => dlSpeed > 0;

  /// Builds the "ip:port" identifier.
  String get address => '$ip:$port';

  /// Creates a [TorrentPeer] from a JSON map.
  ///
  /// [ip] is passed externally because it is the key of the peers map in the
  /// qBittorrent `/sync/torrentPeers` response rather than a nested field.
  factory TorrentPeer.fromJson(Map<String, dynamic> json, String ip) {
    return TorrentPeer(
      ip: ip,
      port: json['port'] as int? ?? 0,
      connection: json['connection'] as String? ?? '',
      progress: (json['progress'] as num? ?? 0).toDouble(),
      dlSpeed: json['dl_speed'] as int? ?? 0,
      upSpeed: json['up_speed'] as int? ?? 0,
      downloaded: json['downloaded'] as int? ?? 0,
      uploaded: json['uploaded'] as int? ?? 0,
      relevance: (json['relevance'] as num? ?? 0).toDouble(),
      countryCode: json['country_code'] as String?,
      country: json['country'] as String?,
      client: json['client'] as String?,
      clientVersion: json['client_version'] as String?,
      flags: json['flags'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    ip,
    port,
    connection,
    countryCode,
    country,
    client,
    clientVersion,
    flags,
    progress,
    dlSpeed,
    upSpeed,
    downloaded,
    uploaded,
    relevance,
  ];
}
