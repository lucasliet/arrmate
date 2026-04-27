/// Strips raw thinking/reasoning artifacts from LLM responses.
///
/// Handles:
/// - `<think ...>...</think ...>` blocks
/// - `<think ...>` / `</think ...>` and related variants
/// - leaked internal tool/planning sections
/// - Excessive blank lines left after removal.
String filterAssistantResponse(String rawText) {
  var text = rawText;

  text = text.replaceAll(_thinkingBlockRegex, '');
  text = text.replaceAll(_thinkTagRegex, '');
  text = _removeLeakedInternalPlan(text);
  text = text.replaceAll(_excessiveNewlines, '\n\n');

  return text.trim();
}

String _removeLeakedInternalPlan(String text) {
  final paragraphs = text
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  if (paragraphs.isEmpty) {
    return text;
  }

  final cleaned = paragraphs.where((paragraph) {
    final normalized = paragraph.toLowerCase();
    final hasInternalMarkers =
        normalized.contains('load_skill') ||
        normalized.contains('encontrar a skill') ||
        normalized.contains('usar a ferramenta') ||
        normalized.contains('seguir as instruções da skill') ||
        normalized.contains('tool call') ||
        normalized.contains('internal reasoning') ||
        normalized.contains('chain of thought');
    final looksLikeEnumeratedPlan = RegExp(
      r'^\s*1\.',
      multiLine: true,
    ).hasMatch(paragraph);

    return !(hasInternalMarkers && looksLikeEnumeratedPlan);
  }).toList();

  return cleaned.join('\n\n');
}

final _thinkingBlockRegex = RegExp(
  r'<(?:think|thinking|reasoning)[^>]*>[\s\S]*?<\/(?:think|thinking|reasoning)[^>]*>',
  caseSensitive: false,
);
final _thinkTagRegex = RegExp(
  r'</?(?:think|thinking|reasoning)[^>]*>',
  caseSensitive: false,
);
final _excessiveNewlines = RegExp(r'\n{3,}');
