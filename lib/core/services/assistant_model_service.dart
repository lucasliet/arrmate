import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Describes a downloadable LiteRT-LM model available to the user.
class AssistantModelCatalogEntry {
  /// Creates a catalog entry for a downloadable model.
  const AssistantModelCatalogEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.repository,
    required this.fileName,
    required this.downloadUrl,
  });

  /// Stable identifier used for persistence.
  final String id;

  /// Human-readable model name.
  final String title;

  /// Short description shown in the UI.
  final String description;

  /// Hugging Face repository name.
  final String repository;

  /// File name of the `.litertlm` artifact.
  final String fileName;

  /// Direct download URL for the model artifact.
  final String downloadUrl;
}

/// Represents a model stored locally on the device.
class AssistantInstalledModel {
  /// Creates an installed model descriptor.
  const AssistantInstalledModel({
    required this.id,
    required this.label,
    required this.path,
    required this.source,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  /// Stable identifier used for persistence.
  final String id;

  /// Label shown in the UI.
  final String label;

  /// Absolute file path to the model.
  final String path;

  /// Source of the model, such as catalog or import.
  final String source;

  /// File size in bytes.
  final int sizeBytes;

  /// File modification timestamp.
  final DateTime modifiedAt;
}

/// Manages the LiteRT-LM model catalog and local model storage.
class AssistantModelService {
  /// Creates a new model service instance.
  AssistantModelService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 15),
              sendTimeout: const Duration(seconds: 30),
            ),
          );

  static const _selectedModelIdKey = 'assistant_selected_model_id';
  static const _catalogCacheKey = 'assistant_model_catalog_cache';

  final Dio _dio;
  CancelToken? _activeCancelToken;

  /// Curated local-first catalog of open `.litertlm` models.
  static const List<AssistantModelCatalogEntry> catalog = [
    AssistantModelCatalogEntry(
      id: 'qwen3_0_6b',
      title: 'Qwen 3 0.6B',
      description: 'Small, fast general-purpose chat model.',
      repository: 'litert-community/Qwen3-0.6B',
      fileName: 'Qwen3-0.6B.litertlm',
      downloadUrl:
          'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm?download=true',
    ),
    AssistantModelCatalogEntry(
      id: 'gemma4_e2b',
      title: 'Gemma 4 E2B',
      description: 'Balanced quality and size for mobile devices.',
      repository: 'litert-community/gemma-4-E2B-it-litert-lm',
      fileName: 'gemma-4-E2B-it.litertlm',
      downloadUrl:
          'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm?download=true',
    ),
    AssistantModelCatalogEntry(
      id: 'gemma4_e4b',
      title: 'Gemma 4 E4B',
      description: 'Higher quality model with larger memory needs.',
      repository: 'litert-community/gemma-4-E4B-it-litert-lm',
      fileName: 'gemma-4-E4B-it.litertlm',
      downloadUrl:
          'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm?download=true',
    ),
  ];

  /// Returns the persisted selected model id.
  Future<String?> getSelectedModelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedModelIdKey);
  }

  /// Persists the selected model id.
  Future<void> setSelectedModelId(String? modelId) async {
    final prefs = await SharedPreferences.getInstance();
    if (modelId == null) {
      await prefs.remove(_selectedModelIdKey);
      return;
    }
    await prefs.setString(_selectedModelIdKey, modelId);
  }

  /// Returns the curated catalog.
  Future<List<AssistantModelCatalogEntry>> loadCatalog() async {
    return catalog;
  }

  /// Loads the catalog cache from assets if needed.
  Future<String> loadKnowledgeBase() async {
    return rootBundle.loadString('assets/assistant/knowledge.md');
  }

  /// Returns the directory where assistant models are stored.
  Future<Directory> getModelsDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final modelsDir = Directory(path.join(supportDir.path, 'assistant_models'));
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  /// Lists all installed `.litertlm` models.
  Future<List<AssistantInstalledModel>> listInstalledModels() async {
    final modelsDir = await getModelsDirectory();
    final files = modelsDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.litertlm'))
        .toList();

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return files.map(_toInstalledModel).toList();
  }

  /// Downloads a model into the managed model directory.
  Future<AssistantInstalledModel> downloadModel(
    AssistantModelCatalogEntry model, {
    void Function(int received, int total)? onProgress,
  }) async {
    final modelsDir = await getModelsDirectory();
    final targetDir = Directory(path.join(modelsDir.path, model.id));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final targetFile = File(path.join(targetDir.path, model.fileName));
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    _activeCancelToken = CancelToken();
    try {
      await _dio.download(
        model.downloadUrl,
        targetFile.path,
        onReceiveProgress: onProgress,
        cancelToken: _activeCancelToken,
      );
    } finally {
      _activeCancelToken = null;
    }

    return _toInstalledModel(targetFile, source: model.id);
  }

  /// Cancels the active model download, if any.
  void cancelDownload() {
    _activeCancelToken?.cancel('Download cancelled by user');
    _activeCancelToken = null;
  }

  /// Imports an existing `.litertlm` file into managed storage.
  Future<AssistantInstalledModel> importModel(PlatformFile file) async {
    final sourcePath = file.path;
    if (sourcePath == null || sourcePath.isEmpty) {
      throw const FileSystemException('Selected file has no path');
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw const FileSystemException('Selected file does not exist');
    }

    final normalizedName = _normalizeFileName(
      path.basenameWithoutExtension(sourceFile.path),
    );
    final modelsDir = await getModelsDirectory();
    final targetDir = Directory(path.join(modelsDir.path, 'imported'));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final targetFile = File(
      path.join(targetDir.path, '$normalizedName.litertlm'),
    );
    await sourceFile.copy(targetFile.path);

    return _toInstalledModel(targetFile, source: 'imported');
  }

  /// Deletes an installed model file.
  Future<void> deleteModel(AssistantInstalledModel model) async {
    final file = File(model.path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Opens a file picker to import a `.litertlm` model.
  Future<AssistantInstalledModel?> pickAndImportModel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['litertlm'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return importModel(result.files.first);
  }

  /// Creates an installed model descriptor from a local file.
  AssistantInstalledModel _toInstalledModel(File file, {String? source}) {
    final stat = file.statSync();
    final title = path.basenameWithoutExtension(file.path).replaceAll('_', ' ');
    return AssistantInstalledModel(
      id: _modelIdForPath(file.path),
      label: title,
      path: file.path,
      source: source ?? 'local',
      sizeBytes: stat.size,
      modifiedAt: stat.modified,
    );
  }

  /// Creates a stable identifier for a local model file.
  String _modelIdForPath(String filePath) {
    final bytes = utf8.encode(filePath);
    return base64Url.encode(bytes).replaceAll('=', '').toLowerCase();
  }

  /// Normalizes a file name into a stable file-system friendly value.
  String _normalizeFileName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }
}
