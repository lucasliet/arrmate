import 'dart:async';

import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/assistant_response_filter.dart';
import 'assistant_knowledge_service.dart';
import 'logger_service.dart';

const _searchKnowledgeTool = LiteLmTool(
  name: 'search_knowledge',
  description:
      'Search Arrmate documentation for features, settings, and usage. '
      'Call this whenever you need app-specific information to answer a question.',
  parameters: {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': 'Search query about Arrmate features or usage',
      },
    },
    'required': ['query'],
  },
);

/// Handles a LiteRT-LM engine and active conversation.
class AssistantChatService {
  LiteLmEngine? _engine;
  LiteLmConversation? _conversation;
  String? _loadedModelPath;

  bool _toolCallingEnabled = false;
  AssistantKnowledgeService? _knowledgeService;

  /// Injects the knowledge service used for tool-calling lookups.
  void setKnowledgeService(AssistantKnowledgeService service) {
    _knowledgeService = service;
  }

  /// Loads a model and prepares a new conversation.
  ///
  /// When [enableToolCalling] is true, the model receives a compact system
  /// prompt without the full knowledge base and gets the `search_knowledge`
  /// tool registered for agentic retrieval. Otherwise the full knowledge base
  /// is injected into the system instruction (legacy path).
  Future<void> loadModel(
    String modelPath, {
    String? knowledgeBase,
    bool enableToolCalling = false,
  }) async {
    if (_loadedModelPath == modelPath && _engine != null) {
      return;
    }

    await dispose();

    _toolCallingEnabled = enableToolCalling;

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

    final systemPrompt = enableToolCalling
        ? _buildToolCallingSystemPrompt()
        : _buildSystemPrompt(knowledgeBase);

    try {
      _conversation = await _engine!.createConversation(
        LiteLmConversationConfig(
          systemInstruction: systemPrompt,
          tools: enableToolCalling ? [_searchKnowledgeTool] : null,
          automaticToolCalling: false,
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
      final rawReply = _toolCallingEnabled
          ? await _sendWithToolLoop(conversation, message)
          : await conversation.sendMessage(message);

      final filtered = filterAssistantResponse(rawReply.text);
      logger.info(
        '[AssistantChatService] Reply received: ${filtered.substring(0, filtered.length.clamp(0, 80))}',
      );
      return filtered;
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
    _toolCallingEnabled = false;

    if (conversation != null) {
      await conversation.dispose();
    }
    if (engine != null) {
      await engine.dispose();
    }
  }

  Future<LiteLmMessage> _sendWithToolLoop(
    LiteLmConversation conversation,
    String message,
  ) async {
    const maxIterations = 5;
    var reply = await conversation.sendMessage(message);

    for (var i = 0; i < maxIterations; i++) {
      if (reply.toolCalls.isEmpty) {
        return reply;
      }

      for (final toolCall in reply.toolCalls) {
        logger.info(
          '[AssistantChatService] Tool call: ${toolCall.name}(${toolCall.arguments})',
        );
        final result = await _executeToolCall(toolCall);
        reply = await conversation.sendToolResponse(toolCall.name, result);
      }
    }

    return reply;
  }

  Future<String> _executeToolCall(LiteLmToolCall call) async {
    if (call.name != 'search_knowledge') {
      return 'Unknown tool: ${call.name}';
    }

    final knowledgeService = _knowledgeService;
    if (knowledgeService == null) {
      return 'Knowledge service not available.';
    }

    final query = call.arguments['query'] as String? ?? '';
    if (query.isEmpty) {
      return 'Empty query.';
    }

    logger.info('[AssistantChatService] Searching knowledge: $query');

    final context = await knowledgeService.buildContext(query);
    if (context == 'No relevant documentation was found.') {
      return context;
    }

    return context;
  }

  String _buildSystemPrompt(String? knowledgeBase) {
    final buffer = StringBuffer(
      'You are the Arrmate assistant. Answer in Portuguese. '
      'You must ONLY answer questions about the Arrmate app. '
      'Use only the supplied app documentation and known app behavior. '
      'If the information is not in the documentation or the question is unrelated to Arrmate, '
      'you must explicitly state that you did not find the information. '
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

  String _buildToolCallingSystemPrompt() {
    return 'Você é o assistente do Arrmate. Responda em Português.\n'
        'Você DEVE responder APENAS perguntas sobre o aplicativo Arrmate.\n'
        'Sempre que o usuário fizer uma pergunta sobre o app (recursos, uso, configurações, etc), '
        'você DEVE utilizar a ferramenta search_knowledge para buscar o contexto atualizado na documentação ANTES de responder.\n'
        'Não confie em seu conhecimento prévio. Não invente recursos não suportados. Seja conciso e prático.\n'
        'Se a informação não for encontrada pela ferramenta ou a pergunta for irrelevante ao Arrmate, '
        'diga explicitamente que não encontrou a informação.';
  }
}
