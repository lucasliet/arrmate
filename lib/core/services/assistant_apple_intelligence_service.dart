import 'package:apple_foundation_models/apple_foundation_models.dart';

import '../utils/assistant_response_filter.dart';
import 'assistant_knowledge_service.dart';
import 'logger_service.dart';

/// One conversation turn sent to the Apple Intelligence model.
class AssistantAppleIntelligenceTurn {
  /// Creates a conversation turn.
  const AssistantAppleIntelligenceTurn({
    required this.fromUser,
    required this.content,
  });

  /// Whether the user wrote this turn; otherwise the assistant did.
  final bool fromUser;

  /// Turn text.
  final String content;
}

/// Failure answering with Apple Intelligence, carrying a user-facing message.
class AssistantAppleIntelligenceException implements Exception {
  /// Creates an exception with a user-facing [message].
  const AssistantAppleIntelligenceException(this.message);

  /// Explanation shown to the user.
  final String message;

  @override
  String toString() => message;
}

/// User-facing descriptions of [AppleFoundationModelsAvailability] values.
extension AppleIntelligenceAvailabilityReason
    on AppleFoundationModelsAvailability {
  /// Why Apple Intelligence cannot be used, or `null` when it is available.
  String? get unavailableReason => switch (this) {
    AppleFoundationModelsAvailability.available => null,
    AppleFoundationModelsAvailability.deviceNotEligible =>
      'This device does not support Apple Intelligence.',
    AppleFoundationModelsAvailability.appleIntelligenceNotEnabled =>
      'Turn on Apple Intelligence in the system settings.',
    AppleFoundationModelsAvailability.modelNotReady =>
      'The Apple Intelligence model is still downloading. Try again later.',
    AppleFoundationModelsAvailability.unsupportedOsVersion =>
      'Apple Intelligence requires iOS 26 or macOS 26.',
    AppleFoundationModelsAvailability.unavailable =>
      'Apple Intelligence is unavailable on this device.',
  };
}

/// Answers assistant questions with the Apple Intelligence on-device model.
///
/// The system model shares a 4,096-token context window between instructions,
/// prompt and response, so every question runs in a fresh session carrying
/// only the most relevant documentation excerpts and the latest turns. When
/// the context still overflows, the question is retried with less of both.
class AssistantAppleIntelligenceService {
  /// Creates the service, optionally with a custom [models] client.
  AssistantAppleIntelligenceService({AppleFoundationModels? models})
    : _models = models ?? const AppleFoundationModels();

  /// Documentation and history budgets tried in order on context overflow.
  static const _attempts = [
    (documentationCharacters: 4500, historyTurns: 4),
    (documentationCharacters: 2000, historyTurns: 2),
    (documentationCharacters: 800, historyTurns: 0),
  ];
  static const _maxTurnCharacters = 400;
  static const _maxResponseTokens = 700;
  static const _temperature = 0.4;

  final AppleFoundationModels _models;

  /// Returns whether the Apple Intelligence model can answer right now.
  Future<AppleFoundationModelsAvailability> checkAvailability() async {
    try {
      return await _models.availability();
    } catch (e, st) {
      logger.warning(
        '[AssistantAppleIntelligenceService] Failed to check availability',
        e,
        st,
      );
      return AppleFoundationModelsAvailability.unavailable;
    }
  }

