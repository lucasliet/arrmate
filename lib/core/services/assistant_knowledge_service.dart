import 'package:flutter/services.dart';

/// Represents one section from the live knowledge base.
class AssistantKnowledgeSection {
  /// Creates a knowledge section.
  const AssistantKnowledgeSection({required this.title, required this.content});

  /// Section title.
  final String title;

  /// Section body.
  final String content;
}

/// Loads and ranks the Arrmate live documentation used by the assistant.
class AssistantKnowledgeService {
  /// Loads the markdown knowledge base and splits it into sections.
  Future<List<AssistantKnowledgeSection>> loadSections() async {
    final markdown = await rootBundle.loadString(
      'assets/assistant/knowledge.md',
    );
    return _parseSections(markdown);
  }

  /// Returns the best matching sections for the provided query.
  Future<List<AssistantKnowledgeSection>> findRelevantSections(
    String query, {
    int limit = 3,
  }) async {
    final sections = await loadSections();
    final tokens = _tokens(query);

    final scored = sections.map((section) {
      final score = _score(section, tokens);
      return (section: section, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored
        .where((item) => item.score > 0)
        .take(limit)
        .map((item) => item.section)
        .toList();
  }

  /// Formats the selected sections into a compact context block.
  Future<String> buildContext(String query) async {
    final sections = await findRelevantSections(query);
    if (sections.isEmpty) {
      return 'No relevant documentation was found.';
    }

    final buffer = StringBuffer();
    for (final section in sections) {
      buffer
        ..writeln('## ${section.title}')
        ..writeln(section.content.trim())
        ..writeln();
    }
    return buffer.toString().trim();
  }

  List<AssistantKnowledgeSection> _parseSections(String markdown) {
    final lines = markdown.split('\n');
    final sections = <AssistantKnowledgeSection>[];
    String? currentTitle;
    final currentContent = StringBuffer();

    void flush() {
      if (currentTitle == null) {
        return;
      }
      sections.add(
        AssistantKnowledgeSection(
          title: currentTitle!,
          content: currentContent.toString().trim(),
        ),
      );
      currentContent.clear();
    }

    for (final line in lines) {
      if (line.startsWith('## ')) {
        flush();
        currentTitle = line.substring(3).trim();
        continue;
      }

      if (currentTitle != null) {
        currentContent.writeln(line);
      }
    }

    flush();
    return sections;
  }

  int _score(AssistantKnowledgeSection section, List<String> tokens) {
    final title = section.title.toLowerCase();
    final body = section.content.toLowerCase();
    var score = 0;

    for (final token in tokens) {
      if (token.isEmpty) {
        continue;
      }

      final titleMatches = _countOccurrences(title, token);
      final bodyMatches = _countOccurrences(body, token);
      score += titleMatches * 4;
      score += bodyMatches * 2;
    }

    return score;
  }

  int _countOccurrences(String text, String token) {
    var count = 0;
    var start = 0;

    while (true) {
      final index = text.indexOf(token, start);
      if (index == -1) {
        break;
      }
      count += 1;
      start = index + token.length;
    }

    return count;
  }

  List<String> _tokens(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áàâãéêíóôõúç ]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }
}
