import 'package:equatable/equatable.dart';

class RootFolder extends Equatable {
  final int id;
  final bool accessible;
  final String? path;
  final int? freeSpace;

  const RootFolder({
    required this.id,
    required this.accessible,
    this.path,
    this.freeSpace,
  });

  factory RootFolder.fromJson(Map<String, dynamic> json) {
    return RootFolder(
      id: json['id'] as int,
      accessible: json['accessible'] as bool? ?? true,
      path: json['path'] as String?,
      freeSpace: json['freeSpace'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accessible': accessible,
      if (path != null) 'path': path,
      if (freeSpace != null) 'freeSpace': freeSpace,
    };
  }

  String get label {
    if (path != null) {
      final p = path!;
      return p.endsWith('/') ? p.substring(0, p.length - 1) : p;
    }
    return 'Folder ($id)';
  }

  @override
  List<Object?> get props => [id, accessible, path, freeSpace];
}
