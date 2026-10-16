/// Builds the system-prompt sentence telling the assistant which language to
/// answer in.
///
/// The prompts and the documentation are written in Portuguese, so the
/// instruction explicitly asks for the reply language even when it differs
/// from the documentation. [languageCode] is the interface language code
/// (`en`, `pt` or `es`); unknown codes fall back to Brazilian Portuguese.
String assistantReplyInstruction(String languageCode) {
  return switch (languageCode) {
    'en' =>
      'Responda SEMPRE em inglês (English), mesmo que a documentação esteja '
          'em português.',
    'es' =>
      'Responda SEMPRE em espanhol (Español), mesmo que a documentação esteja '
          'em português.',
    _ => 'Responda sempre em Português do Brasil.',
  };
}
