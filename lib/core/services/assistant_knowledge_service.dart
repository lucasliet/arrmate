import 'package:flutter/services.dart';

/// Loads the Arrmate live documentation used by the assistant.
class AssistantKnowledgeService {
  /// Returns the full knowledge base markdown content.
  Future<String> loadFullKnowledgeBase() async {
    return rootBundle.loadString('assets/assistant/knowledge.md');
  }
}
