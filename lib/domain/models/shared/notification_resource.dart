/// Represents a notification configuration in a Radarr or Sonarr instance.
///
/// This model maps to the `/notification` endpoint of the *arr APIs and preserves
/// unknown fields in an [extra] map to ensure compatibility with different
/// API versions and implementations.
class NotificationResource {
  /// The unique identifier of the notification in the *arr instance.
  final int? id;

  /// The display name of the notification.
  final String? name;

  /// The implementation type (e.g., 'ntfy', 'telegram', 'discord').
  final String? implementation;

  /// The configuration contract name used by the API.
  final String? configContract;

  /// The list of configuration fields for this notification.
  final List<NotificationField> fields;

  /// Whether to notify when a release is grabbed.
  final bool onGrab;

  /// Whether to notify when a download is imported.
  final bool onDownload;

  /// Whether to notify when a release is upgraded.
  final bool onUpgrade;

  /// Whether to notify when a download fails.
  final bool onDownloadFailure;

  /// Whether to notify on application updates.
  final bool onApplicationUpdate;

  /// Whether to notify on system health issues.
  final bool onHealthIssue;

  final bool onMovieAdded;
  final bool onSeriesAdded;
  final bool onMovieDelete;
  final bool onSeriesDelete;
  final bool onMovieFileDelete;
  final bool onEpisodeFileDelete;
  final bool onManualInteractionRequired;
  final bool includeHealthWarnings;
  final bool onHealthRestored;

  /// Preservation of fields not explicitly mapped in this model.
  final Map<String, dynamic> extra;

  NotificationResource({
    this.id,
    this.name,
    this.implementation,
    this.configContract,
    this.fields = const [],
    this.onGrab = false,
    this.onDownload = false,
    this.onUpgrade = false,
    this.onDownloadFailure = false,
    this.onApplicationUpdate = false,
    this.onHealthIssue = false,
    this.onMovieAdded = false,
    this.onSeriesAdded = false,
    this.onMovieDelete = false,
    this.onSeriesDelete = false,
    this.onMovieFileDelete = false,
    this.onEpisodeFileDelete = false,
    this.onManualInteractionRequired = false,
    this.includeHealthWarnings = false,
    this.onHealthRestored = false,
    this.extra = const {},
  });

