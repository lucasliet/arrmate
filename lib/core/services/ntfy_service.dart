import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ntfluttery/ntfluttery.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/notification/ntfy_message.dart';
import '../../domain/models/settings/notification_settings.dart';
import 'logger_service.dart';
import 'notification_service.dart';

final ntfyServiceProvider = Provider<NtfyService>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return NtfyService(notificationService);
});

class NtfyService {
  final NotificationService _notificationService;

  NtflutteryService? _client;
  StreamSubscription<dynamic>? _subscription;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _currentTopic;
  String? get currentTopic => _currentTopic;

  int _notificationIdCounter = 0;

  NtfyService(this._notificationService);

  Future<void> connect(String topic) async {
    if (_currentTopic == topic && _isConnected) {
      logger.debug('[NtfyService] Already connected to topic: $topic');
      return;
    }

    await disconnect();

    logger.info('[NtfyService] Connecting to topic: $topic');
    _currentTopic = topic;

    try {
      _client = NtflutteryService();

      final url = 'https://${NotificationSettings.ntfyServer}/$topic/json';
      logger.debug('[NtfyService] Stream URL: $url');

      final result = await _client!.get(url);

      _subscription = result.$1.listen(
        onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _isConnected = true;
      logger.info('[NtfyService] Connected successfully to topic: $topic');
    } catch (e, stackTrace) {
      logger.error('[NtfyService] Failed to connect', e, stackTrace);
      _isConnected = false;
      rethrow;
    }
  }

  @visibleForTesting
  void onMessage(dynamic event) {
    try {
      logger.debug('[NtfyService] Received event: $event');

      Map<String, dynamic>? json;

      if (event is (Map<String, dynamic>?, dynamic)) {
        json = event.$1;
      } else if (event is String) {
        json = jsonDecode(event) as Map<String, dynamic>;
      } else if (event is Map<String, dynamic>) {
        json = event;
      }

      if (json == null) {
        logger.warning('[NtfyService] Could not parse event: $event');
        return;
      }

      final message = NtfyMessage.tryParse(json);
      if (message == null) {
        logger.warning('[NtfyService] Invalid message format: $json');
        return;
      }

      logger.debug(
        '[NtfyService] Parsed message: event=${message.event}, title=${message.title}',
      );

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
    logger.error('[NtfyService] Stream error', error, stackTrace);
    _isConnected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    logger.warning('[NtfyService] Stream closed');
    _isConnected = false;
    _scheduleReconnect();
  }

  Timer? _reconnectTimer;

  void _scheduleReconnect() {
    if (_currentTopic == null) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (_currentTopic != null && !_isConnected) {
        logger.info('[NtfyService] Attempting reconnection...');
        try {
          await connect(_currentTopic!);
        } catch (e, stackTrace) {
          logger.error('[NtfyService] Reconnection failed', e, stackTrace);
        }
      }
    });
  }

  Future<void> disconnect() async {
    logger.debug('[NtfyService] Disconnecting...');
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _subscription?.cancel();
    _subscription = null;
    _client = null;
    _isConnected = false;
    _currentTopic = null;

    logger.debug('[NtfyService] Disconnected');
  }

  static String generateTopic() {
    final uuid = const Uuid().v4().replaceAll('-', '').substring(0, 12);
    final topic = 'arrmate-$uuid';
    logger.info('[NtfyService] Generated topic: $topic');
    return topic;
  }

  Future<void> testConnection(String topic) async {
    logger.info('[NtfyService] Testing connection to topic: $topic');
    try {
      final client = NtflutteryService();
      final url =
          'https://${NotificationSettings.ntfyServer}/$topic/json?poll=0';
      await client
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Connection test timed out'),
          );
      logger.info('[NtfyService] Connection test successful');
    } catch (e, stackTrace) {
      logger.error('[NtfyService] Connection test failed', e, stackTrace);
      rethrow;
    }
  }
}
