import 'dart:ui';

import 'package:apple_foundation_models/apple_foundation_models.dart';

import '../l10n/app_locale.dart';

import '../utils/assistant_response_filter.dart';
import 'assistant_knowledge_service.dart';
import 'assistant_reply_language.dart';
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
  /// Creates an exception with a user-facing [message], optionally tagged
  /// with the model [error] it was derived from.
  const AssistantAppleIntelligenceException(this.message, {this.error});

  /// Explanation shown to the user, in English.
  final String message;

  /// The model failure behind this exception, when known; used to translate
  /// [message] (see [localizedMessage]).
  final AppleFoundationModelsError? error;

  /// Returns [message] in the language of [l10n].
  ///
  /// Falls back to the English [message] when no [error] was recorded.
  String localizedMessage(AppLocalizations l10n) {
    final error = this.error;
    return error == null ? message : _errorMessage(error, l10n);
  }

  @override
  String toString() => message;
}

/// English translations, backing the English-only getters kept for logs and
/// tests.
final AppLocalizations _english = appLocalizationsFor(const Locale('en'));

/// User-facing descriptions of [AppleFoundationModelsAvailability] values.
extension AppleIntelligenceAvailabilityReason
    on AppleFoundationModelsAvailability {
  /// Why Apple Intelligence cannot be used, in English, or `null` when it is
  /// available.
  String? get unavailableReason => localizedUnavailableReason(_english);

  /// Why Apple Intelligence cannot be used, in the language of [l10n], or
  /// `null` when it is available.
  String? localizedUnavailableReason(AppLocalizations l10n) => switch (this) {
    AppleFoundationModelsAvailability.available => null,
    AppleFoundationModelsAvailability.deviceNotEligible =>
      l10n.appleIntelligenceDeviceNotEligible,
    AppleFoundationModelsAvailability.appleIntelligenceNotEnabled =>
      l10n.appleIntelligenceNotEnabled,
    AppleFoundationModelsAvailability.modelNotReady =>
      l10n.appleIntelligenceModelNotReady,
    AppleFoundationModelsAvailability.unsupportedOsVersion =>
      l10n.appleIntelligenceUnsupportedOs,
    AppleFoundationModelsAvailability.unavailable =>
      l10n.appleIntelligenceUnavailable,
  };
}

/// Describes a model [error] in the language of [l10n].
String _errorMessage(AppleFoundationModelsError error, AppLocalizations l10n) {
  return switch (error) {
    AppleFoundationModelsError.contextWindowExceeded =>
      l10n.appleIntelligenceContextTooLong,
    AppleFoundationModelsError.guardrailViolation ||
    AppleFoundationModelsError.refusal => l10n.appleIntelligenceDeclined,
    AppleFoundationModelsError.unsupportedLanguage =>
      l10n.appleIntelligenceUnsupportedLanguage,
    AppleFoundationModelsError.assetsUnavailable =>
      l10n.appleIntelligenceAssetsUnavailable,
    AppleFoundationModelsError.rateLimited ||
    AppleFoundationModelsError.busy => l10n.appleIntelligenceBusy,
    AppleFoundationModelsError.unavailable => l10n.appleIntelligenceUnavailable,
    AppleFoundationModelsError.invalidArguments ||
    AppleFoundationModelsError.generationFailed =>
      l10n.appleIntelligenceGenerationFailed,
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
  /// [languageCode] is the interface language the reply must be written in.
  /// Throws [AssistantAppleIntelligenceException] when the model fails.
  Future<String> sendMessage(
    List<AssistantAppleIntelligenceTurn> conversation,
    AssistantKnowledgeService knowledgeService, {
    String languageCode = 'pt',
  }) async {
    final question = conversation.last.content;
    final history = conversation.sublist(0, conversation.length - 1);

    for (final (index, attempt) in _attempts.indexed) {
      final documentation = await knowledgeService.loadRelevantExcerpts(
        question,
        maxCharacters: attempt.documentationCharacters,
      );

      try {
        final reply = await _models.respond(
          instructions: _buildInstructions(documentation, languageCode),
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
        throw AssistantAppleIntelligenceException(
          _errorMessage(e.error, _english),
          error: e.error,
        );
      }
    }

    throw StateError('Apple Intelligence retries exhausted.');
  }

  String _buildInstructions(String documentation, String languageCode) {
    return 'Você é o assistente virtual do Arrmate, um app para gerenciar '
        'servidores Radarr, Sonarr e qBittorrent. '
        '${assistantReplyInstruction(languageCode)}\n\n'
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
}
