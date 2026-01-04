import 'package:equatable/equatable.dart';

class QualityProfile extends Equatable {
  final int id;
  final String name;

  const QualityProfile({
    required this.id,
    required this.name,
  });

  factory QualityProfile.fromJson(Map<String, dynamic> json) {
    return QualityProfile(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, name];
}