  /// Creates a [NotificationResource] from a JSON map.
  ///
  /// Extracts known fields and captures any remaining fields in the [extra] map.
  factory NotificationResource.fromJson(Map<String, dynamic> json) {
    final knownKeys = {
      'id',
      'name',
      'implementation',
      'configContract',
      'fields',
      'onGrab',
      'onDownload',
      'onUpgrade',
      'onDownloadFailure',
      'onApplicationUpdate',
      'onHealthIssue',
      'onMovieAdded',
      'onSeriesAdded',
      'onMovieDelete',
      'onSeriesDelete',
      'onMovieFileDelete',
      'onEpisodeFileDelete',
      'onManualInteractionRequired',
      'includeHealthWarnings',
      'onHealthRestored',
    };
    final extra = Map<String, dynamic>.from(json)
      ..removeWhere((key, value) => knownKeys.contains(key));

    return NotificationResource(
      id: json['id'] as int?,
      name: json['name'] as String?,
      implementation: json['implementation'] as String?,
      configContract: json['configContract'] as String?,
      fields:
          (json['fields'] as List?)
              ?.map(
                (e) => NotificationField.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      onGrab: json['onGrab'] as bool? ?? false,
      onDownload: json['onDownload'] as bool? ?? false,
      onUpgrade: json['onUpgrade'] as bool? ?? false,
      onDownloadFailure: json['onDownloadFailure'] as bool? ?? false,
      onApplicationUpdate: json['onApplicationUpdate'] as bool? ?? false,
      onHealthIssue: json['onHealthIssue'] as bool? ?? false,
      onMovieAdded: json['onMovieAdded'] as bool? ?? false,
      onSeriesAdded: json['onSeriesAdded'] as bool? ?? false,
      onMovieDelete: json['onMovieDelete'] as bool? ?? false,
      onSeriesDelete: json['onSeriesDelete'] as bool? ?? false,
      onMovieFileDelete: json['onMovieFileDelete'] as bool? ?? false,
      onEpisodeFileDelete: json['onEpisodeFileDelete'] as bool? ?? false,
      onManualInteractionRequired:
          json['onManualInteractionRequired'] as bool? ?? false,
      includeHealthWarnings: json['includeHealthWarnings'] as bool? ?? false,
      onHealthRestored: json['onHealthRestored'] as bool? ?? false,
      extra: extra,
    );
  }

  /// Converts this resource into a JSON map compatible with *arr APIs.
  Map<String, dynamic> toJson() {
    return {
      ...extra,
      if (id != null) 'id': id,
      'name': name,
      'implementation': implementation,
      'configContract': configContract,
      'fields': fields.map((e) => e.toJson()).toList(),
      'onGrab': onGrab,
      'onDownload': onDownload,
      'onUpgrade': onUpgrade,
      'onDownloadFailure': onDownloadFailure,
      'onApplicationUpdate': onApplicationUpdate,
      'onHealthIssue': onHealthIssue,
      'onMovieAdded': onMovieAdded,
      'onSeriesAdded': onSeriesAdded,
      'onMovieDelete': onMovieDelete,
      'onSeriesDelete': onSeriesDelete,
      'onMovieFileDelete': onMovieFileDelete,
      'onEpisodeFileDelete': onEpisodeFileDelete,
      'onManualInteractionRequired': onManualInteractionRequired,
      'includeHealthWarnings': includeHealthWarnings,
      'onHealthRestored': onHealthRestored,
    };
  }

  /// Creates a copy of this resource with the given fields replaced.
  NotificationResource copyWith({
    int? id,
    String? name,
    String? implementation,
    String? configContract,
    List<NotificationField>? fields,
    bool? onGrab,
    bool? onDownload,
    bool? onUpgrade,
    bool? onDownloadFailure,
    bool? onApplicationUpdate,
    bool? onHealthIssue,
    bool? onMovieAdded,
    bool? onSeriesAdded,
    bool? onMovieDelete,
    bool? onSeriesDelete,
    bool? onMovieFileDelete,
    bool? onEpisodeFileDelete,
    bool? onManualInteractionRequired,
    bool? includeHealthWarnings,
    bool? onHealthRestored,
    Map<String, dynamic>? extra,
  }) {
    return NotificationResource(
      id: id ?? this.id,
      name: name ?? this.name,
      implementation: implementation ?? this.implementation,
      configContract: configContract ?? this.configContract,
      fields: fields ?? this.fields,
      onGrab: onGrab ?? this.onGrab,
      onDownload: onDownload ?? this.onDownload,
      onUpgrade: onUpgrade ?? this.onUpgrade,
      onDownloadFailure: onDownloadFailure ?? this.onDownloadFailure,
      onApplicationUpdate: onApplicationUpdate ?? this.onApplicationUpdate,
      onHealthIssue: onHealthIssue ?? this.onHealthIssue,
      onMovieAdded: onMovieAdded ?? this.onMovieAdded,
      onSeriesAdded: onSeriesAdded ?? this.onSeriesAdded,
      onMovieDelete: onMovieDelete ?? this.onMovieDelete,
      onSeriesDelete: onSeriesDelete ?? this.onSeriesDelete,
      onMovieFileDelete: onMovieFileDelete ?? this.onMovieFileDelete,
      onEpisodeFileDelete: onEpisodeFileDelete ?? this.onEpisodeFileDelete,
      onManualInteractionRequired:
          onManualInteractionRequired ?? this.onManualInteractionRequired,
      includeHealthWarnings:
          includeHealthWarnings ?? this.includeHealthWarnings,
      onHealthRestored: onHealthRestored ?? this.onHealthRestored,
      extra: extra ?? this.extra,
    );
  }
}

/// Represents a single configuration field in a [NotificationResource].
class NotificationField {
  /// The key/name of the field (e.g., 'topic', 'server').
  final String name;

  /// The value of the field. Typically a [String] or [List].
  final dynamic value;

  NotificationField({required this.name, required this.value});

  /// Creates a field from a JSON map.
  factory NotificationField.fromJson(Map<String, dynamic> json) {
    return NotificationField(
      name: json['name'] as String,
      value: json['value'],
    );
  }

  /// Converts this field to a JSON map.
  Map<String, dynamic> toJson() {
    return {'name': name, 'value': value};
  }
}
