import 'package:arrmate/core/services/assistant_knowledge_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssistantKnowledgeService.loadRelevantExcerpts', () {
    final service = AssistantKnowledgeService();

    test('returns nothing without a budget', () async {
      expect(
        await service.loadRelevantExcerpts(
          'Como adicionar um filme?',
          maxCharacters: 0,
        ),
        isEmpty,
      );
    });

    test(
      'starts with the section whose heading matches the question',
      () async {
        final excerpts = await service.loadRelevantExcerpts(
          'Como deletar um filme da biblioteca?',
          maxCharacters: 4500,
        );

        expect(excerpts, startsWith('## Deletar filme da biblioteca'));
        expect(excerpts.length, lessThanOrEqualTo(4500));
        expect(excerpts, isNot(contains('name: movies')));
      },
    );

    test('never exceeds the budget, truncating the best section', () async {
      for (final budget in [120, 800, 2000]) {
        final excerpts = await service.loadRelevantExcerpts(
          'Detalhes do filme',
          maxCharacters: budget,
        );

        expect(excerpts, isNotEmpty);
        expect(excerpts.length, lessThanOrEqualTo(budget));
      }
    });

    test('falls back to general sections for unrelated questions', () async {
      final excerpts = await service.loadRelevantExcerpts(
        'xyz',
        maxCharacters: 1500,
      );

      expect(excerpts, isNotEmpty);
      expect(excerpts.length, lessThanOrEqualTo(1500));
    });
  });
}
