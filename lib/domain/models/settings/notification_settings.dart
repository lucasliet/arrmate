import 'package:equatable/equatable.dart';

class NotificationSettings extends Equatable {
  final bool enabled;
  final String? ntfyTopic;
  final bool notifyOnGrab;
  final bool notifyOnImport;
  final bool notifyOnDownloadFailed;
  final bool notifyOnHealthIssue;

  static const String ntfyServer = 'ntfy.sh';

  const NotificationSettings({
    this.enabled = false,
    this.ntfyTopic,
    this.notifyOnGrab = true,
    this.notifyOnImport = true,
    this.notifyOnDownloadFailed = true,
    this.notifyOnHealthIssue = false,
  });

  String? get ntfyTopicUrl =>
      ntfyTopic != null ? 'https://$ntfyServer/$ntfyTopic' : null;

  String? get ntfyWebSocketUrl =>
      ntfyTopic != null ? 'wss://$ntfyServer/$ntfyTopic/ws' : null;

  String? get ntfyJsonStreamUrl =>
      ntfyTopic != null ? 'https://$ntfyServer/$ntfyTopic/json' : null;

  NotificationSettings copyWith({
    bool? enabled,
    String? ntfyTopic,
    bool? notifyOnGrab,
    bool? notifyOnImport,
    bool? notifyOnDownloadFailed,
    bool? notifyOnHealthIssue,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      ntfyTopic: ntfyTopic ?? this.ntfyTopic,
      notifyOnGrab: notifyOnGrab ?? this.notifyOnGrab,
      notifyOnImport: notifyOnImport ?? this.notifyOnImport,
      notifyOnDownloadFailed:
          notifyOnDownloadFailed ?? this.notifyOnDownloadFailed,
      notifyOnHealthIssue: notifyOnHealthIssue ?? this.notifyOnHealthIssue,
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
  ];
}
