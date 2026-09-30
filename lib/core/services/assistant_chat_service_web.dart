import 'assistant_knowledge_service.dart';

/// Web-safe adapter for the unavailable on-device assistant runtime.
class AssistantChatService {
  /// Associates the knowledge service used by supported assistant runtimes.
  void setKnowledgeService(AssistantKnowledgeService service) {}

  /// Rejects loading a native local model in a browser.
  Future<void> loadModel(String modelPath) => Future.error(
    UnsupportedError('The on-device assistant is unavailable on web.'),
  );

  /// Rejects local inference in a browser.
  Future<String> sendMessage(String message) => Future.error(
    UnsupportedError('The on-device assistant is unavailable on web.'),
  );

  /// Releases web adapter resources.
  Future<void> dispose() async {}
}
