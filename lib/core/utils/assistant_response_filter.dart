/// Strips raw thinking/reasoning artifacts from LLM responses.
///
/// Handles:
/// - Qwen 3 thinking lines starting with `##`
/// - `<think ...>` / `</think ...>` tags
/// - Excessive blank lines left after removal.
String filterAssistantResponse(String rawText) {
  var text = rawText;

  text = text.replaceAll(_thinkingLineRegex, '');
  text = text.replaceAll(_thinkTagRegex, '');
  text = text.replaceAll(_excessiveNewlines, '\n\n');

  return text.trim();
}

final _thinkingLineRegex = RegExp(r'^##\s+.*$', multiLine: true);
final _thinkTagRegex = RegExp(r'</?think[^>]*>');
final _excessiveNewlines = RegExp(r'\n{3,}');
