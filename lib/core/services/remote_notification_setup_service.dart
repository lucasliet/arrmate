import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/logger_service.dart';
import '../../domain/models/models.dart';
import '../../domain/models/settings/notification_settings.dart';
import '../../data/api/radarr_api.dart';
import '../../data/api/sonarr_api.dart';
import '../../presentation/providers/settings_provider.dart';

final remoteNotificationServiceProvider = Provider(
  (ref) => RemoteNotificationService(ref),
);

/// Service responsible for automatically configuring push notifications in *arr instances.
///
/// It uses the 'ntfy' implementation to create or update a webhook in Radarr/Sonarr
/// that points to the user's unique ntfy topic.
class RemoteNotificationService {
  final Ref _ref;

  RemoteNotificationService(this._ref);

  /// Configures (creates or updates) a notification for the given [instance].
  ///
  /// This method:
  /// 1. Verifies if a ntfy topic exists in settings.
  /// 2. Searches existing notifications in the instance by matching the topic.
  /// 3. Creates a new notification if none matches, or updates the existing one.
  /// 4. Ensures a unique name `Arrmate (XXXXXX)` to allow multiple installations.
  ///
  /// Returns a [NotificationSetupResult] indicating success or failure.
  Future<NotificationSetupResult> configureInstance(
    Instance instance, {
    NotificationSettings? settings,
  }) async {
    try {
      final effectiveSettings =
          settings ?? _ref.read(settingsProvider).notifications;
      final topic = effectiveSettings.ntfyTopic;
      if (topic == null) {
        return NotificationSetupResult.failure(
          'No Ntfy topic configured in Arrmate.',
        );
      }

      logger.info(
        '[RemoteNotificationService] Configuring ${instance.name} (${instance.type.name}) with topic: $topic',
      );

      final notifications = await _getNotifications(instance);

      // Look for existing Arrmate notification by topic or unique name
      final topicSuffix = topic.length > 6
          ? topic.substring(topic.length - 6)
          : topic;
      final uniqueName = 'Arrmate ($topicSuffix)';

      NotificationResource? existing = notifications
          .cast<NotificationResource?>()
          .firstWhere(
            (n) => n != null && (_hasTopic(n, topic) || n.name == uniqueName),
            orElse: () => null,
          );

      if (existing == null) {
        // Create new
        final schemas = await _getSchemas(instance);
        final ntfySchema = schemas.firstWhere(
          (s) => s.implementation?.toLowerCase() == 'ntfy',
          orElse: () => throw Exception(
            'Ntfy implementation not found in ${instance.type.name}',
          ),
        );

        final newNotification = ntfySchema.copyWith(
          name: uniqueName,
          onGrab: effectiveSettings.notifyOnGrab,
          onDownload: effectiveSettings.notifyOnImport,
          onUpgrade: effectiveSettings.notifyOnUpgrade,
          onDownloadFailure: effectiveSettings.notifyOnDownloadFailed,
          onHealthIssue: effectiveSettings.notifyOnHealthIssue,
          onHealthRestored: effectiveSettings.notifyOnHealthRestored,
          onApplicationUpdate: effectiveSettings.notifyOnUpgrade,
          onMovieAdded: effectiveSettings.notifyOnMediaAdded,
          onSeriesAdded: effectiveSettings.notifyOnMediaAdded,
          onMovieDelete: effectiveSettings.notifyOnMediaDeleted,
          onSeriesDelete: effectiveSettings.notifyOnMediaDeleted,
          onMovieFileDelete: effectiveSettings.notifyOnFileDelete,
          onEpisodeFileDelete: effectiveSettings.notifyOnFileDelete,
          onManualInteractionRequired: effectiveSettings.notifyOnManualRequired,
          includeHealthWarnings: effectiveSettings.includeHealthWarnings,
          fields: _buildFields(ntfySchema.fields, topic),
        );

        // Map extra triggers if they exist in schema but not in our model
        final json = newNotification.toJson();
        if (json.containsKey('onImportComplete')) {
          json['onImportComplete'] = effectiveSettings.notifyOnImport;
        }
        if (json.containsKey('onDownloadFailed') &&
            !json.containsKey('onDownloadFailure')) {
          json['onDownloadFailed'] = effectiveSettings.notifyOnDownloadFailed;
        }

        await _createNotification(
          instance,
          NotificationResource.fromJson(json),
        );
        return NotificationSetupResult.success(
          '${instance.name} configured successfully.',
        );
      } else {
        // Update existing (maybe topic or triggers changed)
        final updated = existing.copyWith(
          name: uniqueName,
          onGrab: effectiveSettings.notifyOnGrab,
          onDownload: effectiveSettings.notifyOnImport,
          onUpgrade: effectiveSettings.notifyOnUpgrade,
          onDownloadFailure: effectiveSettings.notifyOnDownloadFailed,
          onHealthIssue: effectiveSettings.notifyOnHealthIssue,
          onHealthRestored: effectiveSettings.notifyOnHealthRestored,
          onApplicationUpdate: effectiveSettings.notifyOnUpgrade,
          onMovieAdded: effectiveSettings.notifyOnMediaAdded,
          onSeriesAdded: effectiveSettings.notifyOnMediaAdded,
          onMovieDelete: effectiveSettings.notifyOnMediaDeleted,
          onSeriesDelete: effectiveSettings.notifyOnMediaDeleted,
          onMovieFileDelete: effectiveSettings.notifyOnFileDelete,
          onEpisodeFileDelete: effectiveSettings.notifyOnFileDelete,
          onManualInteractionRequired: effectiveSettings.notifyOnManualRequired,
          includeHealthWarnings: effectiveSettings.includeHealthWarnings,
          fields: _buildFields(existing.fields, topic),
        );

        // Map extra triggers
        final json = updated.toJson();
        if (json.containsKey('onImportComplete')) {
          json['onImportComplete'] = effectiveSettings.notifyOnImport;
        }
        if (json.containsKey('onDownloadFailed') &&
            !json.containsKey('onDownloadFailure')) {
          json['onDownloadFailed'] = effectiveSettings.notifyOnDownloadFailed;
        }

        await _updateNotification(
          instance,
          NotificationResource.fromJson(json),
        );
        return NotificationSetupResult.success(
          '${instance.name} updated successfully.',
        );
      }
    } catch (e, st) {
      logger.error(
        '[RemoteNotificationService] Failed to configure ${instance.name}',
        e,
        st,
      );
      return NotificationSetupResult.failure(
        'Failed to configure ${instance.name}: $e',
      );
    }
  }

