import 'package:equatable/equatable.dart';

/// Configuration settings for app notifications (via ntfy).
class NotificationSettings extends Equatable {
  /// Whether notifications are enabled.
  final bool enabled;

  /// The unique ntfy topic for this device.
  final String? ntfyTopic;

  /// Notify when a release is grabbed (sent to download client).
  final bool notifyOnGrab;

  /// Notify when a file is successfully imported.
  final bool notifyOnImport;

  /// Notify when a download fails to import.
  final bool notifyOnDownloadFailed;

  /// Notify on system health issues.
  final bool notifyOnHealthIssue;

  /// Notify when a health issue is resolved.
  final bool notifyOnHealthRestored;

  /// Include warnings in health issue notifications.
  final bool includeHealthWarnings;

  /// Notify when a movie/number is added.
  final bool notifyOnMediaAdded;

  /// Notify when a movie/series is deleted.
  final bool notifyOnMediaDeleted;

  /// Notify when a file is deleted.
  final bool notifyOnFileDelete;

  /// Notify when the application is updated.
  final bool notifyOnUpgrade;

  /// Notify when manual interaction is required.
  final bool notifyOnManualRequired;

  /// When enabled, disables background polling to save battery.
  /// Notifications will only be received while the app is open.
  final bool batterySaverMode;

  /// The interval in minutes for background polling.
  /// Only used when [batterySaverMode] is false.
  final int pollingIntervalMinutes;

  static const String ntfyServer = 'ntfy.sh';

  /// Available polling interval options in minutes.
  static const List<int> pollingIntervalOptions = [15, 30, 60];

  const NotificationSettings({
    this.enabled = false,
    this.ntfyTopic,
    this.notifyOnGrab = true,
    this.notifyOnImport = true,
    this.notifyOnDownloadFailed = true,
    this.notifyOnHealthIssue = false,
    this.notifyOnHealthRestored = false,
    this.includeHealthWarnings = false,
    this.notifyOnMediaAdded = false,
    this.notifyOnMediaDeleted = false,
    this.notifyOnFileDelete = false,
    this.notifyOnUpgrade = false,
    this.notifyOnManualRequired = false,
    this.batterySaverMode = false,
    this.pollingIntervalMinutes = 30,
  });

  /// Returns the full URL for the ntfy topic.
  String? get ntfyTopicUrl =>
      ntfyTopic != null ? 'https://$ntfyServer/$ntfyTopic' : null;

  /// Returns the WebSocket URL for listening to notifications.
  String? get ntfyWebSocketUrl =>
      ntfyTopic != null ? 'wss://$ntfyServer/$ntfyTopic/ws' : null;

  /// Returns the JSON stream URL for listening to notifications (SSE).
  String? get ntfyJsonStreamUrl =>
      ntfyTopic != null ? 'https://$ntfyServer/$ntfyTopic/json' : null;

  NotificationSettings copyWith({
    bool? enabled,
    String? ntfyTopic,
    bool? notifyOnGrab,
    bool? notifyOnImport,
    bool? notifyOnDownloadFailed,
    bool? notifyOnHealthIssue,
    bool? notifyOnHealthRestored,
    bool? includeHealthWarnings,
    bool? notifyOnMediaAdded,
    bool? notifyOnMediaDeleted,
    bool? notifyOnFileDelete,
    bool? notifyOnUpgrade,
    bool? notifyOnManualRequired,
    bool? batterySaverMode,
    int? pollingIntervalMinutes,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      ntfyTopic: ntfyTopic ?? this.ntfyTopic,
      notifyOnGrab: notifyOnGrab ?? this.notifyOnGrab,
      notifyOnImport: notifyOnImport ?? this.notifyOnImport,
      notifyOnDownloadFailed:
          notifyOnDownloadFailed ?? this.notifyOnDownloadFailed,
      notifyOnHealthIssue: notifyOnHealthIssue ?? this.notifyOnHealthIssue,
      notifyOnHealthRestored:
          notifyOnHealthRestored ?? this.notifyOnHealthRestored,
      includeHealthWarnings:
          includeHealthWarnings ?? this.includeHealthWarnings,
      notifyOnMediaAdded: notifyOnMediaAdded ?? this.notifyOnMediaAdded,
      notifyOnMediaDeleted: notifyOnMediaDeleted ?? this.notifyOnMediaDeleted,
      notifyOnFileDelete: notifyOnFileDelete ?? this.notifyOnFileDelete,
      notifyOnUpgrade: notifyOnUpgrade ?? this.notifyOnUpgrade,
      notifyOnManualRequired:
          notifyOnManualRequired ?? this.notifyOnManualRequired,
      batterySaverMode: batterySaverMode ?? this.batterySaverMode,
      pollingIntervalMinutes:
          pollingIntervalMinutes ?? this.pollingIntervalMinutes,
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] as bool? ?? false,
      ntfyTopic: json['ntfyTopic'] as String?,
      notifyOnGrab: json['notifyOnGrab'] as bool? ?? true,
      notifyOnImport: json['notifyOnImport'] as bool? ?? true,
      notifyOnDownloadFailed: json['notifyOnDownloadFailed'] as bool? ?? true,
      notifyOnHealthIssue: json['notifyOnHealthIssue'] as bool? ?? false,
      notifyOnHealthRestored: json['notifyOnHealthRestored'] as bool? ?? false,
      includeHealthWarnings: json['includeHealthWarnings'] as bool? ?? false,
      notifyOnMediaAdded: json['notifyOnMediaAdded'] as bool? ?? false,
      notifyOnMediaDeleted: json['notifyOnMediaDeleted'] as bool? ?? false,
      notifyOnFileDelete: json['notifyOnFileDelete'] as bool? ?? false,
      notifyOnUpgrade: json['notifyOnUpgrade'] as bool? ?? false,
      notifyOnManualRequired: json['notifyOnManualRequired'] as bool? ?? false,
      batterySaverMode: json['batterySaverMode'] as bool? ?? false,
      pollingIntervalMinutes: json['pollingIntervalMinutes'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'ntfyTopic': ntfyTopic,
      'notifyOnGrab': notifyOnGrab,
      'notifyOnImport': notifyOnImport,
      'notifyOnDownloadFailed': notifyOnDownloadFailed,
      'notifyOnHealthIssue': notifyOnHealthIssue,
      'notifyOnHealthRestored': notifyOnHealthRestored,
      'includeHealthWarnings': includeHealthWarnings,
      'notifyOnMediaAdded': notifyOnMediaAdded,
      'notifyOnMediaDeleted': notifyOnMediaDeleted,
      'notifyOnFileDelete': notifyOnFileDelete,
      'notifyOnUpgrade': notifyOnUpgrade,
      'notifyOnManualRequired': notifyOnManualRequired,
      'batterySaverMode': batterySaverMode,
      'pollingIntervalMinutes': pollingIntervalMinutes,
    };
  }

  @override
  List<Object?> get props => [
    enabled,
    ntfyTopic,
    notifyOnGrab,
    notifyOnImport,
    notifyOnDownloadFailed,
    notifyOnHealthIssue,
    notifyOnHealthRestored,
    includeHealthWarnings,
    notifyOnMediaAdded,
    notifyOnMediaDeleted,
    notifyOnFileDelete,
    notifyOnUpgrade,
    notifyOnManualRequired,
    batterySaverMode,
    pollingIntervalMinutes,
  ];
}
