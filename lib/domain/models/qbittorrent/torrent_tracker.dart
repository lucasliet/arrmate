import 'package:equatable/equatable.dart';

/// Status reported by qBittorrent for one tracker of a torrent.
///
/// Codes match `GET /api/v2/torrents/trackers`.
enum TorrentTrackerStatus {
  /// Tracker is disabled. qBittorrent uses this for DHT, PeX, and LSD.
  disabled(0, 'Disabled'),

  /// Tracker has not been contacted yet.
  notContacted(1, 'Not contacted'),

  /// Tracker has been contacted and is working.
  working(2, 'Working'),

  /// Tracker is being updated.
  updating(3, 'Updating'),

  /// Tracker was contacted but is not working.
  notWorking(4, 'Not working'),

  /// Status code the app does not recognize.
  unknown(-1, 'Unknown');

  /// Numeric status code returned by the qBittorrent API.
  final int code;

  /// Short label shown in the trackers sheet.
  final String label;

  const TorrentTrackerStatus(this.code, this.label);

  /// Maps a qBittorrent status code to a [TorrentTrackerStatus].
  static TorrentTrackerStatus fromCode(int? code) {
    for (final status in TorrentTrackerStatus.values) {
      if (status.code == code) return status;
    }
    return TorrentTrackerStatus.unknown;
  }
}

/// One tracker entry from `GET /api/v2/torrents/trackers`.
///
/// The list includes real announce URLs and the special DHT, PeX, and LSD rows
/// qBittorrent reports with the same payload.
class TorrentTracker extends Equatable {
  /// Announce URL, or a special marker such as `** [DHT] **`.
  final String url;

  /// Last known contact status.
  final TorrentTrackerStatus status;

  /// Announce tier. Lower tiers are tried first.
  final int tier;

  /// Peers reported by this tracker.
  final int numPeers;

  /// Seeds reported by this tracker.
  final int numSeeds;

  /// Leechers reported by this tracker.
  final int numLeeches;

  /// Times this torrent was downloaded through this tracker.
  final int numDownloaded;

  /// Tracker message, usually an error when the tracker is not working.
  final String message;

  const TorrentTracker({
    required this.url,
    required this.status,
    required this.tier,
    required this.numPeers,
    required this.numSeeds,
    required this.numLeeches,
    required this.numDownloaded,
    this.message = '',
  });

  /// Whether this row is DHT, PeX, or LSD rather than an announce URL.
  bool get isSpecial {
    final trimmed = url.trim();
    return trimmed == '** [DHT] **' ||
        trimmed == '** [PeX] **' ||
        trimmed == '** [LSD] **';
  }

  /// Host of an announce URL, or the short name of a special row.
  String get displayName {
    if (isSpecial) {
      return url.replaceAll(RegExp(r'[^A-Za-z]'), '');
    }
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host.isNotEmpty) return uri.host;
    return url;
  }

  /// Working announce trackers come first; DHT, PeX, and LSD come last.
  int get listOrder {
    if (isSpecial) return 10;
    switch (status) {
      case TorrentTrackerStatus.working:
        return 0;
      case TorrentTrackerStatus.updating:
        return 1;
      case TorrentTrackerStatus.notContacted:
        return 2;
      case TorrentTrackerStatus.notWorking:
        return 3;
      case TorrentTrackerStatus.disabled:
        return 4;
      case TorrentTrackerStatus.unknown:
        return 5;
    }
  }

  /// Orders trackers for the details sheet: status, then tier, then name.
  static int compare(TorrentTracker a, TorrentTracker b) {
    final order = a.listOrder.compareTo(b.listOrder);
    if (order != 0) return order;
    final tierOrder = a.tier.compareTo(b.tier);
    if (tierOrder != 0) return tierOrder;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  }

  /// Creates a [TorrentTracker] from a qBittorrent trackers JSON object.
  factory TorrentTracker.fromJson(Map<String, dynamic> json) {
    return TorrentTracker(
      url: json['url'] as String? ?? '',
      status: TorrentTrackerStatus.fromCode(_asInt(json['status'])),
      tier: _asInt(json['tier']),
      numPeers: _asInt(json['num_peers']),
      numSeeds: _asInt(json['num_seeds']),
      numLeeches: _asInt(json['num_leeches']),
      numDownloaded: _asInt(json['num_downloaded']),
      message: json['msg'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    url,
    status,
    tier,
    numPeers,
    numSeeds,
    numLeeches,
    numDownloaded,
    message,
  ];

  /// Describes the tracker by host only.
  ///
  /// Announce URLs usually carry a private passkey, so the default
  /// [Equatable] output, which prints every prop, must not reach the logs.
  @override
  String toString() =>
      'TorrentTracker($displayName, ${status.label}, tier: $tier)';
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}
