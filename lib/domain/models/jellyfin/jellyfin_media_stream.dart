import 'package:equatable/equatable.dart';

/// A single audio, video, or subtitle stream inside a Jellyfin media source.
class JellyfinMediaStream extends Equatable {
  /// Stream index within its [parent media source].
  final int index;

  /// Stream type as reported by Jellyfin (`Audio`, `Subtitle`, `Video`).
  final String? type;

  /// Container codec (e.g. `aac`, `subrip`, `h264`).
  final String? codec;

  /// ISO language code when the stream declares one.
  final String? language;

  /// Server-composed label suitable for display in a track picker.
  final String? displayTitle;

  /// Raw stream title as embedded in the file.
  final String? title;

  /// Whether the stream is flagged as the default for its type.
  final bool isDefault;

  /// Whether the stream lives in a sidecar file next to the media.
  final bool isExternal;

  /// Jellyfin-relative delivery path for external subtitles, when provided.
  ///
  /// The value is not absolute: callers must resolve it against the server
  /// base URL before handing it to a player.
  final String? deliveryUrl;

  /// Creates a media stream description.
  const JellyfinMediaStream({
    required this.index,
    this.type,
    this.codec,
    this.language,
    this.displayTitle,
    this.title,
    this.isDefault = false,
    this.isExternal = false,
    this.deliveryUrl,
  });

  /// Builds a stream from a Jellyfin `MediaStream` JSON object.
  factory JellyfinMediaStream.fromJson(Map<String, dynamic> json) {
    return JellyfinMediaStream(
      index: (json['Index'] as num?)?.toInt() ?? 0,
      type: json['Type'] as String?,
      codec: json['Codec'] as String?,
      language: json['Language'] as String?,
      displayTitle: json['DisplayTitle'] as String?,
      title: json['Title'] as String?,
      isDefault: json['IsDefault'] as bool? ?? false,
      isExternal: json['IsExternal'] as bool? ?? false,
      deliveryUrl: json['DeliveryUrl'] as String?,
    );
  }

  /// Serializes the stream back to a Jellyfin-compatible JSON object.
  Map<String, dynamic> toJson() {
    return {
      'Index': index,
      if (type != null) 'Type': type,
      if (codec != null) 'Codec': codec,
      if (language != null) 'Language': language,
      if (displayTitle != null) 'DisplayTitle': displayTitle,
      if (title != null) 'Title': title,
      'IsDefault': isDefault,
      'IsExternal': isExternal,
      if (deliveryUrl != null) 'DeliveryUrl': deliveryUrl,
    };
  }

  @override
  List<Object?> get props => [
    index,
    type,
    codec,
    language,
    displayTitle,
    title,
    isDefault,
    isExternal,
    deliveryUrl,
  ];
}
