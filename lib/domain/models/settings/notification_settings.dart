import 'package:equatable/equatable.dart';

class NotificationSettings extends Equatable {
  final bool enabled;
  final bool notifyOnGrab;
  final bool notifyOnImport;
  final bool notifyOnDownloadFailed;
  final int pollingIntervalMinutes;
  final Map<String, int> lastNotifiedIdByInstance;

  const NotificationSettings({
    this.enabled = false,
    this.notifyOnGrab = true,
    this.notifyOnImport = true,
    this.notifyOnDownloadFailed = true,
    this.pollingIntervalMinutes = 15,
    this.lastNotifiedIdByInstance = const {},
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? notifyOnGrab,
    bool? notifyOnImport,
    bool? notifyOnDownloadFailed,
    int? pollingIntervalMinutes,
    Map<String, int>? lastNotifiedIdByInstance,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      notifyOnGrab: notifyOnGrab ?? this.notifyOnGrab,
      notifyOnImport: notifyOnImport ?? this.notifyOnImport,
      notifyOnDownloadFailed:
          notifyOnDownloadFailed ?? this.notifyOnDownloadFailed,
      pollingIntervalMinutes:
          pollingIntervalMinutes ?? this.pollingIntervalMinutes,
      lastNotifiedIdByInstance: lastNotifiedIdByInstance != null
          ? Map<String, int>.from(lastNotifiedIdByInstance)
          : Map<String, int>.from(this.lastNotifiedIdByInstance),
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] as bool? ?? false,
      notifyOnGrab: json['notifyOnGrab'] as bool? ?? true,
      notifyOnImport: json['notifyOnImport'] as bool? ?? true,
      notifyOnDownloadFailed: json['notifyOnDownloadFailed'] as bool? ?? true,
      pollingIntervalMinutes: json['pollingIntervalMinutes'] as int? ?? 15,
      lastNotifiedIdByInstance:
          (json['lastNotifiedIdByInstance'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'notifyOnGrab': notifyOnGrab,
      'notifyOnImport': notifyOnImport,
      'notifyOnDownloadFailed': notifyOnDownloadFailed,
      'pollingIntervalMinutes': pollingIntervalMinutes,
      'lastNotifiedIdByInstance': lastNotifiedIdByInstance,
    };
  }

  @override
  List<Object?> get props => [
    enabled,
    notifyOnGrab,
    notifyOnImport,
    notifyOnDownloadFailed,
    pollingIntervalMinutes,
    lastNotifiedIdByInstance,
  ];
}
