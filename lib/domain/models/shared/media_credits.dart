import 'package:equatable/equatable.dart';

/// A person credited in a movie or series, either cast or crew.
class MediaCredit extends Equatable {
  /// Name of the person.
  final String name;

  /// Character played (cast) or job held (crew), when known.
  final String? role;

  /// Absolute URL of the headshot, when the person has one.
  final String? imageUrl;

  /// Creates a [MediaCredit].
  const MediaCredit({required this.name, this.role, this.imageUrl});

  @override
  List<Object?> get props => [name, role, imageUrl];
}

/// Extra identification data for a title that is not in the library yet.
///
/// Comes from the public metadata servers Radarr and Sonarr use themselves,
/// since their lookup endpoints return no credits.
class MediaPreviewDetails extends Equatable {
  /// Title in the original language, when the server reports one.
  final String? originalTitle;

  /// English title, when the server reports one.
  final String? englishTitle;

  /// Main cast, in billing order.
  final List<MediaCredit> cast;

  /// Main crew, directors and writers first.
  final List<MediaCredit> crew;

  /// Creates a [MediaPreviewDetails].
  const MediaPreviewDetails({
    this.originalTitle,
    this.englishTitle,
    this.cast = const [],
    this.crew = const [],
  });

  @override
  List<Object?> get props => [originalTitle, englishTitle, cast, crew];
}
