import 'package:equatable/equatable.dart';

/// Represents a quality profile which dictates allowed qualities for media.
class QualityProfile extends Equatable {
  final int id;
  final String name;
  final bool upgradeAllowed;
  final int? cutoff;

  const QualityProfile({
    required this.id,
    required this.name,
    this.upgradeAllowed = false,
    this.cutoff,
  });

  factory QualityProfile.fromJson(Map<String, dynamic> json) {
    return QualityProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      upgradeAllowed: json['upgradeAllowed'] as bool? ?? false,
      cutoff: json['cutoff'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'upgradeAllowed': upgradeAllowed,
      'cutoff': cutoff,
    };
  }

  @override
  List<Object?> get props => [id, name, upgradeAllowed, cutoff];
}