  /// Answers the last user turn of [conversation] using [knowledgeService].
  ///
  /// Throws [AssistantAppleIntelligenceException] when the model fails.
  Future<String> sendMessage(
    List<AssistantAppleIntelligenceTurn> conversation,
    AssistantKnowledgeService knowledgeService,
  ) async {
    final question = conversation.last.content;
    final history = conversation.sublist(0, conversation.length - 1);

    for (final (index, attempt) in _attempts.indexed) {
      final documentation = await knowledgeService.loadRelevantExcerpts(
        question,
        maxCharacters: attempt.documentationCharacters,
      );

      try {
        final reply = await _models.respond(
          instructions: _buildInstructions(documentation),
          prompt: _buildPrompt(question, history, attempt.historyTurns),
          temperature: _temperature,
          maximumResponseTokens: _maxResponseTokens,
        );
        final content = filterAssistantResponse(reply);
        if (content.isEmpty) {
          throw const AppleFoundationModelsException(
            AppleFoundationModelsError.generationFailed,
            'The model returned an empty response.',
          );
        }
        return content;
      } on AppleFoundationModelsException catch (e, st) {
        final canRetry =
            e.error == AppleFoundationModelsError.contextWindowExceeded &&
            index < _attempts.length - 1;
        if (canRetry) {
          logger.warning(
            '[AssistantAppleIntelligenceService] Context window exceeded, '
            'retrying with less context',
            e,
            st,
          );
          continue;
        }

        logger.error(
          '[AssistantAppleIntelligenceService] Failed to generate a response',
          e,
          st,
        );
        throw AssistantAppleIntelligenceException(_messageFor(e.error));
      }
    }

    throw StateError('Apple Intelligence retries exhausted.');
  }

  String _buildInstructions(String documentation) {
    return 'Você é o assistente virtual do Arrmate, um app para gerenciar '
        'servidores Radarr, Sonarr e qBittorrent. Responda sempre em '
        'Português do Brasil.\n\n'
        'REGRAS:\n'
        '- Fale como parte do Arrmate e responda diretamente, sem mencionar '
        'documentação, instruções ou detalhes internos.\n'
        '- Seja conciso e prático. Dê instruções passo a passo quando '
        'relevante.\n'
        '- Use APENAS as informações da documentação abaixo. Se ela não cobrir '
        'a pergunta, diga que não encontrou essa informação sobre o Arrmate.\n'
        '- Se a pergunta não for sobre o Arrmate, diga que só pode ajudar com '
        'dúvidas sobre o app.\n\n'
        'DOCUMENTAÇÃO DO ARRMATE:\n'
        '$documentation';
  }

  String _buildPrompt(
    String question,
    List<AssistantAppleIntelligenceTurn> history,
    int historyTurns,
  ) {
    final recentHistory = history.length > historyTurns
        ? history.sublist(history.length - historyTurns)
        : history;
    if (recentHistory.isEmpty) {
      return question;
    }

    final transcript = recentHistory
        .map(
          (turn) =>
              '${turn.fromUser ? 'Usuário' : 'Assistente'}: '
              '${_truncate(turn.content)}',
        )
        .join('\n');

    return 'CONVERSA ANTERIOR:\n$transcript\n\nPERGUNTA ATUAL:\n$question';
  }

  String _truncate(String content) {
    return content.length > _maxTurnCharacters
        ? '${content.substring(0, _maxTurnCharacters)}…'
        : content;
  }

  String _messageFor(AppleFoundationModelsError error) {
    return switch (error) {
      AppleFoundationModelsError.contextWindowExceeded =>
        'The question is too long for Apple Intelligence. Try a shorter one.',
      AppleFoundationModelsError.guardrailViolation ||
      AppleFoundationModelsError.refusal =>
        'Apple Intelligence declined to answer. Try rephrasing the question.',
      AppleFoundationModelsError.unsupportedLanguage =>
        'Apple Intelligence does not support this language on this device.',
      AppleFoundationModelsError.assetsUnavailable =>
        'The Apple Intelligence model is not ready yet. Try again later.',
      AppleFoundationModelsError.rateLimited ||
      AppleFoundationModelsError.busy =>
        'Apple Intelligence is busy. Try again in a moment.',
      AppleFoundationModelsError.unavailable =>
        'Apple Intelligence is unavailable on this device.',
      AppleFoundationModelsError.invalidArguments ||
      AppleFoundationModelsError.generationFailed =>
        'Apple Intelligence failed to generate a response.',
    };
  }
}
