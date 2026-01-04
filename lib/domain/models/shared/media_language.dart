import 'package:equatable/equatable.dart';

class MediaLanguage extends Equatable {
  final int id;
  final String? name;

  const MediaLanguage({required this.id, this.name});

  factory MediaLanguage.fromJson(Map<String, dynamic> json) {
    return MediaLanguage(id: json['id'] as int, name: json['name'] as String?);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, if (name != null) 'name': name};
  }

  @override
  List<Object?> get props => [id, name];
}
