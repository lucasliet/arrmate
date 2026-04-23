import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/assistant_chat_service.dart';
import '../../core/services/assistant_knowledge_service.dart';
import '../../core/services/assistant_model_service.dart';
import '../../core/services/logger_service.dart';

/// Conversation message roles supported by the assistant.
enum AssistantMessageRole { user, assistant }

/// Represents one chat message in the assistant conversation.
class AssistantMessage {
  /// Creates a chat message.
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  /// Message identifier.
  final String id;

  /// Message author role.
  final AssistantMessageRole role;

  /// Message body.
  final String content;

  /// Creation timestamp.
  final DateTime createdAt;
}

/// Holds the current assistant screen state.
class AssistantState {
  /// Creates the assistant state.
  const AssistantState({
    this.catalog = const [],
    this.installedModels = const [],
    this.messages = const [],
    this.selectedModelId,
    this.selectedModelPath,
    this.isLoading = true,
    this.isGenerating = false,
    this.isDownloading = false,
    this.downloadProgress = 0,
    this.isImporting = false,
    this.error,
  });

  /// Available downloadable models.
  final List<AssistantModelCatalogEntry> catalog;

  /// Installed local models.
  final List<AssistantInstalledModel> installedModels;

  /// Conversation messages.
  final List<AssistantMessage> messages;

  /// Selected model id.
  final String? selectedModelId;

  /// Selected model absolute file path.
  final String? selectedModelPath;

  /// Whether the assistant is loading initial data.
  final bool isLoading;

  /// Whether a model response is currently generating.
  final bool isGenerating;

  /// Whether a download is in progress.
  final bool isDownloading;

  /// Download progress as a percentage (0-100).
  final double downloadProgress;

  /// Whether an import is in progress.
  final bool isImporting;

  /// Last error message, if any.
  final String? error;

  /// Returns whether a model is ready to answer.
  bool get hasModel => selectedModelPath != null;

  /// Returns the selected installed model, if any.
  AssistantInstalledModel? get selectedModel {
    final id = selectedModelId;
    if (id == null) {
      return null;
    }
    return installedModels.firstWhereOrNull((model) => model.id == id);
  }

