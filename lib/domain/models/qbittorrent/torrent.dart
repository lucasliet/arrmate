import 'package:equatable/equatable.dart';
import 'torrent_status.dart';

class Torrent extends Equatable {
  final String hash;
  final String name;
  final int size;
  final double progress;
  final int dlspeed;
  final int upspeed;
  final int eta;
  final double ratio;
  final TorrentStatus status;
  final String state;
  final String? category;
  final List<String> tags;
  final String savePath;
  final int numSeeds;
  final int numLeechs;
  final int downloaded;
  final int uploaded;
  final int amountLeft;
  final int addedOn;

  const Torrent({
    required this.hash,
    required this.name,
    required this.size,
    required this.progress,
    required this.dlspeed,
    required this.upspeed,
    required this.eta,
    required this.ratio,
    required this.status,
    required this.state,
    this.category,
    required this.tags,
    required this.savePath,
    required this.numSeeds,
    required this.numLeechs,
    required this.downloaded,
    required this.uploaded,
    required this.amountLeft,
    required this.addedOn,
  });

  factory Torrent.fromJson(Map<String, dynamic> json) {
    return Torrent(
      hash: json['hash'] as String,
      name: json['name'] as String,
      size: json['size'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      dlspeed: json['dlspeed'] as int? ?? 0,
      upspeed: json['upspeed'] as int? ?? 0,
      eta: json['eta'] as int? ?? -1,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0.0,
      status: TorrentStatus.parse(json['state'] as String? ?? ''),
      state: json['state'] as String? ?? 'unknown',
      category: json['category'] as String?,
      tags:
          (json['tags'] as String?)?.split(',').map((e) => e.trim()).toList() ??
          [],
      savePath: json['save_path'] as String? ?? '',
      numSeeds: json['num_seeds'] as int? ?? 0,
      numLeechs: json['num_leechs'] as int? ?? 0,
      downloaded: json['downloaded'] as int? ?? 0,
      uploaded: json['uploaded'] as int? ?? 0,
      amountLeft: json['amount_left'] as int? ?? 0,
      addedOn: json['added_on'] as int? ?? 0,
    );
  }

  double get progressPercent => progress * 100;

  bool get isComplete => progress >= 1.0;

  Duration? get estimatedTime => eta > 0 ? Duration(seconds: eta) : null;

  @override
  List<Object?> get props => [
    hash,
    name,
    size,
    progress,
    dlspeed,
    upspeed,
    eta,
    ratio,
    status,
    state,
    category,
    tags,
    savePath,
    numSeeds,
    numLeechs,
    downloaded,
    uploaded,
    amountLeft,
    addedOn,
  ];
}
