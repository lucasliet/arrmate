// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appInitErrorTitle => 'Erro de inicialização';

  @override
  String get appInitNotificationServicesFailed =>
      'Falha ao iniciar os serviços de notificação. Alguns recursos podem não funcionar corretamente.';

  @override
  String get appTitle => 'Arrmate';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get commonAutomaticSearch => 'Busca automática';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClear => 'Limpar';

  @override
  String get commonClearFilters => 'Limpar filtros';

  @override
  String get commonClient => 'Cliente';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonDeleteFiles => 'Excluir arquivos';

  @override
  String get commonDismiss => 'Dispensar';

  @override
  String get commonEdit => 'Editar';

  @override
  String commonErrorWithDetails(String error) {
    return 'Erro: $error';
  }

  @override
  String get commonFilter => 'Filtrar';

  @override
  String get commonImport => 'Importar';

  @override
  String get commonIndexer => 'Indexador';

  @override
  String get commonInteractiveSearch => 'Busca interativa';

  @override
  String get commonLanguage => 'Idioma';

  @override
  String get commonLoading => 'Carregando...';

  @override
  String get commonMonitor => 'Monitorar';

  @override
  String get commonMonitored => 'Monitorado';

  @override
  String get commonMovies => 'Filmes';

  @override
  String get commonNo => 'Não';

  @override
  String get commonOk => 'OK';

  @override
  String get commonOpenExternally => 'Abrir externamente';

  @override
  String get commonOpenInLibrary => 'Abrir na biblioteca';

  @override
  String get commonProtocol => 'Protocolo';

  @override
  String get commonPurge => 'Expurgar';

  @override
  String get commonQuality => 'Qualidade';

  @override
  String get commonQualityProfile => 'Perfil de qualidade';

  @override
  String get commonRefresh => 'Atualizar';

  @override
  String get commonReset => 'Redefinir';

  @override
  String get commonRestore => 'Restaurar';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonRootFolder => 'Pasta raiz';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonSearchStarted => 'Busca iniciada';

  @override
  String get commonSelectAll => 'Selecionar tudo';

  @override
  String get commonSeries => 'Séries';

  @override
  String get commonSize => 'Tamanho';

  @override
  String get commonSort => 'Ordenar';

  @override
  String get commonSortBy => 'Ordenar por';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonTags => 'Tags';

  @override
  String get commonUnknown => 'Desconhecido';

  @override
  String get commonUnmonitor => 'Deixar de monitorar';

  @override
  String get commonUnmonitored => 'Não monitorado';

  @override
  String get commonWatchInJellyfin => 'Assistir no Jellyfin';

  @override
  String get commonYes => 'Sim';

  @override
  String get errorConnectionFailed => 'Falha na conexão. Verifique sua rede.';

  @override
  String errorInvalidUrl(String url) {
    return 'URL inválida: $url';
  }

  @override
  String get errorNotFound => 'Recurso não encontrado.';

  @override
  String get errorRequestCancelled => 'Solicitação cancelada';

  @override
  String get errorRequestTimedOut => 'A solicitação expirou. Tente novamente.';

  @override
  String get errorServer => 'Erro no servidor. Tente novamente mais tarde.';

  @override
  String get errorUnauthorized => 'Não autorizado. Verifique sua API Key.';

  @override
  String get errorUnknown => 'Ocorreu um erro desconhecido.';

  @override
  String get errorValidationFailed => 'Falha na validação.';

  @override
  String formatDaysAgo(int count) {
    return 'há $count d';
  }

  @override
  String formatHoursAgo(int count) {
    return 'há $count h';
  }

  @override
  String get formatJustNow => 'Agora mesmo';

  @override
  String formatLastOnline(String time) {
    return 'Online pela última vez $time';
  }

  @override
  String formatMinutesAgo(int count) {
    return 'há $count min';
  }

  @override
  String formatMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count meses',
      one: 'há 1 mês',
    );
    return '$_temp0';
  }

  @override
  String formatSeason(int number) {
    return 'Temporada $number';
  }

  @override
  String formatSeasonEpisode(int season, int episode) {
    return 'Temporada $season, Episódio $episode';
  }

  @override
  String formatTitleWithSeason(String title, int season) {
    return '$title (Temporada $season)';
  }

  @override
  String formatWeeksAgo(int count) {
    return 'há $count sem';
  }

  @override
  String formatYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count anos',
      one: 'há 1 ano',
    );
    return '$_temp0';
  }

  @override
  String get formatYesterday => 'Ontem';

  @override
  String get labelAll => 'Todos';

  @override
  String get labelAppearanceDark => 'Escuro';

  @override
  String get labelAppearanceLight => 'Claro';

  @override
  String get labelAppearanceSystem => 'Sistema';

  @override
  String get labelCalendarAllMedia => 'Todas as mídias';

  @override
  String get labelCalendarUnknownMovie => 'Filme desconhecido';

  @override
  String get labelCalendarUnknownSeries => 'Série desconhecida';

  @override
  String get labelColorAmber => 'Âmbar';

  @override
  String get labelColorBlue => 'Azul';

  @override
  String get labelColorGreen => 'Verde';

  @override
  String get labelColorIndigo => 'Índigo';

  @override
  String get labelColorOrange => 'Laranja';

  @override
  String get labelColorPink => 'Rosa';

  @override
  String get labelColorPurple => 'Roxo';

  @override
  String get labelColorRed => 'Vermelho';

  @override
  String get labelColorTeal => 'Verde-azulado';

  @override
  String get labelDangling => 'Abandonado';

  @override
  String get labelDeleted => 'Excluído';

  @override
  String get labelDigitalRelease => 'Lançamento digital';

  @override
  String get labelDiscoverySortLatest => 'Mais recentes';

  @override
  String get labelDiscoverySortRelevant => 'Relevantes';

  @override
  String get labelDownloaded => 'Baixado';

  @override
  String get labelDownloading => 'Baixando';

  @override
  String get labelEpisode => 'Episódio';

  @override
  String get labelError => 'Erro';

  @override
  String get labelFailed => 'Falhou';

  @override
  String get labelFilePriorityDoNotDownload => 'Não baixar';

  @override
  String get labelFilePriorityHigh => 'Prioridade alta';

  @override
  String get labelFilePriorityLow => 'Prioridade baixa';

  @override
  String get labelFilePriorityMaximal => 'Prioridade máxima';

  @override
  String get labelFilePriorityNormal => 'Prioridade normal';

  @override
  String get labelFilterAllMovies => 'Todos os filmes';

  @override
  String get labelFilterAllSeries => 'Todas as séries';

  @override
  String get labelGrabbed => 'Capturado';

  @override
  String get labelHistoryDeletedGeneric => 'O arquivo foi excluído.';

  @override
  String get labelHistoryDeletedManual =>
      'O arquivo foi excluído manualmente ou por um cliente através da API.';

  @override
  String get labelHistoryDeletedMissingFromDisk =>
      'O arquivo não foi encontrado no disco, então foi desvinculado do banco de dados.';

  @override
  String get labelHistoryDeletedUpgrade =>
      'O arquivo foi excluído para importar uma versão melhor.';

  @override
  String get labelHistoryDownloadFailedDescription => 'O download falhou.';

  @override
  String get labelHistoryDownloadIgnoredDescription => 'Download ignorado.';

  @override
  String labelHistoryEpisodeGrabbed(String indexer, String client) {
    return 'Episódio capturado de $indexer e enviado para $client.';
  }

  @override
  String labelHistoryEpisodeImported(String client) {
    return 'Episódio baixado com sucesso e importado de $client.';
  }

  @override
  String get labelHistoryEpisodeRenamed =>
      'O arquivo do episódio foi renomeado.';

  @override
  String get labelHistoryFallbackClient => 'cliente de download';

  @override
  String get labelHistoryFallbackIndexer => 'indexador';

  @override
  String get labelHistoryIgnored => 'Ignorado';

  @override
  String get labelHistoryImported => 'Importado';

  @override
  String labelHistoryMovieGrabbed(String indexer, String client) {
    return 'Filme capturado de $indexer e enviado para $client.';
  }

  @override
  String labelHistoryMovieImported(String client) {
    return 'Filme baixado com sucesso e importado de $client.';
  }

  @override
  String get labelHistoryMovieRenamed => 'O arquivo do filme foi renomeado.';

  @override
  String get labelHistoryRenamed => 'Renomeado';

  @override
  String get labelHistoryTitleDeleted => 'Arquivo excluído';

  @override
  String get labelHistoryTitleFailed => 'Download falhou';

  @override
  String get labelHistoryTitleGrabbed => 'Release capturado';

  @override
  String get labelHistoryTitleIgnored => 'Download ignorado';

  @override
  String get labelHistoryTitleImported => 'Pasta importada';

  @override
  String get labelHistoryTitleRenamed => 'Arquivo renomeado';

  @override
  String get labelHistoryTitleUnknown => 'Evento desconhecido';

  @override
  String get labelHistoryUnknownEventDescription => 'Evento desconhecido.';

  @override
  String get labelInCinemas => 'Nos cinemas';

  @override
  String get labelMissing => 'Ausente';

  @override
  String get labelMovieMonitorMovieAndCollection => 'Filme + Coleção';

  @override
  String get labelMovieMonitorMovieOnly => 'Filme';

  @override
  String get labelMovieStateUnreleased => 'Não lançado';

  @override
  String get labelMovieStateUnwanted => 'Indesejado';

  @override
  String get labelMovieStateWaiting => 'Aguardando';

  @override
  String get labelMovieStatusAnnounced => 'Anunciado';

  @override
  String get labelMovieStatusReleased => 'Lançado';

  @override
  String get labelMovieStatusTba => 'Não anunciado';

  @override
  String get labelNone => 'Nenhum';

  @override
  String get labelPaused => 'Pausado';

  @override
  String get labelPhysicalRelease => 'Lançamento físico';

  @override
  String get labelQueueCompleted => 'Concluído';

  @override
  String get labelQueuePending => 'Pendente';

  @override
  String get labelQueueWarning => 'Aviso';

  @override
  String get labelQueued => 'Na fila';

  @override
  String get labelSeeding => 'Semeando';

  @override
  String get labelSeriesMonitorAll => 'Todos os episódios';

  @override
  String get labelSeriesMonitorExisting => 'Episódios existentes';

  @override
  String get labelSeriesMonitorFirstSeason => 'Primeira temporada';

  @override
  String get labelSeriesMonitorFuture => 'Episódios futuros';

  @override
  String get labelSeriesMonitorLastSeason => 'Última temporada';

  @override
  String get labelSeriesMonitorMissing => 'Episódios ausentes';

  @override
  String get labelSeriesMonitorPilot => 'Episódio piloto';

  @override
  String get labelSeriesMonitorRecent => 'Episódios recentes';

  @override
  String get labelSeriesMonitorSpecials => 'Monitorar especiais';

  @override
  String get labelSeriesStatusContinuing => 'Em andamento';

  @override
  String get labelSeriesStatusEnded => 'Finalizada';

  @override
  String get labelSeriesStatusUpcoming => 'Em breve';

  @override
  String get labelSeriesTypeAnime => 'Anime';

  @override
  String get labelSeriesTypeDaily => 'Diária';

  @override
  String get labelSeriesTypeStandard => 'Padrão';

  @override
  String get labelSeriesUnmonitorSpecials => 'Não monitorar especiais';

  @override
  String get labelSortAdded => 'Adicionado';

  @override
  String get labelSortNextAiring => 'Próxima exibição';

  @override
  String get labelSortPreviousAiring => 'Exibição anterior';

  @override
  String get labelSortRating => 'Avaliação';

  @override
  String get labelSortRuntime => 'Duração';

  @override
  String get labelSortTitle => 'Título';

  @override
  String get labelSortYear => 'Ano';

  @override
  String get labelSpecials => 'Especiais';

  @override
  String get labelTabActivity => 'Atividade';

  @override
  String get labelTabCalendar => 'Calendário';

  @override
  String get labelTabSettings => 'Configurações';

  @override
  String get labelTba => 'A definir';

  @override
  String get labelTorrentChecking => 'Verificando';

  @override
  String get labelTorrentLinkExternal => 'Fora da biblioteca';

  @override
  String get labelTorrentLinkExternalDescription =>
      'Este torrent foi baixado fora da biblioteca de mídia.';

  @override
  String get labelTorrentLinkFileMissing => 'Arquivo removido';

  @override
  String get labelTorrentLinkFileMissingDescription =>
      'O item do catálogo ainda existe, mas o arquivo de mídia foi excluído.';

  @override
  String get labelTorrentLinkLinked => 'Na biblioteca';

  @override
  String get labelTorrentLinkLinkedDescription =>
      'Este torrent sustenta um item que ainda está na biblioteca de mídia.';

  @override
  String get labelTorrentLinkOrphan => 'Órfão';

  @override
  String get labelTorrentLinkOrphanDescription =>
      'O Radarr/Sonarr baixou este torrent, mas o item do catálogo não existe mais. Só restou o torrent.';

  @override
  String get labelTorrentLinkUnknownDescription =>
      'Não foi possível determinar a relação com a biblioteca.';

  @override
  String get labelTorrentMissingFiles => 'Arquivos ausentes';

  @override
  String get labelTorrentPausedDl => 'Pausado (DL)';

  @override
  String get labelTorrentPausedUp => 'Pausado (UP)';

  @override
  String get labelTorrentQueuedDl => 'Na fila (DL)';

  @override
  String get labelTorrentQueuedUp => 'Na fila (UP)';

  @override
  String get labelTorrentSortActivity => 'Atividade';

  @override
  String get labelTorrentSortAddedDate => 'Data de adição';

  @override
  String get labelTorrentSortDownloadSpeed => 'Velocidade de download';

  @override
  String get labelTorrentSortName => 'Nome';

  @override
  String get labelTorrentSortProgress => 'Progresso';

  @override
  String get labelTorrentSortRatio => 'Proporção';

  @override
  String get labelTorrentSortSeedTime => 'Tempo semeando';

  @override
  String get labelTorrentStalledDl => 'Parado (DL)';

  @override
  String get labelTorrentStalledUp => 'Parado (UP)';

  @override
  String get labelTrackerDisabled => 'Desativado';

  @override
  String get labelTrackerNotContacted => 'Não contatado';

  @override
  String get labelTrackerNotWorking => 'Não funciona';

  @override
  String get labelTrackerUpdating => 'Atualizando';

  @override
  String get labelTrackerWorking => 'Funcionando';

  @override
  String get labelUnnamedFile => 'um arquivo sem nome';

  @override
  String get labelViewModeGrid => 'Grade';

  @override
  String get labelViewModeList => 'Lista';

  @override
  String get labelWanted => 'Desejado';

  @override
  String get languagePromptSubtitle =>
      'Você pode alterar depois em Configurações.';

  @override
  String get languagePromptTitle => 'Escolha seu idioma';

  @override
  String get languageSystemDefault => 'Padrão do sistema';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsSelectLanguage => 'Selecionar idioma';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appInitErrorTitle => 'Erro de inicialização';

  @override
  String get appInitNotificationServicesFailed =>
      'Falha ao iniciar os serviços de notificação. Alguns recursos podem não funcionar corretamente.';

  @override
  String get appTitle => 'Arrmate';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get commonAutomaticSearch => 'Busca automática';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClear => 'Limpar';

  @override
  String get commonClearFilters => 'Limpar filtros';

  @override
  String get commonClient => 'Cliente';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonDeleteFiles => 'Excluir arquivos';

  @override
  String get commonDismiss => 'Dispensar';

  @override
  String get commonEdit => 'Editar';

  @override
  String commonErrorWithDetails(String error) {
    return 'Erro: $error';
  }

  @override
  String get commonFilter => 'Filtrar';

  @override
  String get commonImport => 'Importar';

  @override
  String get commonIndexer => 'Indexador';

  @override
  String get commonInteractiveSearch => 'Busca interativa';

  @override
  String get commonLanguage => 'Idioma';

  @override
  String get commonLoading => 'Carregando...';

  @override
  String get commonMonitor => 'Monitorar';

  @override
  String get commonMonitored => 'Monitorado';

  @override
  String get commonMovies => 'Filmes';

  @override
  String get commonNo => 'Não';

  @override
  String get commonOk => 'OK';

  @override
  String get commonOpenExternally => 'Abrir externamente';

  @override
  String get commonOpenInLibrary => 'Abrir na biblioteca';

  @override
  String get commonProtocol => 'Protocolo';

  @override
  String get commonPurge => 'Expurgar';

  @override
  String get commonQuality => 'Qualidade';

  @override
  String get commonQualityProfile => 'Perfil de qualidade';

  @override
  String get commonRefresh => 'Atualizar';

  @override
  String get commonReset => 'Redefinir';

  @override
  String get commonRestore => 'Restaurar';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonRootFolder => 'Pasta raiz';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonSearchStarted => 'Busca iniciada';

  @override
  String get commonSelectAll => 'Selecionar tudo';

  @override
  String get commonSeries => 'Séries';

  @override
  String get commonSize => 'Tamanho';

  @override
  String get commonSort => 'Ordenar';

  @override
  String get commonSortBy => 'Ordenar por';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonTags => 'Tags';

  @override
  String get commonUnknown => 'Desconhecido';

  @override
  String get commonUnmonitor => 'Deixar de monitorar';

  @override
  String get commonUnmonitored => 'Não monitorado';

  @override
  String get commonWatchInJellyfin => 'Assistir no Jellyfin';

  @override
  String get commonYes => 'Sim';

  @override
  String get errorConnectionFailed => 'Falha na conexão. Verifique sua rede.';

  @override
  String errorInvalidUrl(String url) {
    return 'URL inválida: $url';
  }

  @override
  String get errorNotFound => 'Recurso não encontrado.';

  @override
  String get errorRequestCancelled => 'Solicitação cancelada';

  @override
  String get errorRequestTimedOut => 'A solicitação expirou. Tente novamente.';

  @override
  String get errorServer => 'Erro no servidor. Tente novamente mais tarde.';

  @override
  String get errorUnauthorized => 'Não autorizado. Verifique sua API Key.';

  @override
  String get errorUnknown => 'Ocorreu um erro desconhecido.';

  @override
  String get errorValidationFailed => 'Falha na validação.';

  @override
  String formatDaysAgo(int count) {
    return 'há $count d';
  }

  @override
  String formatHoursAgo(int count) {
    return 'há $count h';
  }

  @override
  String get formatJustNow => 'Agora mesmo';

  @override
  String formatLastOnline(String time) {
    return 'Online pela última vez $time';
  }

  @override
  String formatMinutesAgo(int count) {
    return 'há $count min';
  }

  @override
  String formatMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count meses',
      one: 'há 1 mês',
    );
    return '$_temp0';
  }

  @override
  String formatSeason(int number) {
    return 'Temporada $number';
  }

  @override
  String formatSeasonEpisode(int season, int episode) {
    return 'Temporada $season, Episódio $episode';
  }

  @override
  String formatTitleWithSeason(String title, int season) {
    return '$title (Temporada $season)';
  }

  @override
  String formatWeeksAgo(int count) {
    return 'há $count sem';
  }

  @override
  String formatYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count anos',
      one: 'há 1 ano',
    );
    return '$_temp0';
  }

  @override
  String get formatYesterday => 'Ontem';

  @override
  String get labelAll => 'Todos';

  @override
  String get labelAppearanceDark => 'Escuro';

  @override
  String get labelAppearanceLight => 'Claro';

  @override
  String get labelAppearanceSystem => 'Sistema';

  @override
  String get labelCalendarAllMedia => 'Todas as mídias';

  @override
  String get labelCalendarUnknownMovie => 'Filme desconhecido';

  @override
  String get labelCalendarUnknownSeries => 'Série desconhecida';

  @override
  String get labelColorAmber => 'Âmbar';

  @override
  String get labelColorBlue => 'Azul';

  @override
  String get labelColorGreen => 'Verde';

  @override
  String get labelColorIndigo => 'Índigo';

  @override
  String get labelColorOrange => 'Laranja';

  @override
  String get labelColorPink => 'Rosa';

  @override
  String get labelColorPurple => 'Roxo';

  @override
  String get labelColorRed => 'Vermelho';

  @override
  String get labelColorTeal => 'Verde-azulado';

  @override
  String get labelDangling => 'Abandonado';

  @override
  String get labelDeleted => 'Excluído';

  @override
  String get labelDigitalRelease => 'Lançamento digital';

  @override
  String get labelDiscoverySortLatest => 'Mais recentes';

  @override
  String get labelDiscoverySortRelevant => 'Relevantes';

  @override
  String get labelDownloaded => 'Baixado';

  @override
  String get labelDownloading => 'Baixando';

  @override
  String get labelEpisode => 'Episódio';

  @override
  String get labelError => 'Erro';

  @override
  String get labelFailed => 'Falhou';

  @override
  String get labelFilePriorityDoNotDownload => 'Não baixar';

  @override
  String get labelFilePriorityHigh => 'Prioridade alta';

  @override
  String get labelFilePriorityLow => 'Prioridade baixa';

  @override
  String get labelFilePriorityMaximal => 'Prioridade máxima';

  @override
  String get labelFilePriorityNormal => 'Prioridade normal';

  @override
  String get labelFilterAllMovies => 'Todos os filmes';

  @override
  String get labelFilterAllSeries => 'Todas as séries';

  @override
  String get labelGrabbed => 'Capturado';

  @override
  String get labelHistoryDeletedGeneric => 'O arquivo foi excluído.';

  @override
  String get labelHistoryDeletedManual =>
      'O arquivo foi excluído manualmente ou por um cliente através da API.';

  @override
  String get labelHistoryDeletedMissingFromDisk =>
      'O arquivo não foi encontrado no disco, então foi desvinculado do banco de dados.';

  @override
  String get labelHistoryDeletedUpgrade =>
      'O arquivo foi excluído para importar uma versão melhor.';

  @override
  String get labelHistoryDownloadFailedDescription => 'O download falhou.';

  @override
  String get labelHistoryDownloadIgnoredDescription => 'Download ignorado.';

  @override
  String labelHistoryEpisodeGrabbed(String indexer, String client) {
    return 'Episódio capturado de $indexer e enviado para $client.';
  }

  @override
  String labelHistoryEpisodeImported(String client) {
    return 'Episódio baixado com sucesso e importado de $client.';
  }

  @override
  String get labelHistoryEpisodeRenamed =>
      'O arquivo do episódio foi renomeado.';

  @override
  String get labelHistoryFallbackClient => 'cliente de download';

  @override
  String get labelHistoryFallbackIndexer => 'indexador';

  @override
  String get labelHistoryIgnored => 'Ignorado';

  @override
  String get labelHistoryImported => 'Importado';

  @override
  String labelHistoryMovieGrabbed(String indexer, String client) {
    return 'Filme capturado de $indexer e enviado para $client.';
  }

  @override
  String labelHistoryMovieImported(String client) {
    return 'Filme baixado com sucesso e importado de $client.';
  }

  @override
  String get labelHistoryMovieRenamed => 'O arquivo do filme foi renomeado.';

  @override
  String get labelHistoryRenamed => 'Renomeado';

  @override
  String get labelHistoryTitleDeleted => 'Arquivo excluído';

  @override
  String get labelHistoryTitleFailed => 'Download falhou';

  @override
  String get labelHistoryTitleGrabbed => 'Release capturado';

  @override
  String get labelHistoryTitleIgnored => 'Download ignorado';

  @override
  String get labelHistoryTitleImported => 'Pasta importada';

  @override
  String get labelHistoryTitleRenamed => 'Arquivo renomeado';

  @override
  String get labelHistoryTitleUnknown => 'Evento desconhecido';

  @override
  String get labelHistoryUnknownEventDescription => 'Evento desconhecido.';

  @override
  String get labelInCinemas => 'Nos cinemas';

  @override
  String get labelMissing => 'Ausente';

  @override
  String get labelMovieMonitorMovieAndCollection => 'Filme + Coleção';

  @override
  String get labelMovieMonitorMovieOnly => 'Filme';

  @override
  String get labelMovieStateUnreleased => 'Não lançado';

  @override
  String get labelMovieStateUnwanted => 'Indesejado';

  @override
  String get labelMovieStateWaiting => 'Aguardando';

  @override
  String get labelMovieStatusAnnounced => 'Anunciado';

  @override
  String get labelMovieStatusReleased => 'Lançado';

  @override
  String get labelMovieStatusTba => 'Não anunciado';

  @override
  String get labelNone => 'Nenhum';

  @override
  String get labelPaused => 'Pausado';

  @override
  String get labelPhysicalRelease => 'Lançamento físico';

  @override
  String get labelQueueCompleted => 'Concluído';

  @override
  String get labelQueuePending => 'Pendente';

  @override
  String get labelQueueWarning => 'Aviso';

  @override
  String get labelQueued => 'Na fila';

  @override
  String get labelSeeding => 'Semeando';

  @override
  String get labelSeriesMonitorAll => 'Todos os episódios';

  @override
  String get labelSeriesMonitorExisting => 'Episódios existentes';

  @override
  String get labelSeriesMonitorFirstSeason => 'Primeira temporada';

  @override
  String get labelSeriesMonitorFuture => 'Episódios futuros';

  @override
  String get labelSeriesMonitorLastSeason => 'Última temporada';

  @override
  String get labelSeriesMonitorMissing => 'Episódios ausentes';

  @override
  String get labelSeriesMonitorPilot => 'Episódio piloto';

  @override
  String get labelSeriesMonitorRecent => 'Episódios recentes';

  @override
  String get labelSeriesMonitorSpecials => 'Monitorar especiais';

  @override
  String get labelSeriesStatusContinuing => 'Em andamento';

  @override
  String get labelSeriesStatusEnded => 'Finalizada';

  @override
  String get labelSeriesStatusUpcoming => 'Em breve';

  @override
  String get labelSeriesTypeAnime => 'Anime';

  @override
  String get labelSeriesTypeDaily => 'Diária';

  @override
  String get labelSeriesTypeStandard => 'Padrão';

  @override
  String get labelSeriesUnmonitorSpecials => 'Não monitorar especiais';

  @override
  String get labelSortAdded => 'Adicionado';

  @override
  String get labelSortNextAiring => 'Próxima exibição';

  @override
  String get labelSortPreviousAiring => 'Exibição anterior';

  @override
  String get labelSortRating => 'Avaliação';

  @override
  String get labelSortRuntime => 'Duração';

  @override
  String get labelSortTitle => 'Título';

  @override
  String get labelSortYear => 'Ano';

  @override
  String get labelSpecials => 'Especiais';

  @override
  String get labelTabActivity => 'Atividade';

  @override
  String get labelTabCalendar => 'Calendário';

  @override
  String get labelTabSettings => 'Configurações';

  @override
  String get labelTba => 'A definir';

  @override
  String get labelTorrentChecking => 'Verificando';

  @override
  String get labelTorrentLinkExternal => 'Fora da biblioteca';

  @override
  String get labelTorrentLinkExternalDescription =>
      'Este torrent foi baixado fora da biblioteca de mídia.';

  @override
  String get labelTorrentLinkFileMissing => 'Arquivo removido';

  @override
  String get labelTorrentLinkFileMissingDescription =>
      'O item do catálogo ainda existe, mas o arquivo de mídia foi excluído.';

  @override
  String get labelTorrentLinkLinked => 'Na biblioteca';

  @override
  String get labelTorrentLinkLinkedDescription =>
      'Este torrent sustenta um item que ainda está na biblioteca de mídia.';

  @override
  String get labelTorrentLinkOrphan => 'Órfão';

  @override
  String get labelTorrentLinkOrphanDescription =>
      'O Radarr/Sonarr baixou este torrent, mas o item do catálogo não existe mais. Só restou o torrent.';

  @override
  String get labelTorrentLinkUnknownDescription =>
      'Não foi possível determinar a relação com a biblioteca.';

  @override
  String get labelTorrentMissingFiles => 'Arquivos ausentes';

  @override
  String get labelTorrentPausedDl => 'Pausado (DL)';

  @override
  String get labelTorrentPausedUp => 'Pausado (UP)';

  @override
  String get labelTorrentQueuedDl => 'Na fila (DL)';

  @override
  String get labelTorrentQueuedUp => 'Na fila (UP)';

  @override
  String get labelTorrentSortActivity => 'Atividade';

  @override
  String get labelTorrentSortAddedDate => 'Data de adição';

  @override
  String get labelTorrentSortDownloadSpeed => 'Velocidade de download';

  @override
  String get labelTorrentSortName => 'Nome';

  @override
  String get labelTorrentSortProgress => 'Progresso';

  @override
  String get labelTorrentSortRatio => 'Proporção';

  @override
  String get labelTorrentSortSeedTime => 'Tempo semeando';

  @override
  String get labelTorrentStalledDl => 'Parado (DL)';

  @override
  String get labelTorrentStalledUp => 'Parado (UP)';

  @override
  String get labelTrackerDisabled => 'Desativado';

  @override
  String get labelTrackerNotContacted => 'Não contatado';

  @override
  String get labelTrackerNotWorking => 'Não funciona';

  @override
  String get labelTrackerUpdating => 'Atualizando';

  @override
  String get labelTrackerWorking => 'Funcionando';

  @override
  String get labelUnnamedFile => 'um arquivo sem nome';

  @override
  String get labelViewModeGrid => 'Grade';

  @override
  String get labelViewModeList => 'Lista';

  @override
  String get labelWanted => 'Desejado';

  @override
  String get languagePromptSubtitle =>
      'Você pode alterar depois em Configurações.';

  @override
  String get languagePromptTitle => 'Escolha seu idioma';

  @override
  String get languageSystemDefault => 'Padrão do sistema';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsSelectLanguage => 'Selecionar idioma';
}
