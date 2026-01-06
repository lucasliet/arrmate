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
    batterySaverMode,
    pollingIntervalMinutes,
  ];
}
