import 'package:equatable/equatable.dart';

/// Represents an image associated with media (poster, fanart, etc.).
class MediaImage extends Equatable {
  final String coverType;
  final String? url;
  final String? remoteUrl;

  const MediaImage({required this.coverType, this.url, this.remoteUrl});

  factory MediaImage.fromJson(Map<String, dynamic> json) {
    return MediaImage(
      coverType: json['coverType'] as String,
      url: json['url'] as String?,
      remoteUrl: json['remoteUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coverType': coverType,
      if (url != null) 'url': url,
      if (remoteUrl != null) 'remoteUrl': remoteUrl,
    };
  }

  /// The URL helper for remote images.
  String? get remoteURL => remoteUrl;

  /// Returns true if this is a poster.
  bool get isPoster => coverType == 'poster';

  /// Returns true if this is fanart / background.
  bool get isFanart => coverType == 'fanart';

  /// Returns true if this is a banner.
  bool get isBanner => coverType == 'banner';

  @override
  List<Object?> get props => [coverType, url, remoteUrl];
}