  /// Creates a copy of this state.
  AssistantState copyWith({
    List<AssistantModelCatalogEntry>? catalog,
    List<AssistantInstalledModel>? installedModels,
    List<AssistantMessage>? messages,
    String? selectedModelId,
    String? selectedModelPath,
    bool? isLoading,
    bool? isGenerating,
    bool? isDownloading,
    double? downloadProgress,
    bool? isImporting,
    String? error,
    bool clearSelectedModelId = false,
    bool clearSelectedModelPath = false,
    bool clearError = false,
  }) {
    return AssistantState(
      catalog: catalog ?? this.catalog,
      installedModels: installedModels ?? this.installedModels,
      messages: messages ?? this.messages,
      selectedModelId: clearSelectedModelId
          ? null
          : selectedModelId ?? this.selectedModelId,
      selectedModelPath: clearSelectedModelPath
          ? null
          : selectedModelPath ?? this.selectedModelPath,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isImporting: isImporting ?? this.isImporting,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// Manages assistant chat, model storage, and live documentation lookup.
final assistantProvider = NotifierProvider<AssistantNotifier, AssistantState>(
  AssistantNotifier.new,
);

/// Coordinates model selection, downloads, imports, and chat generation.
class AssistantNotifier extends Notifier<AssistantState> {
  final AssistantModelService _modelService = AssistantModelService();
  final AssistantKnowledgeService _knowledgeService =
      AssistantKnowledgeService();
  final AssistantChatService _chatService = AssistantChatService();

  @override
  AssistantState build() {
    unawaited(_initialize());
    ref.onDispose(() {
      unawaited(_chatService.dispose());
    });
    return const AssistantState();
  }

  Future<void> _initialize() async {
    try {
      final catalog = await _modelService.loadCatalog();
      final installedModels = await _modelService.listInstalledModels();
      final selectedModelId = await _modelService.getSelectedModelId();
      final selectedModel = installedModels.firstWhereOrNull(
        (model) => model.id == selectedModelId,
      );

      if (selectedModel != null) {
        await _chatService.loadModel(selectedModel.path);
      }

      state = state.copyWith(
        catalog: catalog,
        installedModels: installedModels,
        selectedModelId: selectedModel?.id ?? selectedModelId,
        selectedModelPath: selectedModel?.path,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize assistant resources.',
      );
    }
  }

  /// Refreshes installed models from disk.
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final installedModels = await _modelService.listInstalledModels();
      final selectedModel = installedModels.firstWhereOrNull(
        (model) => model.id == state.selectedModelId,
      );

      if (selectedModel == null && state.selectedModelPath != null) {
        await _chatService.dispose();
      }

      state = state.copyWith(
        installedModels: installedModels,
        selectedModelId: selectedModel?.id,
        selectedModelPath: selectedModel?.path,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh installed models.',
      );
    }
  }

  /// Imports a local `.litertlm` file and selects it.
  Future<void> importModel() async {
    if (state.isImporting) {
      return;
    }

    try {
      state = state.copyWith(isImporting: true, clearError: true);
      final importedModel = await _modelService.pickAndImportModel();
      if (importedModel == null) {
        state = state.copyWith(isImporting: false);
        return;
      }

      final installedModels = await _modelService.listInstalledModels();
      await _selectModel(importedModel);
      state = state.copyWith(
        installedModels: installedModels,
        isImporting: false,
      );
    } catch (e) {
      state = state.copyWith(
        isImporting: false,
        error: 'Failed to import model.',
      );
    }
  }

  /// Downloads a curated model and selects it.
  Future<void> downloadModel(AssistantModelCatalogEntry model) async {
    if (state.isDownloading) {
      return;
    }

    try {
      state = state.copyWith(
        isDownloading: true,
        downloadProgress: 0,
        clearError: true,
      );
      final installedModel = await _modelService.downloadModel(
        model,
        onProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total) * 100;
            state = state.copyWith(downloadProgress: progress);
          }
        },
      );
      final installedModels = await _modelService.listInstalledModels();
      await _selectModel(installedModel);
      state = state.copyWith(
        installedModels: installedModels,
        isDownloading: false,
        downloadProgress: 100,
      );
    } catch (e) {
      logger.error('[AssistantNotifier] Download failed', e);
      state = state.copyWith(
        isDownloading: false,
        downloadProgress: 0,
        error: 'Failed to download model: $e',
      );
    }
  }

  /// Cancels the active model download.
  void cancelDownload() {
    _modelService.cancelDownload();
  }

  /// Selects an installed model by id.
  Future<void> selectModel(String modelId) async {
    final model = state.installedModels.firstWhereOrNull(
      (candidate) => candidate.id == modelId,
    );
    if (model == null) {
      state = state.copyWith(error: 'Model not found.');
      return;
    }

    await _selectModel(model);
  }

  /// Sends a user message to the selected model.
  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || state.isGenerating) {
      return;
    }

    if (!state.hasModel) {
      state = state.copyWith(error: 'Select a model before chatting.');
      return;
    }

    final userMessage = AssistantMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: AssistantMessageRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isGenerating: true,
      clearError: true,
    );

    try {
      final reply = await _chatService.sendMessage(trimmed);
      final assistantMessage = AssistantMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: AssistantMessageRole.assistant,
        content: reply,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isGenerating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate a response.',
      );
    }
  }

  /// Deletes an installed model and clears selection if it was active.
  Future<void> deleteModel(String modelId) async {
    final model = state.installedModels.firstWhereOrNull(
      (candidate) => candidate.id == modelId,
    );
    if (model == null) return;

    try {
      await _modelService.deleteModel(model);

      final updatedInstalled = await _modelService.listInstalledModels();
      final wasSelected = modelId == state.selectedModelId;

      if (wasSelected) {
        await _chatService.dispose();
        await _modelService.setSelectedModelId(null);
      }

      state = state.copyWith(
        installedModels: updatedInstalled,
        clearSelectedModelId: wasSelected,
        clearSelectedModelPath: wasSelected,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete model.');
    }
  }

  Future<void> _selectModel(AssistantInstalledModel model) async {
    try {
      final knowledgeBase = await _knowledgeService.loadFullKnowledgeBase();
      await _chatService.loadModel(model.path, knowledgeBase: knowledgeBase);
      await _modelService.setSelectedModelId(model.id);
      state = state.copyWith(
        selectedModelId: model.id,
        selectedModelPath: model.path,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load the selected model.');
    }
  }
}