  /// Fetches already configured notifications from the instance.
  Future<List<NotificationResource>> _getNotifications(
    Instance instance,
  ) async {
    if (instance.type == InstanceType.radarr) {
      return RadarrApi(instance).getNotifications();
    } else {
      return SonarrApi(instance).getNotifications();
    }
  }

  /// Fetches available notification schemas from the instance.
  Future<List<NotificationResource>> _getSchemas(Instance instance) async {
    if (instance.type == InstanceType.radarr) {
      return RadarrApi(instance).getNotificationSchemas();
    } else {
      return SonarrApi(instance).getNotificationSchemas();
    }
  }

  /// Sends a request to create a new notification in the instance.
  Future<void> _createNotification(
    Instance instance,
    NotificationResource notification,
  ) async {
    if (instance.type == InstanceType.radarr) {
      await RadarrApi(instance).createNotification(notification);
    } else {
      await SonarrApi(instance).createNotification(notification);
    }
  }

  /// Sends a request to update an existing notification in the instance.
  Future<void> _updateNotification(
    Instance instance,
    NotificationResource notification,
  ) async {
    if (instance.type == InstanceType.radarr) {
      await RadarrApi(instance).updateNotification(notification);
    } else {
      await SonarrApi(instance).updateNotification(notification);
    }
  }

  /// Populates configuration fields with the ntfy topic and server URL.
  List<NotificationField> _buildFields(
    List<NotificationField> baseFields,
    String topic,
  ) {
    return baseFields.map((f) {
      // Radarr style or generic
      if (f.name == 'topic') {
        return NotificationField(name: 'topic', value: topic);
      }
      // Sonarr v4 style (list of topics)
      if (f.name == 'topics') {
        return NotificationField(name: 'topics', value: [topic]);
      }
      // Server URL handling
      if (f.name == 'baseUrl' || f.name == 'serverUrl') {
        return NotificationField(name: f.name, value: 'https://ntfy.sh');
      }
      return f;
    }).toList();
  }

  /// Checks if a [notification] points to the given [topic].
  bool _hasTopic(NotificationResource notification, String topic) {
    return notification.fields.any((f) {
      if (f.name == 'topic') return f.value == topic;
      if (f.name == 'topics' && f.value is List) {
        return (f.value as List).contains(topic);
      }
      return false;
    });
  }
}

/// Represents the result of an auto-configuration attempt.
class NotificationSetupResult {
  /// A descriptive message about the result.
  final String message;

  /// Whether the operation was successful.
  final bool isSuccess;

  NotificationSetupResult.success(this.message) : isSuccess = true;
  NotificationSetupResult.failure(this.message) : isSuccess = false;
}
