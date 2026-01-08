import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../domain/models/notification/app_notification.dart';
import '../../domain/models/notification/ntfy_message.dart';
import '../../domain/models/settings/notification_settings.dart';
import 'in_app_notification_service.dart';
import 'logger_service.dart';

/// Callback type for when a new notification is received.
typedef OnNotificationReceived = void Function(AppNotification notification);

/// Service for connecting to an ntfy server to receive real-time notifications via SSE (Server-Sent Events).
///
/// This service connects to ntfy.sh and streams notifications in real-time
/// while the app is in the foreground. It also provides polling functionality
/// to fetch missed notifications when the app opens.
class NtfyService extends ChangeNotifier {
  final InAppNotificationService _notificationService;
  final Dio _dio;
  CancelToken? _cancelToken;
  StreamSubscription<dynamic>? _subscription;

  bool _isConnected = false;

  /// Returns true if the service is currently connected to an ntfy stream.
  bool get isConnected => _isConnected;

  String? _currentTopic;

  /// The topic currently subscribed to.
  String? get currentTopic => _currentTopic;

  /// Optional callback invoked when a new notification is received.
  OnNotificationReceived? onNotificationReceived;

  NtfyService(this._notificationService, {Dio? dio}) : _dio = dio ?? Dio();

  void _setConnected(bool value) {
    if (_isConnected != value) {
      _isConnected = value;
      notifyListeners();
    }
  }

  /// Connects to the specified [topic] on the ntfy server.
  ///
  /// Disconnects from any existing connection before establishing a new one.
  Future<void> connect(String topic) async {
    if (_currentTopic == topic && _isConnected) {
      logger.debug('[NtfyService] Already connected to topic: $topic');
      return;
    }

    await disconnect();

    logger.info('[NtfyService] Connecting to topic: $topic');
    _currentTopic = topic;
    _cancelToken = CancelToken();

    try {
      // No poll param, relying on SSE
      final url = 'https://${NotificationSettings.ntfyServer}/$topic/json';
      logger.debug('[NtfyService] Stream URL: $url');
      logger.debug('[NtfyService] Requesting connection...');

      final response = await _dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'application/x-ndjson'},
        ),
        cancelToken: _cancelToken,
      );

      logger.debug('[NtfyService] Connection established, stream ready');

      _subscription = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(onMessage, onError: _onError, onDone: _onDone);

      _setConnected(true);
      logger.info('[NtfyService] Connected successfully to topic: $topic');
    } catch (e, stackTrace) {
      if (e is DioException && CancelToken.isCancel(e)) {
        logger.debug('[NtfyService] Connection cancelled');
      } else {
        logger.error('[NtfyService] Failed to connect', e, stackTrace);
        _setConnected(false);
        _scheduleReconnect();
        rethrow;
      }
    }
  }

  /// Handles incoming messages from the SSE stream.
  @visibleForTesting
  void onMessage(dynamic event) async {
    try {
      Map<String, dynamic>? json;
      if (event is String) {
        if (event.trim().isEmpty) return;
        json = jsonDecode(event);
      } else if (event is Map<String, dynamic>) {
        json = event;
      }

      if (json == null) {
        logger.warning('[NtfyService] Could not parse event: $event');
        return;
      }

      logger.debug('[NtfyService] Received event JSON: $json');

      final message = NtfyMessage.tryParse(json);
      if (message == null) {
        logger.warning('[NtfyService] Invalid message format: $json');
        return;
      }

      if (message.isMessage) {
        logger.info(
          '[NtfyService] Adding in-app notification: ${message.title ?? "Arrmate"}',
        );
        final notification = await _notificationService.addFromNtfyMessage(
          message,
        );

        // Update shared timestamp so polling doesn't re-fetch this
        await InAppNotificationService.updateLastPollTimestamp(message.time);

        // Notify listeners
        onNotificationReceived?.call(notification);
        notifyListeners();
      } else if (message.isOpen) {
        logger.debug('[NtfyService] Connection opened');
      } else if (message.isKeepalive) {
        logger.debug('[NtfyService] Keepalive received');
      }
    } catch (e, stackTrace) {
      logger.error('[NtfyService] Error processing message', e, stackTrace);
    }
  }

  void _onError(Object error, [StackTrace? stackTrace]) {
    if (error is DioException && CancelToken.isCancel(error)) return;

    logger.error('[NtfyService] Stream error', error, stackTrace);
    _setConnected(false);
    _scheduleReconnect();
  }

  void _onDone() {
    logger.warning('[NtfyService] Stream closed');
    _setConnected(false);
    _scheduleReconnect();
  }

  Timer? _reconnectTimer;

  void _scheduleReconnect() {
    if (_currentTopic == null) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      // Verify if we still want to reconnect (topic not null)
      if (_currentTopic != null && !_isConnected) {
        logger.info('[NtfyService] Attempting reconnection...');
        try {
          // Check _currentTopic again inside try just to be safe async
          if (_currentTopic != null) {
            await connect(_currentTopic!);
          }
        } catch (e) {
          // Error already logged in connect
        }
      }
    });
  }

  /// Disconnects from the current topic and stops any reconnection attempts.
  Future<void> disconnect() async {
    logger.debug('[NtfyService] Disconnecting...');
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _cancelToken?.cancel();
    _cancelToken = null;

    await _subscription?.cancel();
    _subscription = null;

    _setConnected(false);
    _currentTopic = null;

    logger.debug('[NtfyService] Disconnected');
  }

  /// Fetches any missed notifications since the last poll/SSE message.
  ///
  /// Call this when the app opens to catch up on notifications
  /// that arrived while the app was closed.
  Future<void> fetchMissedNotifications(String topic) async {
    logger.info(
      '[NtfyService] Fetching missed notifications for topic: $topic',
    );

    try {
      final lastPoll = await InAppNotificationService.getLastPollTimestamp();
      final url = Uri.parse(
        'https://${NotificationSettings.ntfyServer}/$topic/json?poll=1&since=$lastPoll',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final lines = const LineSplitter().convert(response.body);
        int addedCount = 0;

        for (final line in lines) {
          if (line.trim().isEmpty) continue;

          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final message = NtfyMessage.tryParse(json);

            if (message != null && message.isMessage) {
              final notification = await _notificationService
                  .addFromNtfyMessage(message);
              onNotificationReceived?.call(notification);
              addedCount++;
            }
          } catch (_) {
            continue;
          }
        }

        await InAppNotificationService.updateLastPollTimestamp();
        logger.info('[NtfyService] Added $addedCount missed notifications');
        notifyListeners();
      }
    } catch (e, stackTrace) {
      logger.error(
        '[NtfyService] Failed to fetch missed notifications',
        e,
        stackTrace,
      );
    }
  }

  /// Generates a random topic ID for new setups.
  static String generateTopic() {
    final uuid = const Uuid().v4().replaceAll('-', '').substring(0, 12);
    final topic = 'arrmate-$uuid';
    logger.info('[NtfyService] Generated topic: $topic');
    return topic;
  }

  /// Tests the connection to a specific [topic].
  Future<void> testConnection(String topic) async {
    logger.info('[NtfyService] Testing connection to topic: $topic');
    try {
      final url =
          'https://${NotificationSettings.ntfyServer}/$topic/json?poll=1';
      await _dio.get(
        url,
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      logger.info('[NtfyService] Connection test successful');
    } catch (e, stackTrace) {
      logger.error('[NtfyService] Connection test failed', e, stackTrace);
      rethrow;
    }
  }
}
