import 'package:equatable/equatable.dart';

class MediaCustomFormat extends Equatable {
  final int id;
  final String name;

  const MediaCustomFormat({required this.id, required this.name});

  String get label => name;

  factory MediaCustomFormat.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    int parsedId = -1;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId) ?? -1;
    }

    if (parsedId == -1) {
      throw FormatException(
        'Invalid or missing id in MediaCustomFormat JSON: $json',
      );
    }

    return MediaCustomFormat(
      id: parsedId,
      name: json['name'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  List<Object?> get props => [id, name];
}
