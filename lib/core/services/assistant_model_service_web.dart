import 'package:file_picker/file_picker.dart';

/// Describes a downloadable LiteRT-LM model available to the user.
class AssistantModelCatalogEntry {
  /// Creates a catalog entry.
  const AssistantModelCatalogEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.repository,
    required this.fileName,
    required this.downloadUrl,
  });

  /// Stable model identifier.
  final String id;

  /// Human-readable model name.
  final String title;

  /// Short model description.
  final String description;

  /// Source repository name.
  final String repository;

  /// Model artifact file name.
  final String fileName;

  /// Model artifact download URL.
  final String downloadUrl;
}

/// Represents a model stored locally on a supported device.
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

  /// Stable model identifier.
  final String id;

  /// User-facing model name.
  final String label;

  /// Native model path, unused in browsers.
  final String path;

  /// Model import source.
  final String source;

  /// Model size in bytes.
  final int sizeBytes;

  /// Last model modification time.
  final DateTime modifiedAt;
}

/// Web-safe assistant model adapter that explicitly rejects local model work.
class AssistantModelService {
  /// Creates the web adapter.
  AssistantModelService();

  /// The local catalog is hidden because browser model execution is unsupported.
  static const List<AssistantModelCatalogEntry> catalog = [];

  /// Returns whether a model supports native tool calling.
  static bool supportsToolCalling(String modelId) => false;

  /// Returns whether an installed model supports native tool calling.
  bool supportsToolCallingForInstalledModel(AssistantInstalledModel model) =>
      false;

  /// Returns no persisted local selection on web.
  Future<String?> getSelectedModelId() async => null;

  /// Ignores local model selection on web.
  Future<void> setSelectedModelId(String? modelId) async {}

  /// Returns an empty local model catalog on web.
  Future<List<AssistantModelCatalogEntry>> loadCatalog() async => catalog;

  /// Returns no locally installed models on web.
  Future<List<AssistantInstalledModel>> listInstalledModels() async => const [];

  /// Rejects local model downloads on web.
  Future<AssistantInstalledModel> downloadModel(
    AssistantModelCatalogEntry model, {
    void Function(int received, int total)? onProgress,
  }) => Future.error(
    UnsupportedError('Local assistant models are unavailable on web.'),
  );

  /// No-op because web never starts a local model download.
  void cancelDownload() {}

  /// Rejects local model imports on web.
  Future<AssistantInstalledModel> importModel(PlatformFile file) =>
      Future.error(
        UnsupportedError('Local assistant models are unavailable on web.'),
      );

  /// Rejects local model deletion on web.
  Future<void> deleteModel(AssistantInstalledModel model) => Future.error(
    UnsupportedError('Local assistant models are unavailable on web.'),
  );

  /// Returns no model because local file import is unsupported on web.
  Future<AssistantInstalledModel?> pickAndImportModel() async => null;
}
