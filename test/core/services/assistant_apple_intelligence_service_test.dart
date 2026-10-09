import 'package:apple_foundation_models/apple_foundation_models.dart';
import 'package:arrmate/core/services/assistant_apple_intelligence_service.dart';
import 'package:arrmate/core/services/assistant_knowledge_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const conversation = [
    AssistantAppleIntelligenceTurn(fromUser: true, content: 'Primeira'),
    AssistantAppleIntelligenceTurn(fromUser: false, content: 'Resposta 1'),
    AssistantAppleIntelligenceTurn(fromUser: true, content: 'Segunda'),
    AssistantAppleIntelligenceTurn(fromUser: false, content: 'Resposta 2'),
    AssistantAppleIntelligenceTurn(fromUser: true, content: 'Terceira'),
    AssistantAppleIntelligenceTurn(fromUser: false, content: 'Resposta 3'),
    AssistantAppleIntelligenceTurn(fromUser: true, content: 'Como uso?'),
  ];

  group('AssistantAppleIntelligenceService', () {
    test('sends documentation as instructions and recent turns', () async {
      final models = _FakeModels(['Use o menu.']);
      final knowledge = _TestKnowledgeService();
      final service = AssistantAppleIntelligenceService(models: models);

      final reply = await service.sendMessage(conversation, knowledge);

      expect(reply, 'Use o menu.');
      expect(knowledge.budgets, [4500]);
      expect(knowledge.questions, ['Como uso?']);
      final request = models.requests.single;
      expect(request.instructions, contains('Docs (4500)'));
      expect(request.instructions, contains('Português do Brasil'));
      expect(request.prompt, isNot(contains('Primeira')));
      expect(request.prompt, isNot(contains('Resposta 1')));
      expect(request.prompt, contains('Usuário: Segunda'));
      expect(request.prompt, contains('Assistente: Resposta 3'));
      expect(request.prompt, endsWith('PERGUNTA ATUAL:\nComo uso?'));
      expect(request.maximumResponseTokens, greaterThan(0));
    });

    test('sends only the question when there is no history', () async {
      final models = _FakeModels(['Ok']);
      final service = AssistantAppleIntelligenceService(models: models);

      await service.sendMessage(const [
        AssistantAppleIntelligenceTurn(fromUser: true, content: 'Oi'),
      ], _TestKnowledgeService());

      expect(models.requests.single.prompt, 'Oi');
    });

    test('shrinks documentation and history when context overflows', () async {
      final models = _FakeModels([
        const AppleFoundationModelsException(
          AppleFoundationModelsError.contextWindowExceeded,
        ),
        const AppleFoundationModelsException(
          AppleFoundationModelsError.contextWindowExceeded,
        ),
        'Resposta curta',
      ]);
      final knowledge = _TestKnowledgeService();
      final service = AssistantAppleIntelligenceService(models: models);

      final reply = await service.sendMessage(conversation, knowledge);

      expect(reply, 'Resposta curta');
      expect(knowledge.budgets, [4500, 2000, 800]);
      expect(models.requests[1].prompt, isNot(contains('Segunda')));
      expect(models.requests[1].prompt, contains('Resposta 3'));
      expect(models.requests.last.prompt, 'Como uso?');
    });

    test('reports a long question once every budget overflows', () async {
      final models = _FakeModels(
        List.filled(
          3,
          const AppleFoundationModelsException(
            AppleFoundationModelsError.contextWindowExceeded,
          ),
        ),
      );
      final service = AssistantAppleIntelligenceService(models: models);

      await expectLater(
        service.sendMessage(conversation, _TestKnowledgeService()),
        throwsA(
          isA<AssistantAppleIntelligenceException>().having(
            (e) => e.message,
            'message',
            contains('too long'),
          ),
        ),
      );
      expect(models.requests, hasLength(3));
    });

    test('does not retry other failures', () async {
      final models = _FakeModels([
        const AppleFoundationModelsException(
          AppleFoundationModelsError.guardrailViolation,
        ),
      ]);
      final service = AssistantAppleIntelligenceService(models: models);

      await expectLater(
        service.sendMessage(conversation, _TestKnowledgeService()),
        throwsA(
          isA<AssistantAppleIntelligenceException>().having(
            (e) => e.message,
            'message',
            contains('declined'),
          ),
        ),
      );
      expect(models.requests, hasLength(1));
    });

    test('rejects empty replies', () async {
      final service = AssistantAppleIntelligenceService(
        models: _FakeModels(['  ']),
      );

      await expectLater(
        service.sendMessage(conversation, _TestKnowledgeService()),
        throwsA(isA<AssistantAppleIntelligenceException>()),
      );
    });

    test('reports unavailable when the availability check fails', () async {
      final service = AssistantAppleIntelligenceService(
        models: _FakeModels(const [], availabilityError: StateError('boom')),
      );

      expect(
        await service.checkAvailability(),
        AppleFoundationModelsAvailability.unavailable,
      );
    });
  });

  test('describes why Apple Intelligence is unavailable', () {
    expect(AppleFoundationModelsAvailability.available.unavailableReason, null);
    for (final availability in AppleFoundationModelsAvailability.values.where(
      (value) => value != AppleFoundationModelsAvailability.available,
    )) {
      expect(availability.unavailableReason, isNotEmpty);
    }
  });
}

class _Request {
  const _Request(this.instructions, this.prompt, this.maximumResponseTokens);

  final String instructions;
  final String prompt;
  final int? maximumResponseTokens;
}

class _FakeModels implements AppleFoundationModels {
  _FakeModels(this.responses, {this.availabilityError});

  final List<Object> responses;
  final Object? availabilityError;
  final List<_Request> requests = [];

  @override
  Future<AppleFoundationModelsAvailability> availability() async {
    final error = availabilityError;
    if (error != null) {
      throw error;
    }
    return AppleFoundationModelsAvailability.available;
  }

  @override
  Future<String> respond({
    required String instructions,
    required String prompt,
    double? temperature,
    int? maximumResponseTokens,
  }) async {
    final response = responses[requests.length];
    requests.add(_Request(instructions, prompt, maximumResponseTokens));
    if (response is Exception) {
      throw response;
    }
    return response as String;
  }
}

class _TestKnowledgeService extends AssistantKnowledgeService {
  final List<String> questions = [];
  final List<int> budgets = [];

  @override
  Future<String> loadRelevantExcerpts(
    String question, {
    required int maxCharacters,
  }) async {
    questions.add(question);
    budgets.add(maxCharacters);
    return 'Docs ($maxCharacters)';
  }
}
