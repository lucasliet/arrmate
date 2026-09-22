import 'dart:async';

import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/assistant_response_filter.dart';
import 'assistant_knowledge_service.dart';
import 'logger_service.dart';

const _loadSkillTool = LiteLmTool(
  name: 'load_skill',
  description: 'Loads a skill by name. Returns the skill instructions.',
  parameters: {
    'type': 'object',
    'properties': {
      'skill_name': {
        'type': 'string',
        'description': 'The name of the skill to load.',
      },
    },
    'required': ['skill_name'],
  },
);

class AssistantChatService {
  LiteLmEngine? _engine;
  LiteLmConversation? _conversation;
  String? _loadedModelPath;
  AssistantKnowledgeService? _knowledgeService;

  void setKnowledgeService(AssistantKnowledgeService service) {
    _knowledgeService = service;
  }

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

    final systemPrompt = _buildSystemPrompt();

    try {
      _conversation = await _engine!.createConversation(
        LiteLmConversationConfig(
          systemInstruction: systemPrompt,
          tools: [_loadSkillTool],
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

  Future<String> sendMessage(String message) async {
    final conversation = _conversation;
    if (conversation == null) {
      throw StateError('No conversation loaded.');
    }

    logger.info(
      '[AssistantChatService] Sending message: ${message.substring(0, message.length.clamp(0, 80))}',
    );

    try {
      final rawReply = await _sendWithToolLoop(conversation, message);

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
    if (call.name != 'load_skill') {
      return 'Unknown tool: ${call.name}';
    }

    final knowledgeService = _knowledgeService;
    if (knowledgeService == null) {
      return 'Knowledge service not available.';
    }

    final skillName = call.arguments['skill_name'] as String? ?? '';
    if (skillName.isEmpty) {
      return 'Empty skill name.';
    }

    logger.info('[AssistantChatService] Loading skill: $skillName');

    return knowledgeService.loadSkill(skillName);
  }

  String _buildSystemPrompt() {
    final knowledgeService = _knowledgeService;
    if (knowledgeService == null) {
      return 'Você é o assistente do Arrmate. Responda em Português.';
    }

    final skillDescriptions = knowledgeService.getSkillDescriptions();

    return 'Você é o assistente virtual do Arrmate, um app mobile para gerenciar '
        'servidores Radarr, Sonarr e qBittorrent. Responda em Português.\n\n'
        'REGRAS DE COMPORTAMENTO:\n'
        '- Aja como um assistente integrado ao app. Fale como parte do Arrmate.\n'
        '- NUNCA mencione skills, tool-calling, ferramentas internas, load_skill, '
        'documentação carregada ou qualquer detalhe do seu funcionamento interno.\n'
        '- NUNCA diga frases como "vou consultar a skill", "de acordo com a documentação", '
        '"segundo as instruções carregadas" ou similares.\n'
        '- Responda diretamente como se você já soubesse a informação.\n'
        '- Seja conciso e prático. Dê instruções passo a passo quando relevante.\n\n'
        'PROCESSO INTERNO (invisível ao usuário):\n'
        '1. Encontrar a skill mais relevante na lista abaixo.\n'
        '2. Usar a ferramenta load_skill para carregar as instruções.\n'
        '3. Responder com base nas instruções, sem revelar o processo.\n\n'
        'Skills disponíveis:\n'
        '$skillDescriptions\n\n'
        'Responda APENAS com base na documentação carregada. '
        'Não invente recursos que não existem no app.\n'
        'Se a pergunta for irrelevante ao Arrmate, diga que só pode ajudar '
        'com dúvidas sobre o app.';
  }
}
