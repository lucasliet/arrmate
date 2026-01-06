import 'package:equatable/equatable.dart';

/// Represents a root folder where media is stored.
class RootFolder extends Equatable {
  final int id;
  final String path;
  final int? freeSpace;
  final List<UnmappedFolder> unmappedFolders;

  const RootFolder({
    required this.id,
    required this.path,
    this.freeSpace,
    this.unmappedFolders = const [],
  });

  String get label => path;
  double get freeSpaceGb => (freeSpace ?? 0) / 1024 / 1024 / 1024;

  factory RootFolder.fromJson(Map<String, dynamic> json) {
    return RootFolder(
      id: json['id'] as int,
      path: json['path'] as String,
      freeSpace: json['freeSpace'] as int?,
      unmappedFolders:
          (json['unmappedFolders'] as List<dynamic>?)
              ?.map((e) => UnmappedFolder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'freeSpace': freeSpace,
      'unmappedFolders': unmappedFolders.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, path, freeSpace, unmappedFolders];
}

/// Represents a folder within a root folder that is not mapped to any series/movie.
class UnmappedFolder extends Equatable {
  final String name;
  final String path;

  const UnmappedFolder({required this.name, required this.path});

  factory UnmappedFolder.fromJson(Map<String, dynamic> json) {
    return UnmappedFolder(
      name: json['name'] as String,
      path: json['path'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'path': path};
  }

  @override
  List<Object?> get props => [name, path];
}
