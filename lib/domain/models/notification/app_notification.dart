import 'package:equatable/equatable.dart';

/// Represents the type of an in-app notification.
enum NotificationType {
  /// Download initiated or completed.
  download,

  /// Error during download or import.
  error,

  /// Media file successfully imported.
  imported,

  /// Upgrade available for *arr instance.
  upgrade,

  /// System warning.
  warning,

  /// General information.
  info,
}

/// Represents the priority level of a notification.
enum NotificationPriority {
  /// Low priority, informational.
  low,

  /// Medium priority, default.
  medium,

  /// High priority, requires attention.
  high,
}

/// Represents an in-app notification.
///
/// Notifications are stored locally and displayed in the app's notification
/// center. They can be marked as read, dismissed, or cleared.
class AppNotification extends Equatable {
  /// Unique identifier for the notification.
  final String id;

  /// Title of the notification.
  final String title;

  /// Body/message of the notification.
  final String message;

  /// Type of notification (download, error, etc.).
  final NotificationType type;

  /// Priority level of the notification.
  final NotificationPriority priority;

  /// Timestamp when the notification was received.
  final DateTime timestamp;

  /// Whether the notification has been read.
  final bool isRead;

  /// Optional metadata (movieId, seriesId, eventType, etc.).
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  /// Creates a copy of this notification with the given fields replaced.
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates an [AppNotification] from a JSON map.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.info,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      isRead: json['isRead'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts this notification to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Returns the icon for this notification type.
  String get iconName {
    switch (type) {
      case NotificationType.download:
        return 'download';
      case NotificationType.error:
        return 'error';
      case NotificationType.imported:
        return 'check_circle';
      case NotificationType.upgrade:
        return 'system_update';
      case NotificationType.warning:
        return 'warning';
      case NotificationType.info:
        return 'info';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        type,
        priority,
        timestamp,
        isRead,
        metadata,
      ];
}
