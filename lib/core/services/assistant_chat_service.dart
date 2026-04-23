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
  ///
  /// [knowledgeBase] is injected into the system instruction so the model
  /// always has the app documentation available without needing per-message
  /// context.
  Future<void> loadModel(String modelPath, {String? knowledgeBase}) async {
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

    final systemPrompt = _buildSystemPrompt(knowledgeBase);

    try {
      _conversation = await _engine!.createConversation(
        LiteLmConversationConfig(
          systemInstruction: systemPrompt,
          samplerConfig: const LiteLmSamplerConfig(
            temperature: 0.4,
            topK: 40,
            topP: 0.95,
          ),
        ),
      );
      logger.info('[AssistantChatService] Conversation created successfully');
    } catch (e, st) {
      logger.error(
        '[AssistantChatService] Failed to create conversation',
        e,
        st,
      );
      rethrow;
    }

    _loadedModelPath = modelPath;
    logger.info('[AssistantChatService] Model loaded: $modelPath');
  }

  /// Sends a message to the current conversation.
  Future<String> sendMessage(String message) async {
    final conversation = _conversation;
    if (conversation == null) {
      throw StateError('No conversation loaded.');
    }

    logger.info(
      '[AssistantChatService] Sending message: ${message.substring(0, message.length.clamp(0, 80))}',
    );

    try {
      final reply = await conversation.sendMessage(message);
      logger.info(
        '[AssistantChatService] Reply received: ${reply.text.substring(0, reply.text.length.clamp(0, 80))}',
      );
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

  String _buildSystemPrompt(String? knowledgeBase) {
    final buffer = StringBuffer(
      'You are the Arrmate assistant. Answer in Portuguese. '
      'Use only the supplied app documentation and known app behavior. '
      'Do not invent unsupported features. Be concise and practical.',
    );

    if (knowledgeBase != null && knowledgeBase.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln()
        ..writeln('--- APP DOCUMENTATION ---')
        ..writeln(knowledgeBase)
        ..writeln('--- END OF DOCUMENTATION ---');
    }

    return buffer.toString();
  }
}
