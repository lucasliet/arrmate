import 'package:equatable/equatable.dart';

/// Represents an alternative title for a media item.
class MediaAlternateTitle extends Equatable {
  final String title;
  final int? seasonNumber;

  const MediaAlternateTitle({required this.title, this.seasonNumber});

  factory MediaAlternateTitle.fromJson(Map<String, dynamic> json) {
    return MediaAlternateTitle(
      title: json['title'] as String,
      seasonNumber: json['seasonNumber'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (seasonNumber != null) 'seasonNumber': seasonNumber,
    };
  }

  @override
  List<Object?> get props => [title, seasonNumber];
}
