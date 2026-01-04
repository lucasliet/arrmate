import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/models.dart';

class SonarrApi {
  final ApiClient _client;
  final Instance instance;

  SonarrApi(this.instance, [ApiClient? client])
      : _client = client ?? ApiClient(
          baseUrl: '${instance.url}${ApiConstants.apiPath}',
          headers: instance.authHeaders,
        );

  Future<List<Series>> getSeries() async {
    final response = await _client.get('/series');
    return (response as List)
        .map((e) => Series.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Series> getSeriesById(int id) async {
    final response = await _client.get('/series/$id');
    return Series.fromJson(response as Map<String, dynamic>);
  }

  Future<Series> addSeries(Series series) async {
    final response = await _client.post('/series', data: series.toJson());
    return Series.fromJson(response as Map<String, dynamic>);
  }

  Future<Series> updateSeries(Series series) async {
    final response = await _client.put('/series/${series.id}', data: series.toJson());
    return Series.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteSeries(int id, {bool deleteFiles = false, bool addExclusion = false}) async {
    await _client.delete(
      '/series/$id',
      queryParameters: {
        'deleteFiles': deleteFiles,
        'addExclusion': addExclusion,
      },
    );
  }

  Future<List<QualityProfile>> getQualityProfiles() async {
    final response = await _client.get('/qualityprofile');
    return (response as List)
        .map((e) => QualityProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RootFolder>> getRootFolders() async {
    final response = await _client.get('/rootfolder');
    return (response as List)
        .map((e) => RootFolder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Series>> lookupSeries(String term) async {
    final response = await _client.get(
      '/series/lookup',
      queryParameters: {'term': term},
    );
    return (response as List)
        .map((e) => Series.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Episode>> getEpisodes(int seriesId) async {
    final response = await _client.get(
      '/episode',
      queryParameters: {'seriesId': seriesId},
    );
    return (response as List)
        .map((e) => Episode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Episode> getEpisode(int id) async {
    final response = await _client.get('/episode/$id');
    return Episode.fromJson(response as Map<String, dynamic>);
  }

  Future<List<Episode>> getCalendar({DateTime? start, DateTime? end}) async {
    final response = await _client.get(
      '/calendar',
      queryParameters: {
        if (start != null) 'start': start.toIso8601String(),
        if (end != null) 'end': end.toIso8601String(),
        'includeSeries': true,
        'includeEpisodeFile': true,
      },
    );
    
    // O calendário do Sonarr retorna Episódios, mas precisamos garantir que venha os dados da Série junto se disponível
    return (response as List)
        .map((e) => Episode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QueueItems> getQueue({
    int page = 1,
    int pageSize = 20,
    String sortKey = 'timeleft',
    String sortDirection = 'ascending',
  }) async {
    final response = await _client.get(
      '/queue',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'sortKey': sortKey,
        'sortDirection': sortDirection,
        'includeUnknownSeriesItems': true,
      },
    );
    return QueueItems.fromJson(response as Map<String, dynamic>);
  }
}
