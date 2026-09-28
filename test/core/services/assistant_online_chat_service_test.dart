import 'dart:convert';

import 'package:arrmate/core/services/assistant_knowledge_service.dart';
import 'package:arrmate/core/services/assistant_online_chat_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssistantOnlineChatService', () {
    test('should send a stable session header only on web', () async {
      SharedPreferences.setMockInitialValues({});
      final adapter = _OpenCodeAdapter();
      final service = AssistantOnlineChatService(
        dio: Dio(BaseOptions(baseUrl: 'https://opencode.test/zen/v1'))
          ..httpClientAdapter = adapter,
      );

      final history = const [
        AssistantOnlineChatMessage(
          role: AssistantOnlineMessageRole.user,
          content: 'Como adiciono uma instância?',
        ),
      ];
      final knowledgeService = _TestKnowledgeService();

      await service.initialize();
      final result = await service.sendMessage(history, knowledgeService);
      await service.sendMessage(history, knowledgeService);
      final otherService = AssistantOnlineChatService(
        dio: Dio(BaseOptions(baseUrl: 'https://opencode.test/zen/v1'))
          ..httpClientAdapter = adapter,
      );
      await otherService.sendMessage(history, knowledgeService);

      expect(result.modelId, 'fallback-free');
      expect(adapter.modelRequests, hasLength(2));
      expect(adapter.chatRequests, hasLength(4));
      expect(
        adapter.modelRequests.every(
          (request) => !request.headers.containsKey('x-opencode-session'),
        ),
        isTrue,
      );
      if (kIsWeb) {
        expect(
          adapter.chatRequests.first.headers['x-opencode-session'],
          isNotEmpty,
        );
        expect(
          adapter.chatRequests.first.headers['x-opencode-session'],
          adapter.chatRequests[1].headers['x-opencode-session'],
        );
        expect(
          adapter.chatRequests[2].headers['x-opencode-session'],
          adapter.chatRequests.first.headers['x-opencode-session'],
        );
        expect(
          adapter.chatRequests[3].headers['x-opencode-session'],
          isNot(adapter.chatRequests.first.headers['x-opencode-session']),
        );
      } else {
        expect(
          adapter.chatRequests.every(
            (request) => !request.headers.containsKey('x-opencode-session'),
          ),
          isTrue,
        );
      }
    });

    test('should filter incompatible free models only on web', () async {
      final adapter = _OpenCodeAdapter(
        modelIds: const [
          'jev-1.13-free',
          'muse-spark-1.3-contributor-free',
          'muse-spark-1.2-contributor-free',
          AssistantOnlineChatService.defaultModelId,
          'another-free',
          'paid-model',
        ],
      );
      final service = AssistantOnlineChatService(
        dio: Dio(BaseOptions(baseUrl: 'https://opencode.test/zen/v1'))
          ..httpClientAdapter = adapter,
      );

      final models = await service.loadFreeModels();

      expect(
        models,
        kIsWeb
            ? [AssistantOnlineChatService.defaultModelId, 'another-free']
            : [
                'jev-1.13-free',
                'muse-spark-1.3-contributor-free',
                'muse-spark-1.2-contributor-free',
                AssistantOnlineChatService.defaultModelId,
                'another-free',
              ],
      );
      expect(adapter.chatRequests, isEmpty);
    });
  });
}

class _TestKnowledgeService extends AssistantKnowledgeService {
  @override
  String getSkillDescriptions() => 'Available skills';

  @override
  Future<String> loadRelevantSkills(String question) async => 'Documentation';
}

class _OpenCodeAdapter implements HttpClientAdapter {
  _OpenCodeAdapter({
    this.modelIds = const [
      AssistantOnlineChatService.defaultModelId,
      'fallback-free',
    ],
  });

  final List<String> modelIds;
  final List<RequestOptions> modelRequests = [];
  final List<RequestOptions> chatRequests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/models') {
      modelRequests.add(options);
      return _jsonResponse({
        'data': modelIds.map((id) => {'id': id}).toList(),
      });
    }

    chatRequests.add(options);
    if (chatRequests.length == 1) {
      return _jsonResponse({'error': 'model unavailable'}, statusCode: 500);
    }

    return _jsonResponse({
      'choices': [
        {
          'message': {'content': 'Abra Settings e adicione a instância.'},
        },
      ],
    });
  }

  ResponseBody _jsonResponse(Object data, {int statusCode = 200}) {
    return ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
