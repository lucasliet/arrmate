import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/notification/ntfy_message.dart';
import '../../domain/models/settings/notification_settings.dart';
import 'background_notification_service.dart';
import 'logger_service.dart';
import 'notification_service.dart';

final ntfyServiceProvider = ChangeNotifierProvider<NtfyService>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return NtfyService(notificationService);
});

/// Service for connecting to an ntfy server to receive real-time notifications via SSE (Server-Sent Events).
class NtfyService extends ChangeNotifier {
  final NotificationService _notificationService;
  final Dio _dio;
  CancelToken? _cancelToken;
  StreamSubscription<dynamic>? _subscription;

  bool _isConnected = false;

  /// Returns true if the service is currently connected to an ntfy stream.
  bool get isConnected => _isConnected;

  String? _currentTopic;

  /// The topic currently subscribed to.
  String? get currentTopic => _currentTopic;

  int _notificationIdCounter = 0;

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
  void onMessage(dynamic event) {
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
          '[NtfyService] Showing notification: ${message.title ?? "Arrmate"}',
        );
        _notificationService.showNotification(
          id: _nextNotificationId(),
          title: message.title ?? 'Arrmate',
          body: message.message ?? '',
          payload: message.click,
        );
        // Update shared timestamp so background polling doesn't re-fetch this
        BackgroundNotificationService.updateLastPollTimestamp(message.time);
      } else if (message.isOpen) {
        logger.debug('[NtfyService] Connection opened');
      } else if (message.isKeepalive) {
        logger.debug('[NtfyService] Keepalive received');
      }
    } catch (e, stackTrace) {
      logger.error('[NtfyService] Error processing message', e, stackTrace);
    }
  }

  int _nextNotificationId() {
    _notificationIdCounter++;
    if (_notificationIdCounter > 0x7FFFFFFF) {
      _notificationIdCounter = 0;
    }
    return _notificationIdCounter;
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
