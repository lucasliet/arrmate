import 'package:equatable/equatable.dart';

class Tag extends Equatable {
  final int id;
  final String label;

  const Tag({required this.id, required this.label});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(id: json['id'] as int, label: json['label'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label};
  }

  @override
  List<Object?> get props => [id, label];
}
