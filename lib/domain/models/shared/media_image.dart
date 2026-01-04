import 'package:equatable/equatable.dart';

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

  String? get remoteURL => remoteUrl;

  bool get isPoster => coverType == 'poster';
  bool get isFanart => coverType == 'fanart';
  bool get isBanner => coverType == 'banner';

  @override
  List<Object?> get props => [coverType, url, remoteUrl];
}
