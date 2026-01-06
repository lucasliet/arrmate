import 'package:workmanager/workmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../domain/models/models.dart';
import '../../domain/models/settings/notification_settings.dart';
import 'notification_service.dart';
import 'logger_service.dart';
import '../../presentation/providers/data_providers.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final container = ProviderContainer();
    try {
      // Manual load since it's a new container
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notification_settings');
      if (notificationsJson == null) return true;

      final settings = NotificationSettings.fromJson(
        jsonDecode(notificationsJson),
      );
      if (!settings.enabled) return true;

      final movieRepo = container.read(movieRepositoryProvider);
      final seriesRepo = container.read(seriesRepositoryProvider);
      final notificationService = container.read(notificationServiceProvider);

      await notificationService.init();

      Map<String, int> newLastIds = Map.from(settings.lastNotifiedIdByInstance);
      bool changed = false;

      // Check Movies (Radarr)
      if (movieRepo != null) {
        try {
          final history = await movieRepo.getHistory(page: 1, pageSize: 10);
          final lastId =
              settings.lastNotifiedIdByInstance[history
                      .records
                      .firstOrNull
                      ?.instanceId ??
                  'radarr'] ??
              0;

          for (var event in history.records.reversed) {
            if (event.id > lastId) {
              if (_shouldNotify(event, settings)) {
                await notificationService.showNotification(
                  id: event.id ^ 0x52000000, // Radarr prefix
                  title: event.eventType.label,
                  body: '${event.sourceTitle}\n${event.description}',
                );
              }
              newLastIds[event.instanceId ?? 'radarr'] = event.id;
              changed = true;
            }
          }
        } catch (e, stack) {
          logger.error('Error polling Radarr', e, stack);
        }
      }

      // Check Series (Sonarr)
      if (seriesRepo != null) {
        try {
          final history = await seriesRepo.getHistory(page: 1, pageSize: 10);
          final lastId =
              settings.lastNotifiedIdByInstance[history
                      .records
                      .firstOrNull
                      ?.instanceId ??
                  'sonarr'] ??
              0;

          for (var event in history.records.reversed) {
            if (event.id > lastId) {
              if (_shouldNotify(event, settings)) {
                await notificationService.showNotification(
                  id: event.id ^ 0x53000000, // Sonarr prefix
                  title: event.eventType.label,
                  body: '${event.sourceTitle}\n${event.description}',
                );
              }
              newLastIds[event.instanceId ?? 'sonarr'] = event.id;
              changed = true;
            }
          }
        } catch (e, stack) {
          logger.error('Error polling Sonarr', e, stack);
        }
      }

      if (changed) {
        final updatedSettings = settings.copyWith(
          lastNotifiedIdByInstance: newLastIds,
        );
        await prefs.setString(
          'notification_settings',
          jsonEncode(updatedSettings.toJson()),
        );
      }

      return true;
    } finally {
      container.dispose();
    }
  });
}

bool _shouldNotify(HistoryEvent event, NotificationSettings settings) {
  switch (event.eventType) {
    case HistoryEventType.grabbed:
      return settings.notifyOnGrab;
    case HistoryEventType.imported:
      return settings.notifyOnImport;
    case HistoryEventType.failed:
      return settings.notifyOnDownloadFailed;
    default:
      return false;
  }
}

class BackgroundSyncService {
  static const taskName = 'arrmate.sync_task';

  Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  Future<void> registerTask(int intervalMinutes) async {
    await Workmanager().registerPeriodicTask(
      '1',
      taskName,
      frequency: Duration(minutes: intervalMinutes),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}

final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  return BackgroundSyncService();
});
