import 'package:equatable/equatable.dart';

class MediaCustomFormat extends Equatable {
  final int id;
  final String name;

  const MediaCustomFormat({required this.id, required this.name});

  String get label => name;

  factory MediaCustomFormat.fromJson(Map<String, dynamic> json) {
    return MediaCustomFormat(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  List<Object?> get props => [id, name];
}
