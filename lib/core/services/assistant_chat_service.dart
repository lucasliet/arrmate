import 'dart:async';

import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import 'package:path_provider/path_provider.dart';

import 'logger_service.dart';

/// Handles a LiteRT-LM engine and active conversation.
class AssistantChatService {
  LiteLmEngine? _engine;
  LiteLmConversation? _conversation;
  String? _loadedModelPath;

  /// Loads a model and prepares a new conversation.
  Future<void> loadModel(String modelPath) async {
    if (_loadedModelPath == modelPath && _engine != null) {
      return;
    }

    await dispose();

    logger.info('[AssistantChatService] Loading model from: $modelPath');
    final supportDirectory = await getApplicationSupportDirectory();
    logger.info('[AssistantChatService] Cache dir: ${supportDirectory.path}');

    try {
      _engine = await LiteLmEngine.create(
        LiteLmEngineConfig(
          modelPath: modelPath,
          backend: LiteLmBackend.cpu,
          cacheDir: supportDirectory.path,
        ),
      );
      logger.info('[AssistantChatService] Engine created successfully');
    } catch (e, st) {
      logger.error('[AssistantChatService] Failed to create engine', e, st);
      rethrow;
    }

    try {
      _conversation = await _engine!.createConversation(
        const LiteLmConversationConfig(
          systemInstruction:
              'You are the Arrmate assistant. Answer in Portuguese. Use only the supplied app documentation and known app behavior. Do not invent unsupported features. Be concise and practical.',
          samplerConfig: LiteLmSamplerConfig(
            temperature: 0.4,
            topK: 40,
            topP: 0.95,
          ),
        ),
      );
      logger.info('[AssistantChatService] Conversation created successfully');
    } catch (e, st) {
      logger.error('[AssistantChatService] Failed to create conversation', e, st);
      rethrow;
    }

    _loadedModelPath = modelPath;
    logger.info('[AssistantChatService] Model loaded: $modelPath');
  }

  /// Sends a message to the current conversation.
  Future<String> sendMessage(String message, {String? extraContext}) async {
    final conversation = _conversation;
    if (conversation == null) {
      throw StateError('No conversation loaded.');
    }

    logger.info('[AssistantChatService] Sending message: ${message.substring(0, message.length.clamp(0, 80))}');

    final Map<String, Object>? contextMap = extraContext != null
        ? {'context': extraContext}
        : null;

    try {
      final reply = await conversation.sendMessage(
        message,
        extraContext: contextMap,
      );
      logger.info('[AssistantChatService] Reply received: ${reply.text.substring(0, reply.text.length.clamp(0, 80))}');
      return reply.text;
    } catch (e, st) {
      logger.error('[AssistantChatService] Failed to send message', e, st);
      rethrow;
    }
  }

  /// Releases the active conversation and engine.
  Future<void> dispose() async {
    final conversation = _conversation;
    final engine = _engine;
    _conversation = null;
    _engine = null;
    _loadedModelPath = null;

    if (conversation != null) {
      await conversation.dispose();
    }
    if (engine != null) {
      await engine.dispose();
    }
  }
}
