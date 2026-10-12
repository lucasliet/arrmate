import 'dart:convert';

import 'package:arrmate/core/services/assistant_knowledge_service.dart';
import 'package:arrmate/core/services/assistant_online_chat_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssistantOnlineChatService', () {
    const history = [
      AssistantOnlineChatMessage(
        role: AssistantOnlineMessageRole.user,
        content: 'Como adiciono uma instância?',
      ),
    ];

    AssistantOnlineChatService buildService(_AdapterStub adapter) {
      return AssistantOnlineChatService(
        dio: Dio(BaseOptions(baseUrl: 'https://adapter.test'))
          ..httpClientAdapter = adapter,
      );
    }

    test('should call chat completions with the auto model', () async {
      final adapter = _AdapterStub();
      final service = buildService(adapter);

      final result = await service.sendMessage(
        history,
        _TestKnowledgeService(),
      );

      expect(result.content, 'Abra Settings e adicione a instância.');
      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.path, '/chat/completions');
      final body = request.data as Map<String, dynamic>;
      expect(body['model'], 'auto');
      final messages = body['messages'] as List;
      expect(messages.first['role'], 'system');
      expect(messages.last, {
        'role': 'user',
        'content': 'Como adiciono uma instância?',
      });
    });

    test('should keep only the most recent history messages', () async {
      final adapter = _AdapterStub();
      final service = buildService(adapter);
      final longHistory = List.generate(
        20,
        (index) => AssistantOnlineChatMessage(
          role: AssistantOnlineMessageRole.user,
          content: 'message $index',
        ),
      );

      await service.sendMessage(longHistory, _TestKnowledgeService());

      final body = adapter.requests.single.data as Map<String, dynamic>;
      final messages = body['messages'] as List;
      expect(messages, hasLength(13));
      expect(messages[1]['content'], 'message 8');
    });

    test('should join text parts when content is a list', () async {
      final adapter = _AdapterStub(
        content: [
          {'type': 'text', 'text': 'Primeira parte.'},
          {'type': 'text', 'text': 'Segunda parte.'},
        ],
      );
      final service = buildService(adapter);

      final result = await service.sendMessage(
        history,
        _TestKnowledgeService(),
      );

      expect(result.content, 'Primeira parte.\nSegunda parte.');
    });

    test('should throw when the adapter returns an empty response', () async {
      final adapter = _AdapterStub(content: '');
      final service = buildService(adapter);

      expect(
        service.sendMessage(history, _TestKnowledgeService()),
        throwsA(isA<StateError>()),
      );
    });

    test('should propagate adapter HTTP errors', () async {
      final adapter = _AdapterStub(statusCode: 500);
      final service = buildService(adapter);

      expect(
        service.sendMessage(history, _TestKnowledgeService()),
        throwsA(isA<DioException>()),
      );
    });
  });
}

class _TestKnowledgeService extends AssistantKnowledgeService {
  @override
  String getSkillDescriptions() => 'Available skills';

  @override
  Future<String> loadRelevantSkills(String question) async => 'Documentation';
}

class _AdapterStub implements HttpClientAdapter {
  _AdapterStub({
    this.content = 'Abra Settings e adicione a instância.',
    this.statusCode = 200,
  });

  final Object content;
  final int statusCode;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final payload = statusCode == 200
        ? {
            'choices': [
              {
                'message': {'content': content},
              },
            ],
          }
        : {'error': 'adapter unavailable'};

    return ResponseBody.fromString(
      jsonEncode(payload),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
