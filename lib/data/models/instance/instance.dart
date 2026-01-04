import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../shared/shared.dart';
import 'root_folder.dart';

enum InstanceType {
  radarr('Radarr'),
  sonarr('Sonarr');

  final String label;
  const InstanceType(this.label);
}

enum InstanceMode {
  normal,
  slow;

  bool get isSlow => this == InstanceMode.slow;
}

class InstanceHeader extends Equatable {
  final String id;
  final String name;
  final String value;

  InstanceHeader({
    String? id,
    required String name,
    required String value,
  })  : id = id ?? const Uuid().v4(),
        name = name.replaceAll(':', '').trim(),
        value = value.trim();

  factory InstanceHeader.fromJson(Map<String, dynamic> json) {
    return InstanceHeader(
      id: json['id'] as String?,
      name: json['name'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
    };
  }

  @override
  List<Object?> get props => [id, name, value];
}

class InstanceStatus extends Equatable {
  final String appName;
  final String instanceName;
  final String version;

  const InstanceStatus({
    required this.appName,
    required this.instanceName,
    required this.version,
  });

  factory InstanceStatus.fromJson(Map<String, dynamic> json) {
    return InstanceStatus(
      appName: json['appName'] as String,
      instanceName: json['instanceName'] as String,
      version: json['version'] as String,
    );
  }

  @override
  List<Object?> get props => [appName, instanceName, version];
}

class Instance extends Equatable {
  final String id;
  final InstanceType type;
  final InstanceMode mode;
  final String label;
  final String url;
  final String apiKey;
  final List<InstanceHeader> headers;
  final List<RootFolder> rootFolders;
  final List<QualityProfile> qualityProfiles;
  final List<Tag> tags;
  final String? name;
  final String? version;

  Instance({
    String? id,
    this.type = InstanceType.radarr,
    this.mode = InstanceMode.normal,
    this.label = '',
    this.url = '',
    this.apiKey = '',
    this.headers = const [],
    this.rootFolders = const [],
    this.qualityProfiles = const [],
    this.tags = const [],
    this.name,
    this.version,
  }) : id = id ?? const Uuid().v4();

  factory Instance.fromJson(Map<String, dynamic> json) {
    return Instance(
      id: json['id'] as String,
      type: InstanceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InstanceType.radarr,
      ),
      mode: InstanceMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => InstanceMode.normal,
      ),
      label: json['label'] as String,
      url: json['url'] as String,
      apiKey: json['apiKey'] as String,
      headers: (json['headers'] as List<dynamic>?)
              ?.map((e) => InstanceHeader.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rootFolders: (json['rootFolders'] as List<dynamic>?)
              ?.map((e) => RootFolder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      qualityProfiles: (json['qualityProfiles'] as List<dynamic>?)
              ?.map((e) => QualityProfile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      name: json['name'] as String?,
      version: json['version'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'mode': mode.name,
      'label': label,
      'url': url,
      'apiKey': apiKey,
      'headers': headers.map((e) => e.toJson()).toList(),
      'rootFolders': rootFolders.map((e) => e.toJson()).toList(),
      'qualityProfiles': qualityProfiles.map((e) => e.toJson()).toList(),
      'tags': tags.map((e) => e.toJson()).toList(),
      if (name != null) 'name': name,
      if (version != null) 'version': version,
    };
  }

  Map<String, String> get authHeaders {
    final map = <String, String>{'X-Api-Key': apiKey};
    for (final header in headers) {
      map[header.name] = header.value;
    }
    return map;
  }

  Uri get baseUri => Uri.parse(url);

  Duration timeout(InstanceTimeout timeout) {
    switch (timeout) {
      case InstanceTimeout.normal:
        return const Duration(seconds: 10);
      case InstanceTimeout.slow:
        return Duration(seconds: mode.isSlow ? 300 : 10);
      case InstanceTimeout.releaseSearch:
        return Duration(seconds: mode.isSlow ? 180 : 90);
      case InstanceTimeout.releaseDownload:
        return const Duration(seconds: 15);
    }
  }

  Instance copyWith({
    String? id,
    InstanceType? type,
    InstanceMode? mode,
    String? label,
    String? url,
    String? apiKey,
    List<InstanceHeader>? headers,
    List<RootFolder>? rootFolders,
    List<QualityProfile>? qualityProfiles,
    List<Tag>? tags,
    String? name,
    String? version,
  }) {
    return Instance(
      id: id ?? this.id,
      type: type ?? this.type,
      mode: mode ?? this.mode,
      label: label ?? this.label,
      url: url ?? this.url,
      apiKey: apiKey ?? this.apiKey,
      headers: headers ?? this.headers,
      rootFolders: rootFolders ?? this.rootFolders,
      qualityProfiles: qualityProfiles ?? this.qualityProfiles,
      tags: tags ?? this.tags,
      name: name ?? this.name,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        mode,
        label,
        url,
        apiKey,
        headers,
        rootFolders,
        qualityProfiles,
        tags,
        name,
        version,
      ];

  static Instance get radarrVoid => Instance(
        id: '00000000-1000-0000-0000-000000000000',
        type: InstanceType.radarr,
      );

  static Instance get sonarrVoid => Instance(
        id: '00000000-2000-0000-0000-000000000000',
        type: InstanceType.sonarr,
      );
}

enum InstanceTimeout {
  normal,
  slow,
  releaseSearch,
  releaseDownload,
}
