// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get activityTabHistory => 'Histórico';

  @override
  String get activityTabQueue => 'Fila';

  @override
  String get activityTabTorrents => 'Torrents';

  @override
  String get activityTabWatching => 'Assistindo';

  @override
  String get appInitErrorTitle => 'Erro de inicialização';

  @override
  String get appInitNotificationServicesFailed =>
      'Falha ao iniciar os serviços de notificação. Alguns recursos podem não funcionar corretamente.';

  @override
  String get appTitle => 'Arrmate';

  @override
  String get appleIntelligenceAssetsUnavailable =>
      'O modelo do Apple Intelligence ainda não está pronto. Tente novamente mais tarde.';

  @override
  String get appleIntelligenceBusy =>
      'O Apple Intelligence está ocupado. Tente novamente em instantes.';

  @override
  String get appleIntelligenceContextTooLong =>
      'A pergunta é longa demais para o Apple Intelligence. Tente uma mais curta.';

  @override
  String get appleIntelligenceDeclined =>
      'O Apple Intelligence se recusou a responder. Tente reformular a pergunta.';

  @override
  String get appleIntelligenceDeviceNotEligible =>
      'Este dispositivo não suporta o Apple Intelligence.';

  @override
  String get appleIntelligenceGenerationFailed =>
      'O Apple Intelligence não conseguiu gerar uma resposta.';

  @override
  String get appleIntelligenceModelNotReady =>
      'O modelo do Apple Intelligence ainda está sendo baixado. Tente novamente mais tarde.';

  @override
  String get appleIntelligenceNotEnabled =>
      'Ative o Apple Intelligence nos ajustes do sistema.';

  @override
  String get appleIntelligenceUnavailable =>
      'O Apple Intelligence não está disponível neste dispositivo.';

  @override
  String get appleIntelligenceUnsupportedLanguage =>
      'O Apple Intelligence não suporta este idioma neste dispositivo.';

  @override
  String get appleIntelligenceUnsupportedOs =>
      'O Apple Intelligence requer iOS 26 ou macOS 26.';

  @override
  String get assistantCloud => 'Cloud';

  @override
  String assistantDeleteModelContent(String model) {
    return 'Remover \"$model\" do seu dispositivo?';
  }

  @override
  String get assistantDeleteModelTitle => 'Excluir modelo';

  @override
  String get assistantDownloadModel => 'Baixar modelo';

  @override
  String get assistantDownloadingModel => 'Baixando modelo';

  @override
  String get assistantEmptyPrompt => 'Pergunte sobre o app';

  @override
  String get assistantInputHint => 'Pergunte sobre o Arrmate...';

  @override
  String get assistantInstalled => 'Instalado';

  @override
  String get assistantLinkNotOpened => 'Não foi possível abrir o link';

  @override
  String get assistantLocalModels => 'Modelos locais';

  @override
  String get assistantNoLocalModel => 'Nenhum modelo local selecionado';

  @override
  String get assistantOnDeviceModel => 'Modelo no dispositivo';

  @override
  String get assistantOnlineModel => 'Modelo online';

  @override
  String get assistantOnlyHttpsLinks => 'Somente links HTTPS são compatíveis';

  @override
  String assistantOpenLinkFailed(String error) {
    return 'Não foi possível abrir o link: $error';
  }

  @override
  String get assistantSelectModelFirst => 'Selecione um modelo primeiro';

  @override
  String get assistantStartingDownload => 'Iniciando download...';

  @override
  String get assistantSwitchModel => 'Trocar modelo';

  @override
  String get assistantTitle => 'Assistente';

  @override
  String get assistantUseCloud => 'Use o Cloud';

  @override
  String get assistantUseCloudOrLocal =>
      'Use o Cloud ou importe/baixe um modelo local';

  @override
  String backupAppVersion(String version) {
    return 'Versão do app: $version';
  }

  @override
  String get backupAutomaticNote =>
      'Os backups automáticos são feitos cerca de 30 segundos após você alterar instâncias ou configurações, enquanto estiver conectado. Algumas configurações (como a aba inicial) só são aplicadas por completo após reiniciar o app.';

  @override
  String backupCreated(String time) {
    return 'Criado: $time';
  }

  @override
  String get backupDriveDescription =>
      'Suas configurações, preferências e instâncias configuradas (incluindo as API Keys) ficam guardadas na pasta privada do app no seu Google Drive, invisível para outros apps.';

  @override
  String get backupDriveTitle => 'Backup no Google Drive';

  @override
  String get backupDriveUnavailableMessage =>
      'Esta versão foi compilada sem credenciais do Google. Peça ao desenvolvedor para compilar com a configuração do Google OAuth ou execute localmente com as flags --dart-define. Use o backup em arquivo local abaixo.';

  @override
  String get backupDriveUnavailableTitle =>
      'Backup no Google Drive indisponível';

  @override
  String get backupExportToFile => 'Exportar backup para arquivo';

  @override
  String get backupExportToFileSubtitle =>
      'Salvar uma cópia .json neste dispositivo';

  @override
  String backupExported(String fileName) {
    return 'Backup exportado para $fileName';
  }

  @override
  String backupFoundMessage(String time) {
    return 'Salvo em $time. Restaure-o para trazer as configurações e instâncias para este dispositivo. Os backups automáticos ficam pausados até você restaurar ou fazer um backup manual.';
  }

  @override
  String get backupFoundTitle => 'Backup encontrado no seu Google Drive';

  @override
  String backupInstanceCount(int count) {
    return 'Instâncias: $count';
  }

  @override
  String backupLastBackup(String time) {
    return 'Último backup: $time';
  }

  @override
  String get backupNever => 'nunca';

  @override
  String get backupNow => 'Fazer backup agora';

  @override
  String backupPlatform(String platform) {
    return 'Plataforma: $platform';
  }

  @override
  String get backupRestoreBackupMenu => 'Restaurar backup…';

  @override
  String get backupRestoreConfirmTitle => 'Restaurar backup?';

  @override
  String get backupRestoreFailed => 'Falha na restauração';

  @override
  String get backupRestoreFromFile => 'Restaurar de arquivo…';

  @override
  String get backupRestoreReplaceWarning =>
      'Isso substitui as configurações e instâncias atuais deste dispositivo.';

  @override
  String get backupRestored => 'Backup restaurado';

  @override
  String get backupSignInWithGoogle => 'Entrar com o Google';

  @override
  String get backupSignOut => 'Sair';

  @override
  String get backupTitle => 'Backup e restauração';

  @override
  String get calendarAnyInstance => 'Qualquer instância';

  @override
  String get calendarDataLoadFailed =>
      'Não foi possível carregar os dados do calendário.';

  @override
  String get calendarFilterByInstance => 'Filtrar por instância';

  @override
  String get calendarFilterByMediaType => 'Filtrar por tipo de mídia';

  @override
  String get calendarHideSpecials => 'Ocultar especiais';

  @override
  String get calendarInstanceAny => 'Instância: qualquer';

  @override
  String calendarInstanceNamed(String name) {
    return 'Instância: $name';
  }

  @override
  String get calendarLoadMore => 'Carregar mais';

  @override
  String get calendarLoading => 'Carregando calendário...';

  @override
  String get calendarNoMatchingEvents => 'Nenhum evento correspondente';

  @override
  String get calendarNoMatchingEventsHint =>
      'Ajuste os filtros do calendário para ver mais eventos.';

  @override
  String get calendarNoUpcomingEvents => 'Nenhum evento próximo';

  @override
  String get calendarNoUpcomingEventsHint =>
      'Volte mais tarde ou adicione conteúdo às suas bibliotecas.';

  @override
  String calendarOpenItemFailed(String error) {
    return 'Não foi possível abrir o item: $error';
  }

  @override
  String get calendarPremieres => 'Estreias';

  @override
  String get calendarToday => 'Hoje';

  @override
  String get calendarTomorrow => 'Amanhã';

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
  String coreGoogleSignInAccountLoadFailed(String status) {
    return 'Falha no login do Google: não foi possível carregar a conta (status $status).';
  }

  @override
  String get coreGoogleSignInBrowserFailed =>
      'Não foi possível abrir o navegador de login. Tente novamente.';

  @override
  String get coreGoogleSignInCancelled =>
      'O login no Google foi cancelado antes de terminar.';

  @override
  String get coreGoogleSignInConsentDenied =>
      'O login no Google foi cancelado: o consentimento foi negado.';

  @override
  String get coreGoogleSignInIncompleteToken =>
      'Falha no login do Google: a resposta do token veio incompleta.';

  @override
  String coreGoogleSignInNetworkError(String status) {
    return 'Falha no login do Google: erro de rede ou do servidor (status $status).';
  }

  @override
  String get coreGoogleSignInNoCode =>
      'Falha no login do Google: nenhum código de autorização foi retornado.';

  @override
  String get coreGoogleSignInNoEmail =>
      'Falha no login do Google: a conta não tem e-mail.';

  @override
  String coreGoogleSignInProviderError(String reason) {
    return 'Falha no login do Google: $reason';
  }

  @override
  String get coreGoogleSignInRedirectUnverified =>
      'Falha no login do Google: não foi possível verificar o redirecionamento.';

  @override
  String coreGoogleSignInServerStatus(String status) {
    return 'Falha no login do Google: o servidor retornou o status $status.';
  }

  @override
  String get coreGoogleSignInStatusUnavailable => 'indisponível';

  @override
  String get coreGoogleSignInTimedOut =>
      'O login no Google expirou. Tente novamente.';

  @override
  String get coreGoogleSignInUnavailableOnWeb =>
      'O login do Google não está disponível na web.';

  @override
  String get corePurgeNotificationTitle => 'Torrent removido';

  @override
  String corePurgeNotificationTitleSeason(int season) {
    return 'Torrent removido (temporada $season)';
  }

  @override
  String corePurgeSummaryMediaFiles(int count) {
    return 'Arquivos de mídia: $count';
  }

  @override
  String get corePurgeSummaryQbittorrentSkipped =>
      'qBittorrent ignorado — configure uma instância do qBittorrent.';

  @override
  String corePurgeSummaryQueueItems(int count) {
    return 'Itens da fila: $count';
  }

  @override
  String corePurgeSummaryTorrents(int count) {
    return 'Torrents: $count';
  }

  @override
  String corePurgeSummaryTorrentsWithCrossSeed(int count, int crossSeed) {
    return 'Torrents: $count (+$crossSeed cross-seed)';
  }

  @override
  String get coreUpdateArchiveMissingFiles =>
      'Faltam arquivos obrigatórios do aplicativo no arquivo da atualização.';

  @override
  String get coreUpdateArchiveTooLarge =>
      'O arquivo da atualização excede os limites de extração.';

  @override
  String get coreUpdateArchiveUnsafeLink =>
      'O arquivo da atualização contém um link simbólico inseguro.';

  @override
  String get coreUpdateArchiveUnsafePath =>
      'O arquivo da atualização contém um caminho inseguro.';

  @override
  String get coreUpdateArchiveWritesThroughLink =>
      'O arquivo da atualização grava através de um link simbólico.';

  @override
  String get coreUpdateCheckFailed =>
      'Não foi possível verificar se há atualizações. Tente novamente.';

  @override
  String get coreUpdateInstallerNotStarted =>
      'Não foi possível iniciar o instalador da atualização. O app não foi alterado.';

  @override
  String get coreUpdateLinuxRequiresAppImage =>
      'As atualizações automáticas no Linux exigem o AppImage. Baixe e execute primeiro a versão AppImage.';

  @override
  String get coreUpdateMacBundleRequired =>
      'Execute o pacote Arrmate.app instalado para atualizá-lo.';

  @override
  String get coreUpdateNotAppImage => 'A atualização não é um AppImage x64.';

  @override
  String coreUpdateOtaFailed(String status) {
    return 'Falha na atualização: $status';
  }

  @override
  String coreUpdatePrepareFailed(String tool) {
    return 'Não foi possível preparar o pacote de atualização ($tool).';
  }

  @override
  String get coreUpdateReadOnlyFolder =>
      'A pasta do aplicativo é somente leitura. Mova o Arrmate para uma pasta com permissão de escrita para o seu usuário e tente novamente.';

  @override
  String get coreUpdateUnverifiedPackage =>
      'A versão não contém um pacote verificado para esta plataforma.';

  @override
  String get coreUpdateVerificationFailed =>
      'A atualização falhou na verificação de tamanho ou SHA-256.';

  @override
  String get coreUpdateVersionMismatch =>
      'A versão do aplicativo baixado não corresponde à versão publicada.';

  @override
  String get coreUpdateWindowsIncomplete =>
      'Execute o Arrmate a partir da pasta completa da versão para Windows para atualizá-lo.';

  @override
  String diagnosticsCheckFailed(String error) {
    return 'Falhou · $error';
  }

  @override
  String diagnosticsCheckOk(int ms) {
    return 'OK · ${ms}ms';
  }

  @override
  String diagnosticsCheckOkWithVersion(int ms, String version) {
    return 'OK · ${ms}ms · v$version';
  }

  @override
  String get diagnosticsChecking => 'Verificando endpoints configurados...';

  @override
  String get diagnosticsEndpointActive => 'Endpoint ativo';

  @override
  String get diagnosticsEndpointAlternative => 'Endpoint alternativo';

  @override
  String get diagnosticsEndpointAlternativeActive =>
      'Endpoint alternativo · Ativo';

  @override
  String get diagnosticsEndpointConnectivity => 'Conectividade dos endpoints';

  @override
  String get diagnosticsEndpointPrimary => 'Endpoint principal';

  @override
  String get diagnosticsEndpointPrimaryActive => 'Endpoint principal · Ativo';

  @override
  String get diagnosticsEndpointsAvailable => 'Endpoints disponíveis';

  @override
  String get diagnosticsEndpointsUnavailable => 'Endpoints indisponíveis';

  @override
  String diagnosticsExportFailed(String error) {
    return 'Falha ao exportar o relatório: $error';
  }

  @override
  String get diagnosticsExportReport => 'Exportar relatório';

  @override
  String diagnosticsGenerated(String date) {
    return 'Gerado em $date';
  }

  @override
  String diagnosticsInterfaces(String interfaces) {
    return 'Interfaces: $interfaces';
  }

  @override
  String get diagnosticsNetworkAvailable => 'Rede disponível';

  @override
  String get diagnosticsNoInstances =>
      'Nenhuma instância do Radarr, Sonarr ou qBittorrent está configurada.';

  @override
  String get diagnosticsNoNetworkInterface => 'Nenhuma interface de rede';

  @override
  String get diagnosticsNoRecentRequests =>
      'Nenhuma requisição recente registrada.';

  @override
  String get diagnosticsPurposeBody =>
      'Testa a disponibilidade e a latência de cada endpoint configurado, mostra os rastros de requisições recentes e exporta um relatório sem dados sensíveis. Saúde mostra os alertas reportados pelo Radarr e Sonarr.';

  @override
  String get diagnosticsPurposeTitle => 'Solução de problemas de conexão';

  @override
  String get diagnosticsRecentRequests => 'Rastros de requisições recentes';

  @override
  String get diagnosticsRefreshing =>
      'Atualizando verificações dos endpoints...';

  @override
  String get diagnosticsRunAgain =>
      'Executar as verificações de conexão novamente';

  @override
  String diagnosticsRunFailed(String error) {
    return 'Falha ao executar o diagnóstico de conexão: $error';
  }

  @override
  String get diagnosticsSomeEndpointsUnavailable =>
      'Alguns endpoints indisponíveis';

  @override
  String get diagnosticsTitle => 'Diagnóstico de conexão';

  @override
  String get diagnosticsUnknownError => 'erro desconhecido';

  @override
  String get diagnosticsUnknownStatus => 'desconhecido';

  @override
  String get discoveryConfigureAddition => 'Configurar adição';

  @override
  String get discoveryHideAlreadyAdded => 'Ocultar já adicionados';

  @override
  String discoveryLoadFoldersFailed(String error) {
    return 'Erro ao carregar pastas: $error';
  }

  @override
  String discoveryLoadProfilesFailed(String error) {
    return 'Erro ao carregar perfis: $error';
  }

  @override
  String get discoveryNoOverview => 'Nenhuma sinopse disponível.';

  @override
  String get discoveryNoRating => 'Sem avaliação';

  @override
  String get discoveryNoResultsFound => 'Nenhum resultado encontrado';

  @override
  String discoveryRootFolderFreeSpace(String path, String free) {
    return '$path ($free GB livres)';
  }

  @override
  String discoveryRuntimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get discoverySearchPrompt =>
      'Busque por título, ID do provedor ou URL';

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
  String healthCheckCouldNotStart(String service) {
    return 'Não foi possível iniciar a verificação do $service';
  }

  @override
  String healthConnectionFailed(String service) {
    return 'Falha na conexão com o $service';
  }

  @override
  String get healthConnectionIssues => 'Problemas de conexão';

  @override
  String get healthLoadFailed => 'Falha ao carregar o status de saúde';

  @override
  String get healthLoadFailureSubtitle =>
      'Não foi possível carregar a saúde do servidor. Verifique a conexão e tente novamente.';

  @override
  String get healthNoInstancesSubtitle =>
      'Adicione uma instância do Radarr ou Sonarr para ver a saúde do servidor.';

  @override
  String get healthNoIssuesSubtitle =>
      'Os servidores conectados não reportaram alertas de saúde.';

  @override
  String get healthNoIssuesTitle => 'Nenhum problema no servidor';

  @override
  String get healthRunCheck => 'Executar verificação de saúde';

  @override
  String get healthRunFailureSubtitle =>
      'O status mais recente disponível do servidor é exibido abaixo.';

  @override
  String get healthServerWarnings => 'Alertas do servidor';

  @override
  String get healthTitle => 'Saúde do sistema';

  @override
  String healthWiki(String url) {
    return 'Wiki: $url';
  }

  @override
  String get historyAllEvents => 'Todos os eventos';

  @override
  String get historyAllInstances => 'Todas as instâncias';

  @override
  String get historyDetailDate => 'Data';

  @override
  String get historyDetailScore => 'Pontuação';

  @override
  String get historyEmpty => 'Nenhum evento no histórico';

  @override
  String get historyLoadFailed =>
      'Não foi possível carregar os dados do histórico.';

  @override
  String get historyLoadMore => 'Carregar mais';

  @override
  String get instanceAddBasicAuth => 'Adicionar Basic Auth';

  @override
  String get instanceAddHeader => 'Adicionar cabeçalho';

  @override
  String get instanceAdvancedSettings => 'Configurações avançadas';

  @override
  String get instanceAdvancedSettingsSubtitle =>
      'Cabeçalhos personalizados e autenticação';

  @override
  String get instanceAlternativeUrl => 'URL alternativa';

  @override
  String get instanceAlternativeUrlHelper =>
      'URL opcional usada fora da sua rede local';

  @override
  String get instanceAlternativeUrlSameAsPrimary =>
      'Deve ser diferente da URL principal';

  @override
  String get instanceApiKeyOrBasicAuthRequired =>
      'Informe uma API Key ou adicione Basic Auth abaixo';

  @override
  String get instanceApiKeySessionExpiredValidation =>
      'Adicione Basic Auth abaixo para entrar novamente ou informe uma API Key';

  @override
  String get instanceAuthCustomHeader => 'Cabeçalho personalizado';

  @override
  String get instanceAuthUsernamePassword => 'Usuário e senha';

  @override
  String get instanceBasicAuthBase64Note =>
      'As credenciais serão codificadas em Base64.';

  @override
  String get instanceBasicAuthTitle => 'Autenticação básica';

  @override
  String instanceDeleteFailed(String error) {
    return 'Falha ao excluir: $error';
  }

  @override
  String get instanceDeleteJellyfinWarning =>
      'O Arrmate também removerá a conexão do Jellyfin do Radarr/Sonarr, revogará a API Key do Arrmate que criou e sairá do Jellyfin. Esta ação não pode ser desfeita.';

  @override
  String get instanceDeleteTitle => 'Excluir instância?';

  @override
  String get instanceDeleteWarning => 'Esta ação não pode ser desfeita.';

  @override
  String get instanceEditTitle => 'Editar instância';

  @override
  String instanceErrorHttpStatus(String status) {
    return 'O servidor respondeu com HTTP $status.';
  }

  @override
  String get instanceErrorTimeout =>
      'O servidor demorou demais para responder. Tente novamente ou ative o Modo de instância lenta.';

  @override
  String get instanceErrorUnreachable =>
      'Servidor inacessível. Verifique a URL e sua rede.';

  @override
  String get instanceGoBack => 'Voltar';

  @override
  String get instanceHeaderName => 'Nome do cabeçalho';

  @override
  String get instanceHeaderValue => 'Valor do cabeçalho';

  @override
  String get instanceHideApiKey => 'Ocultar API Key';

  @override
  String get instanceJellyfinFallbackUser => 'um usuário do Jellyfin';

  @override
  String get instanceJellyfinHelperDefault =>
      'API Key (painel do Jellyfin → Avançado → Chaves de API). Deixe vazio se usar \"Adicionar Basic Auth\" abaixo para entrar com usuário e senha.';

  @override
  String get instanceJellyfinHelperSessionExpired =>
      'Sessão expirada — adicione Basic Auth abaixo para entrar novamente ou informe uma API Key';

  @override
  String instanceJellyfinHelperSignedIn(String user) {
    return 'Conectado como $user. Deixe vazio para manter a sessão, informe uma API Key para trocar ou adicione Basic Auth abaixo para entrar novamente.';
  }

  @override
  String get instanceJellyfinSessionExpiredBanner =>
      'Sua sessão do Jellyfin expirou. Adicione Basic Auth em Configurações avançadas com seu usuário e senha para entrar novamente.';

  @override
  String get instanceLibraryAutoUpdateSetupTitle =>
      'Configuração da atualização automática da biblioteca';

  @override
  String get instanceNameHint => 'ex.: Servidor de casa';

  @override
  String get instanceNameLabel => 'Nome';

  @override
  String get instanceNotFoundMessage =>
      'A instância solicitada não existe mais ou não pôde ser carregada.';

  @override
  String get instanceNotFoundTitle => 'Instância não encontrada';

  @override
  String get instancePassword => 'Senha';

  @override
  String get instanceQbittorrentApiKeyHelper =>
      'Token Bearer (qBittorrent ≥ v5.2.0). Deixe vazio se usar \"Adicionar Basic Auth\" abaixo para versões mais antigas.';

  @override
  String instanceRemovedCleanupFailed(String failures) {
    return 'Instância removida, mas parte da limpeza falhou:\n$failures';
  }

  @override
  String get instanceRequired => 'Obrigatório';

  @override
  String get instanceSave => 'Salvar instância';

  @override
  String get instanceSetUpLibraryAutoUpdate =>
      'Configurar atualização automática da biblioteca';

  @override
  String instanceSetupFailed(String error) {
    return 'Falha na configuração: $error';
  }

  @override
  String get instanceShowApiKey => 'Mostrar API Key';

  @override
  String get instanceSlowMode => 'Modo de instância lenta';

  @override
  String get instanceSlowModeSubtitle =>
      'Aumenta os tempos limite para conexões lentas';

  @override
  String get instanceTestConnection => 'Testar conexão';

  @override
  String instanceTestSuccessArr(String version, String name, int count) {
    return 'Conexão bem-sucedida!\nVersão: $version\nInstância: $name\nTags: $count disponíveis';
  }

  @override
  String instanceTestSuccessQbittorrent(String auth, int count) {
    return 'Conexão bem-sucedida!\nAutenticação: $auth\nTorrents: $count';
  }

  @override
  String get instanceUrlHelper => 'Inclua http:// ou https:// e a porta';

  @override
  String get instanceUrlInvalid => 'Deve ser uma URL HTTP ou HTTPS válida';

  @override
  String get instanceUsername => 'Usuário';

  @override
  String instanceValidationFailed(String error) {
    return 'Falha na validação: $error';
  }

  @override
  String get jellyfinSetupApiKeyRequired =>
      'API Key do Jellyfin necessária para atualizar a biblioteca automaticamente: informe uma API Key no campo ou entre com uma conta de administrador (Basic Auth)';

  @override
  String get jellyfinSetupNoConnection =>
      'Nenhuma conexão com o Jellyfin configurada no Arrmate.';

  @override
  String jellyfinSetupNotArrInstance(String name) {
    return '$name não é uma instância do Radarr ou do Sonarr.';
  }

  @override
  String jellyfinSetupRemoveConnectorFailed(String name, String error) {
    return 'Não foi possível remover a conexão do Jellyfin de $name: $error';
  }

  @override
  String jellyfinSetupRevokeKeyFailed(String error) {
    return 'Não foi possível revogar a API Key do Arrmate no Jellyfin: $error';
  }

  @override
  String jellyfinSetupSignOutFailed(String error) {
    return 'Não foi possível sair do Jellyfin: $error';
  }

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
  String get logsAllCopied =>
      'Todos os logs copiados para a área de transferência';

  @override
  String get logsAppLogsCleared => 'Logs do app limpos';

  @override
  String get logsClearAppLogs => 'Limpar logs do app';

  @override
  String get logsCopyAllVisible => 'Copiar todos os logs visíveis';

  @override
  String get logsDetailException => 'Exceção/Erro:';

  @override
  String get logsDetailLevel => 'Nível';

  @override
  String get logsDetailLogger => 'Logger';

  @override
  String get logsDetailMessage => 'Mensagem:';

  @override
  String get logsDetailTime => 'Hora';

  @override
  String get logsDetailTitle => 'Detalhes do log';

  @override
  String get logsLevelDebug => 'Debug';

  @override
  String get logsLevelInfo => 'Info';

  @override
  String get logsLevelWarn => 'Aviso';

  @override
  String get logsLogCopied => 'Log copiado';

  @override
  String get logsNoAppLogsMatchingFilter =>
      'Nenhum log do app encontrado para o filtro';

  @override
  String get logsNoLogsMatchingFilter => 'Nenhum log encontrado para o filtro';

  @override
  String get logsSource => 'Origem dos logs';

  @override
  String get logsTabApp => 'Logs do app';

  @override
  String get logsTabArr => 'Logs ARR';

  @override
  String get logsTitle => 'Logs do sistema';

  @override
  String get manualImportEmptySubtitle =>
      'Não há arquivos disponíveis para importação manual.';

  @override
  String get manualImportEmptyTitle => 'Nenhum arquivo importável';

  @override
  String manualImportFailed(String error) {
    return 'Falha ao importar: $error';
  }

  @override
  String manualImportIssueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count com problemas',
    );
    return '$_temp0';
  }

  @override
  String get manualImportLoadFailed =>
      'Falha ao carregar os arquivos importáveis';

  @override
  String get manualImportLoading => 'Carregando arquivos importáveis...';

  @override
  String get manualImportNoFilesSelected => 'Nenhum arquivo selecionado';

  @override
  String manualImportSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos selecionados',
      one: '1 arquivo selecionado',
    );
    return '$_temp0';
  }

  @override
  String manualImportSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos importados com sucesso',
      one: '1 arquivo importado com sucesso',
    );
    return '$_temp0';
  }

  @override
  String get manualImportTitle => 'Importação manual';

  @override
  String manualImportValidCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count válidos',
      one: '1 válido',
    );
    return '$_temp0';
  }

  @override
  String moviesAddFailed(String error) {
    return 'Erro ao adicionar o filme: $error';
  }

  @override
  String get moviesAddMissingSelection =>
      'Selecione um filme, um perfil de qualidade e uma pasta raiz';

  @override
  String get moviesAddMovieButton => 'Adicionar filme';

  @override
  String get moviesAddMovieTitle => 'Adicionar filme';

  @override
  String get moviesAddedSuccessfully => 'Filme adicionado com sucesso';

  @override
  String get moviesAllFolders => 'Todas as pastas';

  @override
  String get moviesAlsoDeleteFiles => 'Excluir também os arquivos do disco';

  @override
  String moviesDeleteFailed(String error) {
    return 'Falha ao excluir: $error';
  }

  @override
  String get moviesDeleteFileConfirm =>
      'Tem certeza de que deseja excluir este arquivo? Esta ação não pode ser desfeita.';

  @override
  String get moviesDeleteFileTitle => 'Excluir arquivo';

  @override
  String moviesDeleteFilesConfirm(String title) {
    return 'Excluir todos os arquivos de \"$title\"? Isso remove o arquivo do filme do disco; o filme continua no Radarr.';
  }

  @override
  String moviesDeleteFilesFailed(String error) {
    return 'Falha ao excluir arquivos: $error';
  }

  @override
  String moviesDeleteMovieConfirm(String title) {
    return 'Tem certeza de que deseja excluir \"$title\"?';
  }

  @override
  String get moviesDeleteMovieTitle => 'Excluir filme';

  @override
  String get moviesDeleted => 'Filme excluído';

  @override
  String moviesDeletedFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos excluídos',
      one: '1 arquivo excluído',
    );
    return '$_temp0';
  }

  @override
  String get moviesDeletedWithFiles => 'Filme e arquivos excluídos';

  @override
  String get moviesEditTitle => 'Editar filme';

  @override
  String get moviesEmptyFilteredSubtitle =>
      'Tente limpar ou ajustar sua busca ou seus filtros.';

  @override
  String get moviesEmptySubtitle =>
      'Adicione filmes à sua biblioteca do Radarr para vê-los aqui.';

  @override
  String get moviesEmptyTitle => 'Nenhum filme encontrado';

  @override
  String get moviesFileDeleted => 'Arquivo excluído';

  @override
  String get moviesFilesSection => 'Arquivos';

  @override
  String get moviesHistorySection => 'Histórico';

  @override
  String get moviesInfoPath => 'Caminho';

  @override
  String get moviesInfoStudio => 'Estúdio';

  @override
  String get moviesLoadFilesFailed => 'Falha ao carregar os arquivos';

  @override
  String get moviesLoadHistoryFailed => 'Falha ao carregar o histórico';

  @override
  String get moviesLoading => 'Carregando filmes...';

  @override
  String get moviesLoadingDetails => 'Carregando detalhes...';

  @override
  String get moviesMinimumAvailability => 'Disponibilidade mínima';

  @override
  String moviesMoveFilesConfirm(String path) {
    return 'Deseja mover os arquivos para \"$path\"?';
  }

  @override
  String get moviesMoveFilesTitle => 'Mover arquivos?';

  @override
  String get moviesNoFilesToDelete => 'Nenhum arquivo para excluir';

  @override
  String get moviesNoHistoryEvents => 'Nenhum evento no histórico';

  @override
  String get moviesNoMediaFiles => 'Nenhum arquivo de mídia';

  @override
  String moviesOpenLinkFailed(String error) {
    return 'Não foi possível abrir o link: $error';
  }

  @override
  String get moviesOverview => 'Sinopse';

  @override
  String get moviesPreventReAdd =>
      'Impedir que este filme seja adicionado novamente';

  @override
  String get moviesPreviewTitle => 'Prévia do filme';

  @override
  String moviesPurgeConfirm(String title) {
    return 'Isso removerá permanentemente \"$title\" do Radarr, excluirá seus arquivos de mídia e excluirá todos os torrents de origem (incluindo duplicatas Cross-seed) do qBittorrent. Libera o espaço em disco usado por dados com hardlink.';
  }

  @override
  String moviesPurgeFailed(String error) {
    return 'Falha ao purgar: $error';
  }

  @override
  String moviesPurgePreviewFailed(String error) {
    return 'Falha ao pré-visualizar: $error';
  }

  @override
  String get moviesPurgeTitle => 'Purgar filme';

  @override
  String get moviesPurged => 'Filme purgado.';

  @override
  String get moviesRefreshAndScan => 'Atualizar e escanear';

  @override
  String get moviesRefreshAndScanTriggered =>
      'Atualização e escaneamento iniciados';

  @override
  String get moviesRootFolderHelper =>
      'Alterar isso moverá os arquivos, se confirmado';

  @override
  String get moviesSearchHint => 'Buscar filmes...';

  @override
  String moviesSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionados',
      one: '1 selecionado',
    );
    return '$_temp0';
  }

  @override
  String get moviesSortAndFilter => 'Ordenar e filtrar';

  @override
  String get moviesSwitchToGrid => 'Alternar para grade';

  @override
  String get moviesSwitchToList => 'Alternar para lista';

  @override
  String get moviesTrailer => 'Trailer';

  @override
  String moviesUpdateFailed(String error) {
    return 'Erro ao atualizar o filme: $error';
  }

  @override
  String get moviesUpdated => 'Filme atualizado';

  @override
  String moviesViewPoster(String title) {
    return 'Ver pôster de $title';
  }

  @override
  String get notificationSettingsArrUpdate => 'Atualização da instância *arr';

  @override
  String get notificationSettingsArrUpdateSubtitle =>
      'Quando o servidor Radarr/Sonarr é atualizado';

  @override
  String get notificationSettingsAutoConfigure =>
      'Configurar instâncias *arr automaticamente';

  @override
  String get notificationSettingsAutoConfiguring =>
      'Configurando notificações automaticamente...';

  @override
  String notificationSettingsConfiguredCount(int success, int total) {
    return '$success/$total instâncias configuradas.';
  }

  @override
  String get notificationSettingsConnected => 'Conectado ao ntfy.sh';

  @override
  String get notificationSettingsCopyTopic => 'Copiar tópico';

  @override
  String get notificationSettingsDisconnected => 'Desconectado';

  @override
  String get notificationSettingsDownloads => 'Downloads';

  @override
  String get notificationSettingsEnable => 'Ativar notificações';

  @override
  String get notificationSettingsFailure => 'Notificar em falhas';

  @override
  String get notificationSettingsFailureSubtitle =>
      'Quando a importação de um download falha';

  @override
  String get notificationSettingsFileDeleted => 'Arquivo excluído';

  @override
  String get notificationSettingsFileDeletedSubtitle =>
      'Quando um arquivo de mídia é excluído';

  @override
  String get notificationSettingsGrab => 'Notificar ao capturar';

  @override
  String get notificationSettingsGrabSubtitle =>
      'Quando um release é enviado ao cliente de download';

  @override
  String get notificationSettingsHealthIssues => 'Problemas de saúde';

  @override
  String get notificationSettingsHealthIssuesSubtitle =>
      'Quando problemas de saúde do sistema são detectados';

  @override
  String get notificationSettingsHealthRestored => 'Saúde restaurada';

  @override
  String get notificationSettingsHealthRestoredSubtitle =>
      'Quando um problema de saúde é resolvido';

  @override
  String get notificationSettingsImport => 'Notificar ao importar';

  @override
  String get notificationSettingsImportSubtitle =>
      'Quando um arquivo é importado com sucesso';

  @override
  String get notificationSettingsInAppBody =>
      'As notificações chegam em tempo real enquanto o app está aberto. Ao fechar o app, as novas notificações serão buscadas na próxima vez que você abri-lo.';

  @override
  String get notificationSettingsInAppTitle => 'Notificações no app';

  @override
  String get notificationSettingsIncludeWarnings => 'Incluir alertas';

  @override
  String get notificationSettingsIncludeWarningsSubtitle =>
      'Notificar também alertas de saúde';

  @override
  String get notificationSettingsManualInteraction => 'Interação manual';

  @override
  String get notificationSettingsManualInteractionSubtitle =>
      'Quando uma intervenção manual é necessária';

  @override
  String get notificationSettingsManualSetup => 'OU CONFIGURAÇÃO MANUAL';

  @override
  String get notificationSettingsManualStep1 => '1. Vá em Settings > Connect';

  @override
  String get notificationSettingsManualStep2 =>
      '2. Adicione uma nova conexão > ntfy';

  @override
  String get notificationSettingsManualStep3 => '3. Configure:';

  @override
  String get notificationSettingsMediaAdded => 'Filme/série adicionado';

  @override
  String get notificationSettingsMediaAddedSubtitle =>
      'Quando um filme ou série é adicionado';

  @override
  String get notificationSettingsMediaDeleted => 'Filme/série excluído';

  @override
  String get notificationSettingsMediaDeletedSubtitle =>
      'Quando um filme ou série é excluído';

  @override
  String get notificationSettingsMediaUpdates => 'Atualizações de mídia';

  @override
  String get notificationSettingsNtfyDocs => 'Documentação do ntfy';

  @override
  String get notificationSettingsServerUrl => 'URL do servidor';

  @override
  String get notificationSettingsSetupInArr => 'Configuração no Radarr/Sonarr';

  @override
  String get notificationSettingsSetupResults => 'Resultados da configuração';

  @override
  String get notificationSettingsSetupSubtitle =>
      'Toque para gerar seu tópico exclusivo';

  @override
  String get notificationSettingsSetupTitle => 'Configurar notificações';

  @override
  String get notificationSettingsTopic => 'Tópico';

  @override
  String get notificationSettingsTopicCopied =>
      'Tópico copiado para a área de transferência';

  @override
  String notificationSettingsUnexpectedError(String error) {
    return 'Erro inesperado: $error';
  }

  @override
  String get notificationSettingsYourTopic => 'Seu tópico';

  @override
  String notificationSetupConfigured(String name) {
    return '$name configurado com sucesso.';
  }

  @override
  String notificationSetupFailed(String name, String error) {
    return 'Falha ao configurar $name: $error';
  }

  @override
  String get notificationSetupNoTopic =>
      'Nenhum tópico do ntfy configurado no Arrmate.';

  @override
  String notificationSetupUpdated(String name) {
    return '$name atualizado com sucesso.';
  }

  @override
  String get notificationsAllCleared => 'Todas as notificações foram removidas';

  @override
  String get notificationsAllMarkedRead =>
      'Todas as notificações foram marcadas como lidas';

  @override
  String get notificationsClearAll => 'Limpar tudo';

  @override
  String get notificationsClearAllConfirm =>
      'Isso removerá todas as notificações. Esta ação não pode ser desfeita.';

  @override
  String get notificationsClearAllTitle => 'Limpar todas as notificações?';

  @override
  String get notificationsDismissed => 'Notificação descartada';

  @override
  String get notificationsEmptySubtitle =>
      'Quando você receber notificações do Radarr ou do Sonarr, elas aparecerão aqui.';

  @override
  String get notificationsEmptyTitle => 'Nenhuma notificação';

  @override
  String get notificationsMarkAllRead => 'Marcar todas como lidas';

  @override
  String get notificationsNewBadge => 'NOVA';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String get playbackLoadMovieFileFailed =>
      'Não foi possível carregar o arquivo do filme';

  @override
  String get playbackNoEpisodeFile =>
      'Nenhum arquivo reproduzível encontrado para este episódio';

  @override
  String get playbackNoJellyfin => 'Nenhum servidor Jellyfin configurado';

  @override
  String get playbackNoMovieFile =>
      'Nenhum arquivo reproduzível encontrado para este filme';

  @override
  String get playbackNotFound =>
      'Não foi possível encontrar esta mídia no Jellyfin';

  @override
  String get playbackSearchingLibrary => 'Buscando na biblioteca do Jellyfin…';

  @override
  String get playbackSessionExpired =>
      'Sua sessão do Jellyfin expirou. Entre novamente.';

  @override
  String get playbackSignIn => 'Entrar';

  @override
  String playbackStartFailed(String error) {
    return 'Não foi possível iniciar a reprodução: $error';
  }

  @override
  String playbackTrackLabel(int index) {
    return 'Faixa $index';
  }

  @override
  String get playerAudio => 'Áudio';

  @override
  String get playerBack => 'Voltar';

  @override
  String get playerExternalOpenFailed =>
      'Não foi possível abrir um player externo';

  @override
  String get playerExternalUnavailable =>
      'Abrir esta mídia em um player externo não está disponível na configuração atual do servidor.';

  @override
  String get playerNoMediaRequested =>
      'Nenhuma mídia foi solicitada para reprodução.';

  @override
  String get playerQualityDataSaver => 'Economia de dados';

  @override
  String get playerQualityOriginal => 'Original';

  @override
  String playerQualityTooltip(String quality) {
    return 'Qualidade: $quality';
  }

  @override
  String get playerStartFailed =>
      'Não foi possível iniciar a reprodução. Verifique sua conexão e tente novamente.';

  @override
  String get playerSubtitleExternal => 'Externa';

  @override
  String get playerSubtitlesDisabled => 'Desativadas';

  @override
  String get playerTitle => 'Player';

  @override
  String get playerUnexpectedFailure => 'A reprodução falhou inesperadamente.';

  @override
  String get playerUnsupportedOnWeb =>
      'A reprodução no app ainda não é compatível com a web';

  @override
  String get providerAssistantDeleteFailed => 'Falha ao excluir o modelo.';

  @override
  String providerAssistantDownloadFailed(String error) {
    return 'Falha ao baixar o modelo: $error';
  }

  @override
  String get providerAssistantEnableOnlineFailed =>
      'Falha ao ativar o modelo online.';

  @override
  String get providerAssistantGenerateFailed => 'Falha ao gerar uma resposta.';

  @override
  String get providerAssistantImportFailed => 'Falha ao importar o modelo.';

  @override
  String get providerAssistantInitFailed =>
      'Falha ao inicializar os recursos do assistente.';

  @override
  String get providerAssistantLoadModelFailed =>
      'Falha ao carregar o modelo selecionado.';

  @override
  String get providerAssistantModelNotFound => 'Modelo não encontrado.';

  @override
  String get providerAssistantNoToolCalling =>
      'Este modelo não suporta tool-calling. Use um modelo Gemma.';

  @override
  String get providerAssistantRefreshModelsFailed =>
      'Falha ao atualizar os modelos instalados.';

  @override
  String get providerAssistantSelectModelFirst =>
      'Selecione um modelo antes de conversar.';

  @override
  String get providerBackupCompleted => 'Backup concluído.';

  @override
  String get providerBackupCorrupt =>
      'O arquivo de backup está corrompido ou é de uma versão não suportada.';

  @override
  String providerBackupExportFailed(String error) {
    return 'Falha ao exportar o backup: $error';
  }

  @override
  String get providerBackupExported => 'Backup exportado para arquivo.';

  @override
  String providerBackupFailed(String error) {
    return 'Falha no backup: $error';
  }

  @override
  String providerBackupLoadFailed(String error) {
    return 'Não foi possível carregar o backup: $error';
  }

  @override
  String get providerBackupNotFound =>
      'Nenhum backup encontrado no seu Google Drive.';

  @override
  String providerBackupReadFileFailed(String error) {
    return 'Não foi possível ler o arquivo de backup: $error';
  }

  @override
  String providerBackupRestoreFailed(String error) {
    return 'Falha na restauração: $error';
  }

  @override
  String providerBackupRestored(int settingsCount, int instanceCount) {
    return '$settingsCount configurações e $instanceCount instâncias restauradas.';
  }

  @override
  String get providerBackupSessionExpired =>
      'A sessão do Google expirou. Entre novamente.';

  @override
  String get providerBackupSignInFailed =>
      'Falha ao entrar. Verifique sua conexão e tente novamente.';

  @override
  String get providerBackupSignedOut => 'Entre com sua conta Google primeiro.';

  @override
  String get providerBackupUnknownError => 'erro desconhecido';

  @override
  String providerInstanceTypeMismatch(String expected, String actual) {
    return 'Esperava $expected, mas conectou a $actual';
  }

  @override
  String get purgeCrossSeedFoundContent =>
      'Foi encontrado um torrent com o mesmo nome de release. Excluí-lo também?';

  @override
  String get purgeCrossSeedFoundTitle => 'Torrent cross-seed encontrado';

  @override
  String get purgeDeleteAll => 'Excluir tudo';

  @override
  String get purgeDeleteAnyway => 'Excluir mesmo assim';

  @override
  String get purgeDeleteTorrent => 'Excluir torrent';

  @override
  String get purgeHash => 'Hash';

  @override
  String get purgeKeepSeeding => 'Continuar semeando';

  @override
  String get purgeKeepTorrent => 'Manter torrent';

  @override
  String get purgeNoTags => 'Sem tags';

  @override
  String get purgeSavePath => 'Caminho de salvamento';

  @override
  String purgeSeededFor(String duration) {
    return 'Semeado por $duration';
  }

  @override
  String get purgeTitleRemovedEitherWay =>
      'De qualquer forma, o título será removido da biblioteca e seus arquivos serão excluídos.';

  @override
  String purgeTorrentBelowMinimum(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return 'Este torrent semeou por menos que o mínimo de $_temp0:';
  }

  @override
  String get purgeTorrentStillSeeding => 'Torrent ainda semeando';

  @override
  String purgeTorrentsBelowMinimum(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Os $count torrents a seguir semearam',
      one: 'O torrent a seguir semeou',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return '$_temp0 por menos que o mínimo de $_temp1:';
  }

  @override
  String get purgeTorrentsStillSeeding => 'Torrents ainda semeando';

  @override
  String get qualityProfilesEmpty =>
      'Nenhum perfil encontrado ou instância não conectada';

  @override
  String qualityProfilesId(String id) {
    return 'ID: $id';
  }

  @override
  String get qualityProfilesRadarr => 'Perfis do Radarr';

  @override
  String get qualityProfilesSonarr => 'Perfis do Sonarr';

  @override
  String get qualityProfilesTitle => 'Perfis de qualidade';

  @override
  String get queueAddToBlocklist => 'Adicionar à lista de bloqueio';

  @override
  String get queueAddToBlocklistSubtitle =>
      'Impedir que este lançamento seja capturado novamente';

  @override
  String get queueAnyClient => 'Qualquer cliente';

  @override
  String get queueAnyInstance => 'Qualquer instância';

  @override
  String get queueAnyProtocol => 'Qualquer protocolo';

  @override
  String get queueAscending => 'Crescente';

  @override
  String get queueCustomFormatScore => 'Pontuação de formato personalizado';

  @override
  String get queueCustomFormats => 'Formatos personalizados';

  @override
  String get queueDescending => 'Decrescente';

  @override
  String get queueDetailPath => 'Caminho';

  @override
  String get queueDirection => 'Direção';

  @override
  String get queueEmptySubtitle => 'Nenhum download ativo no momento.';

  @override
  String get queueEmptyTitle => 'A fila está vazia';

  @override
  String queueEtaDays(int count) {
    return '${count}d';
  }

  @override
  String get queueEtaDone => 'Concluído';

  @override
  String queueEtaHours(int count) {
    return '${count}h';
  }

  @override
  String get queueEtaLessThanMinute => '<1min';

  @override
  String queueEtaMinutes(int count) {
    return '${count}min';
  }

  @override
  String get queueFilterSection => 'Filtro';

  @override
  String get queueGroupedTasks => 'Tarefas agrupadas';

  @override
  String get queueInformation => 'Informações';

  @override
  String get queueInstance => 'Instância';

  @override
  String get queueItemRemoved => 'Item removido da fila';

  @override
  String get queueLoadFailed => 'Não foi possível carregar os dados da fila.';

  @override
  String get queueLoading => 'Carregando fila...';

  @override
  String get queueManualImportDescription =>
      'Este download requer intervenção manual. Selecione quais arquivos importar.';

  @override
  String get queueManualImportRequired => 'Importação manual necessária';

  @override
  String get queueNoMatchSubtitle => 'Ajuste ou redefina os filtros da fila.';

  @override
  String get queueNoMatchTitle => 'Nenhuma tarefa encontrada';

  @override
  String get queueOpenDetails => 'Abrir detalhes';

  @override
  String get queueOpenMovie => 'Abrir filme';

  @override
  String get queueOpenSeries => 'Abrir série';

  @override
  String get queueOptions => 'Opções da fila';

  @override
  String queueProblemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count problemas)',
      one: '(1 problema)',
    );
    return '$_temp0';
  }

  @override
  String get queueProblemsOnly => 'Somente problemas';

  @override
  String get queueProblemsOnlySubtitle =>
      'Mostrar tarefas que precisam de atenção ou importação manual';

  @override
  String get queueRemovalOptions => 'Opções de remoção';

  @override
  String get queueRemoveFromClient => 'Remover do cliente de download';

  @override
  String get queueRemoveFromClientSubtitle => 'Excluir o download do cliente';

  @override
  String get queueRemoveFromQueue => 'Remover da fila';

  @override
  String get queueSearchReplacement => 'Buscar substituto';

  @override
  String get queueSearchReplacementSubtitle =>
      'Buscar automaticamente outro lançamento';

  @override
  String queueSizeLeft(String size) {
    return '$size restantes';
  }

  @override
  String queueTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarefas',
      one: '1 tarefa',
    );
    return '$_temp0';
  }

  @override
  String queueTimeRemainingDaysHours(int days, int hours) {
    return '${days}d ${hours}h restantes';
  }

  @override
  String queueTimeRemainingHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}min restantes';
  }

  @override
  String get queueTimeRemainingLessThanMinute => 'Menos de um minuto';

  @override
  String queueTimeRemainingMinutes(int minutes) {
    return '${minutes}min restantes';
  }

  @override
  String get queueUnableToImport => 'Não foi possível importar automaticamente';

  @override
  String get queueUnknownError => 'Erro desconhecido';

  @override
  String get releasesAge => 'Idade';

  @override
  String releasesAgeDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String releasesAgeShort(int days) {
    return '${days}d';
  }

  @override
  String get releasesApproval => 'Aprovação';

  @override
  String get releasesApproved => 'Aprovada';

  @override
  String get releasesClearSearch => 'Limpar busca';

  @override
  String get releasesCustomFormat => 'Formato personalizado';

  @override
  String get releasesCustomFormatScore => 'Pontuação de formato personalizado';

  @override
  String get releasesCustomFormats => 'Formatos personalizados';

  @override
  String get releasesDetailsTitle => 'Detalhes da release';

  @override
  String get releasesDownload => 'Baixar';

  @override
  String get releasesDownloadRelease => 'Baixar release';

  @override
  String get releasesDownloadTitle => 'Baixar release';

  @override
  String get releasesEpisodeOrMovie => 'Episódio ou filme';

  @override
  String get releasesEpisodes => 'Episódios';

  @override
  String get releasesExcludeFreeleech => 'Excluir freeleech';

  @override
  String get releasesFilterTooltip => 'Filtrar releases';

  @override
  String get releasesFiltersSubtitle => 'Combine quantos filtros quiser';

  @override
  String get releasesFiltersTitle => 'Filtros de releases';

  @override
  String get releasesFreeleech => 'Freeleech';

  @override
  String get releasesFreeleechOnly => 'Somente freeleech';

  @override
  String releasesGrabConfirm(String title) {
    return 'Tem certeza de que deseja capturar \"$title\"?';
  }

  @override
  String releasesGrabError(String error) {
    return 'Erro ao capturar a release: $error';
  }

  @override
  String get releasesGrabSuccess => 'Release capturada com sucesso';

  @override
  String get releasesIndexerFlags => 'Flags do indexador';

  @override
  String get releasesLanguages => 'Idiomas';

  @override
  String get releasesMappedEpisodes => 'Episódios mapeados';

  @override
  String get releasesNoMatch =>
      'Nenhuma release corresponde aos filtros atuais';

  @override
  String get releasesNoneFound => 'Nenhuma release encontrada';

  @override
  String get releasesOriginalLanguageOnly => 'Somente idioma original';

  @override
  String get releasesQualityWeight => 'Peso da qualidade';

  @override
  String get releasesRejected => 'Rejeitada';

  @override
  String get releasesRejectedTooltip => 'Release rejeitada';

  @override
  String get releasesRejectionReasons => 'Motivos da rejeição';

  @override
  String get releasesReleaseRejected => 'Release rejeitada';

  @override
  String get releasesReleaseType => 'Tipo de release';

  @override
  String get releasesReleaseWeight => 'Peso da release';

  @override
  String get releasesRememberFilters => 'Lembrar filtros';

  @override
  String get releasesRememberFiltersSubtitle =>
      'Manter esta configuração para buscas futuras';

  @override
  String get releasesRequestedEpisode => 'Episódio solicitado';

  @override
  String releasesResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String releasesResultCountHidden(int count, int hidden) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hidden,
      locale: localeName,
      other: '$hidden ocultos',
      one: '1 oculto',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get releasesSearchHint => 'Buscar releases';

  @override
  String get releasesSeasonPack => 'Pacote da temporada';

  @override
  String get releasesSeasonPacks => 'Pacotes de temporada';

  @override
  String get releasesSeeders => 'Seeders';

  @override
  String get releasesSeedsPeers => 'Seeds / peers';

  @override
  String get releasesSendingTooltip =>
      'Enviando release para o cliente de download';

  @override
  String seriesAddFailed(String error) {
    return 'Erro ao adicionar a série: $error';
  }

  @override
  String get seriesAddMissingSelection =>
      'Selecione uma série, um perfil de qualidade e uma pasta raiz';

  @override
  String get seriesAddSeries => 'Adicionar série';

  @override
  String get seriesAddSeriesTitle => 'Adicionar série';

  @override
  String get seriesAddedSuccessfully => 'Série adicionada com sucesso';

  @override
  String get seriesAirDate => 'Data de exibição';

  @override
  String get seriesAllFolders => 'Todas as pastas';

  @override
  String get seriesAllSeasonsMonitored => 'Todas as temporadas monitoradas';

  @override
  String get seriesAllSeasonsUnmonitored =>
      'Todas as temporadas desmonitoradas';

  @override
  String get seriesAlsoDeleteFiles => 'Excluir também os arquivos do disco';

  @override
  String get seriesAndFilesDeleted => 'Série e arquivos excluídos';

  @override
  String get seriesConfigureAddition => 'Configurar adição';

  @override
  String seriesDeleteFailed(String error) {
    return 'Falha ao excluir: $error';
  }

  @override
  String get seriesDeleteFile => 'Excluir arquivo';

  @override
  String get seriesDeleteFileConfirm =>
      'Tem certeza de que deseja excluir este arquivo? Esta ação não pode ser desfeita.';

  @override
  String seriesDeleteFilesConfirm(String title) {
    return 'Excluir todos os arquivos de \"$title\"? Isso remove do disco todos os arquivos de episódio; a série continua no Sonarr.';
  }

  @override
  String seriesDeleteFilesFailed(String error) {
    return 'Falha ao excluir arquivos: $error';
  }

  @override
  String seriesDeleteFilesForSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir arquivos de $count temporadas',
      one: 'Excluir arquivos de 1 temporada',
    );
    return '$_temp0';
  }

  @override
  String get seriesDeleteSeasonFiles => 'Excluir arquivos da temporada';

  @override
  String seriesDeleteSeasonFilesConfirm(String title, int season) {
    return 'Excluir todos os arquivos de \"$title - Temporada $season\"? Isso remove do disco todos os arquivos de episódio desta temporada.';
  }

  @override
  String get seriesDeleteSeasonsFilesContent =>
      'Isso exclui do disco os arquivos de episódio das temporadas selecionadas. A série continua no Sonarr.';

  @override
  String get seriesDeleteSeries => 'Excluir série';

  @override
  String seriesDeleteSeriesConfirm(String title) {
    return 'Tem certeza de que deseja excluir \"$title\"?';
  }

  @override
  String get seriesDeleted => 'Série excluída';

  @override
  String seriesDeletedFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos excluídos',
      one: '1 arquivo excluído',
    );
    return '$_temp0';
  }

  @override
  String get seriesEditSeries => 'Editar série';

  @override
  String get seriesEmptySubtitle =>
      'Adicione séries à sua biblioteca do Sonarr para vê-las aqui.';

  @override
  String get seriesEpisodeActions => 'Ações do episódio';

  @override
  String seriesEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episódios',
      one: '1 episódio',
    );
    return '$_temp0';
  }

  @override
  String seriesEpisodeLoadFailed(String error) {
    return 'Falha ao carregar o episódio: $error';
  }

  @override
  String get seriesEpisodeLoading => 'Carregando episódio...';

  @override
  String get seriesEpisodeMonitored => 'Episódio monitorado';

  @override
  String get seriesEpisodeUnmonitored => 'Episódio desmonitorado';

  @override
  String get seriesFile => 'Arquivo';

  @override
  String get seriesFileDeleted => 'Arquivo excluído';

  @override
  String get seriesHideAlreadyAdded => 'Ocultar já adicionadas';

  @override
  String get seriesHistory => 'Histórico';

  @override
  String seriesLoadEpisodesFailed(String error) {
    return 'Falha ao carregar episódios: $error';
  }

  @override
  String get seriesLoadFileInfoFailed =>
      'Falha ao carregar informações do arquivo';

  @override
  String seriesLoadFoldersError(String error) {
    return 'Erro ao carregar pastas: $error';
  }

  @override
  String get seriesLoadHistoryFailed => 'Falha ao carregar o histórico';

  @override
  String seriesLoadProfilesError(String error) {
    return 'Erro ao carregar perfis: $error';
  }

  @override
  String get seriesLoadingDetails => 'Carregando detalhes...';

  @override
  String get seriesLoadingSeries => 'Carregando séries...';

  @override
  String get seriesMonitorEpisode => 'Monitorar episódio';

  @override
  String get seriesMonitorNewSeasons => 'Monitorar novas temporadas';

  @override
  String get seriesMonitorNewSeasonsSubtitle =>
      'Monitorar automaticamente temporadas adicionadas no futuro';

  @override
  String get seriesMonitoredSubtitle => 'Monitorar episódios desta série';

  @override
  String get seriesMoveFilesContent =>
      'Você alterou a pasta raiz. Deseja mover os arquivos existentes para o novo local?';

  @override
  String get seriesMoveFilesTitle => 'Mover arquivos?';

  @override
  String get seriesNetwork => 'Emissora';

  @override
  String get seriesNoEpisodesFound => 'Nenhum episódio encontrado';

  @override
  String get seriesNoFileAvailable => 'Nenhum arquivo disponível';

  @override
  String get seriesNoFilesToDelete => 'Nenhum arquivo para excluir';

  @override
  String get seriesNoHistoryEvents => 'Nenhum evento no histórico';

  @override
  String get seriesNoOverview => 'Nenhuma sinopse disponível.';

  @override
  String get seriesNoRating => 'Sem avaliação';

  @override
  String get seriesNoResultsFound => 'Nenhum resultado encontrado';

  @override
  String get seriesNoResultsSubtitle =>
      'Tente limpar ou ajustar sua busca ou filtros.';

  @override
  String get seriesNoSeriesFound => 'Nenhuma série encontrada';

  @override
  String get seriesNoSonarrInstance =>
      'Nenhuma instância do Sonarr configurada';

  @override
  String get seriesOverview => 'Sinopse';

  @override
  String get seriesPath => 'Caminho';

  @override
  String get seriesPreventReAdd =>
      'Impedir que esta série seja adicionada novamente';

  @override
  String get seriesPreview => 'Prévia da série';

  @override
  String seriesPreviewCrossSeedsFailed(String error) {
    return 'Falha ao gerar a prévia de cross-seeds: $error';
  }

  @override
  String seriesPreviewFailed(String error) {
    return 'Falha ao gerar a prévia: $error';
  }

  @override
  String seriesPurgeFailed(String error) {
    return 'Falha ao expurgar: $error';
  }

  @override
  String get seriesPurgeSeason => 'Expurgar temporada';

  @override
  String seriesPurgeSeasonConfirm(String title, int season) {
    return 'Excluir todos os arquivos de \"$title - Temporada $season\" e remover os torrents de origem do qBittorrent? A série continua no Sonarr.';
  }

  @override
  String get seriesPurgeSeasonsContent =>
      'Isso exclui os arquivos de episódio das temporadas selecionadas e seus torrents de origem do qBittorrent. A série continua no Sonarr.';

  @override
  String seriesPurgeSeasonsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expurgar $count temporadas',
      one: 'Expurgar 1 temporada',
    );
    return '$_temp0';
  }

  @override
  String get seriesPurgeSeries => 'Expurgar série';

  @override
  String seriesPurgeSeriesConfirm(String title) {
    return 'Isso removerá permanentemente \"$title\" e todos os seus episódios do Sonarr, excluirá seus arquivos de mídia e excluirá todos os torrents de origem (incluindo duplicatas de cross-seed) do qBittorrent. Libera o espaço em disco usado por dados com hardlink.';
  }

  @override
  String get seriesPurged => 'Série expurgada.';

  @override
  String seriesPurgedSeasonsSummary(int seasons, int files, int torrents) {
    String _temp0 = intl.Intl.pluralLogic(
      seasons,
      locale: localeName,
      other: '$seasons temporadas expurgadas',
      one: '1 temporada expurgada',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files arquivos',
      one: '1 arquivo',
    );
    String _temp2 = intl.Intl.pluralLogic(
      torrents,
      locale: localeName,
      other: '$torrents torrents',
      one: '1 torrent',
    );
    return '$_temp0: $_temp1, $_temp2.';
  }

  @override
  String seriesPurgedSummary(int files, int torrents) {
    String _temp0 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files arquivos',
      one: '1 arquivo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      torrents,
      locale: localeName,
      other: '$torrents torrents',
      one: '1 torrent',
    );
    return 'Expurgado: $_temp0, $_temp1.';
  }

  @override
  String get seriesRefreshAndScan => 'Atualizar e escanear';

  @override
  String get seriesRefreshScanTriggered =>
      'Atualização e escaneamento iniciados';

  @override
  String seriesRootFolderFreeSpace(String path, String free) {
    return '$path ($free GB livres)';
  }

  @override
  String get seriesRootFolderHeader => 'PASTA RAIZ';

  @override
  String seriesRuntimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get seriesSearchByHint => 'Busque por título, ID do provedor ou URL';

  @override
  String seriesSearchFailed(String error) {
    return 'Falha na busca: $error';
  }

  @override
  String get seriesSearchHint => 'Buscar séries...';

  @override
  String seriesSearchStartedFor(String name) {
    return 'Busca iniciada para $name';
  }

  @override
  String seriesSearchStartedForSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Busca iniciada para $count temporadas',
      one: 'Busca iniciada para 1 temporada',
    );
    return '$_temp0';
  }

  @override
  String seriesSearchingFor(String name) {
    return 'Buscando $name...';
  }

  @override
  String get seriesSeasonActions => 'Ações da temporada';

  @override
  String seriesSeasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temporadas',
      one: '1 temporada',
    );
    return '$_temp0';
  }

  @override
  String get seriesSeasonFolder => 'Pasta de temporada';

  @override
  String get seriesSeasonFolders => 'Pastas de temporada';

  @override
  String get seriesSeasonFoldersSubtitle =>
      'Usar pastas por temporada (ex.: Season 01/...)';

  @override
  String seriesSeasonLoadFailed(String error) {
    return 'Falha ao carregar a temporada: $error';
  }

  @override
  String get seriesSeasonLoading => 'Carregando temporada...';

  @override
  String get seriesSeasonTitle => 'Temporada';

  @override
  String get seriesSeasons => 'Temporadas';

  @override
  String get seriesSelect => 'Selecionar';

  @override
  String get seriesSelectPath => 'Selecionar caminho';

  @override
  String seriesSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionadas',
      one: '1 selecionada',
    );
    return '$_temp0';
  }

  @override
  String get seriesSeriesType => 'Tipo de série';

  @override
  String get seriesSortAndFilter => 'Ordenar e filtrar';

  @override
  String get seriesSwitchToGrid => 'Mudar para grade';

  @override
  String get seriesSwitchToList => 'Mudar para lista';

  @override
  String seriesTitleWithSeason(String title, int season) {
    return '$title - Temporada $season';
  }

  @override
  String seriesUnableToOpenLink(String error) {
    return 'Não foi possível abrir o link: $error';
  }

  @override
  String get seriesUnmonitorEpisode => 'Desmonitorar episódio';

  @override
  String seriesUnmonitoredSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temporadas desmonitoradas',
      one: '1 temporada desmonitorada',
    );
    return '$_temp0';
  }

  @override
  String seriesUpdateEpisodeFailed(String error) {
    return 'Falha ao atualizar o episódio: $error';
  }

  @override
  String seriesUpdateFailed(String error) {
    return 'Erro ao atualizar a série: $error';
  }

  @override
  String seriesViewPoster(String title) {
    return 'Ver pôster de $title';
  }

  @override
  String get seriesWatch => 'Assistir';

  @override
  String get seriesYesMoveFiles => 'Sim, mover arquivos';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsAddInstance => 'Adicionar instância';

  @override
  String get settingsAppUpToDate => 'O app está atualizado';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsAssistant => 'Assistente';

  @override
  String get settingsAssistantSubtitle => 'Pergunte como o app funciona';

  @override
  String get settingsBackupLocalFileSubtitle =>
      'Importar ou exportar um arquivo local';

  @override
  String get settingsColorScheme => 'Esquema de cores';

  @override
  String get settingsCouldNotCheckUpdates =>
      'Não foi possível verificar atualizações';

  @override
  String get settingsGettingStarted => 'Primeiros passos';

  @override
  String get settingsGettingStartedSubtitle => 'Repetir o tour de configuração';

  @override
  String get settingsHomeTab => 'Aba inicial';

  @override
  String settingsInstanceTagCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return '$_temp0';
  }

  @override
  String get settingsInstances => 'Instâncias';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsNoArrInstancesConfigured =>
      'Nenhuma instância Arr configurada';

  @override
  String get settingsNoInstances => 'Nenhuma instância configurada';

  @override
  String get settingsNoRadarrSonarrInstances =>
      'Nenhuma instância do Radarr ou Sonarr configurada';

  @override
  String get settingsNotificationCenter => 'Central de notificações';

  @override
  String get settingsNotificationSettings => 'Configurações de notificação';

  @override
  String get settingsNotifications => 'Notificações';

  @override
  String get settingsNotificationsEnabledSubtitle =>
      'Ativado · integração com ntfy.sh';

  @override
  String get settingsNotificationsSetupSubtitle => 'Configurar notificações';

  @override
  String get settingsSelectColor => 'Selecionar cor';

  @override
  String get settingsSelectHomeTab => 'Selecionar aba inicial';

  @override
  String get settingsSelectLanguage => 'Selecionar idioma';

  @override
  String get settingsSelectMode => 'Selecionar modo';

  @override
  String get settingsSessionExpiredSignIn =>
      'Sessão expirada · toque para entrar';

  @override
  String get settingsSourceCode => 'Código-fonte';

  @override
  String get settingsSystem => 'Sistema';

  @override
  String get settingsSystemManagementSubtitle =>
      'Diagnóstico, status, logs e manutenção do app';

  @override
  String get settingsThemeMode => 'Modo do tema';

  @override
  String settingsUnreadNotifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificações não lidas',
      one: '1 notificação não lida',
    );
    return '$_temp0';
  }

  @override
  String get settingsVersion => 'Versão';

  @override
  String settingsVersionViaAltStore(String version) {
    return '$version • atualizações via AltStore';
  }

  @override
  String get settingsViewAllNotifications => 'Ver todas as notificações';

  @override
  String get sharedAddImportExclusion =>
      'Adicionar à lista de exclusão de importação';

  @override
  String get sharedAddImportExclusionSubtitle =>
      'Impede que o item seja adicionado novamente por uma lista de importação.';

  @override
  String get sharedAscending => 'Crescente';

  @override
  String sharedBatchDeleteFilesFailed(String error) {
    return 'Falha ao excluir arquivos: $error';
  }

  @override
  String get sharedBatchDeleteMovieFilesContent =>
      'Isso exclui do disco os arquivos de mídia dos filmes selecionados. Eles permanecem no Radarr.';

  @override
  String sharedBatchDeleteMovieFilesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir arquivos de $count filmes',
      one: 'Excluir arquivos de 1 filme',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteMoviesKeepFiles =>
      'Isso remove os filmes selecionados do Radarr. Os arquivos permanecem no disco.';

  @override
  String sharedBatchDeleteMoviesPartial(int deleted, int total, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total filmes',
      one: '1 filme',
    );
    return '$deleted de $_temp0 excluídos antes do erro: $error';
  }

  @override
  String sharedBatchDeleteMoviesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count filmes',
      one: 'Excluir 1 filme',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteMoviesWithFiles =>
      'Isso remove os filmes selecionados do Radarr e exclui os arquivos deles do disco.';

  @override
  String get sharedBatchDeleteSeriesFilesContent =>
      'Isso exclui do disco os arquivos de mídia das séries selecionadas. Elas permanecem no Sonarr.';

  @override
  String sharedBatchDeleteSeriesFilesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir arquivos de $count séries',
      one: 'Excluir arquivos de 1 série',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteSeriesKeepFiles =>
      'Isso remove as séries selecionadas do Sonarr. Os arquivos permanecem no disco.';

  @override
  String sharedBatchDeleteSeriesPartial(int deleted, int total, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total séries',
      one: '1 série',
    );
    return '$deleted de $_temp0 excluídas antes do erro: $error';
  }

  @override
  String sharedBatchDeleteSeriesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count séries',
      one: 'Excluir 1 série',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteSeriesWithFiles =>
      'Isso remove as séries selecionadas do Sonarr e exclui os arquivos delas do disco.';

  @override
  String sharedBatchDeletedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos excluídos',
      one: '1 arquivo excluído',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filmes excluídos',
      one: '1 filme excluído',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedMoviesAndFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filmes e arquivos excluídos',
      one: '1 filme e arquivos excluídos',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries excluídas',
      one: '1 série excluída',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedSeriesAndFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries e arquivos excluídos',
      one: '1 série e arquivos excluídos',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchMonitoredMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filmes monitorados',
      one: '1 filme monitorado',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchMonitoredSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries monitoradas',
      one: '1 série monitorada',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchPreviewCrossSeedsFailed(String error) {
    return 'Falha ao gerar a prévia dos cross-seeds: $error';
  }

  @override
  String sharedBatchPreviewFailed(String error) {
    return 'Falha ao gerar a prévia: $error';
  }

  @override
  String sharedBatchPurgeFailed(String error) {
    return 'Falha ao expurgar: $error';
  }

  @override
  String get sharedBatchPurgeMoviesContent =>
      'Isso remove permanentemente os filmes selecionados do Radarr, exclui os arquivos deles e exclui todos os torrents de origem do qBittorrent.';

  @override
  String sharedBatchPurgeMoviesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expurgar $count filmes',
      one: 'Expurgar 1 filme',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchPurgeSeriesContent =>
      'Isso remove permanentemente as séries selecionadas do Sonarr, exclui os arquivos delas e exclui todos os torrents de origem do qBittorrent.';

  @override
  String sharedBatchPurgeSeriesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expurgar $count séries',
      one: 'Expurgar 1 série',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchPurgedMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filmes expurgados.',
      one: '1 filme expurgado.',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchPurgedSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries expurgadas.',
      one: '1 série expurgada.',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchUnmonitoredMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filmes deixaram de ser monitorados',
      one: '1 filme deixou de ser monitorado',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchUnmonitoredSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries deixaram de ser monitoradas',
      one: '1 série deixou de ser monitorada',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchUpdateMoviesPartial(int updated, int total, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total filmes',
      one: '1 filme',
    );
    return '$updated de $_temp0 atualizados antes do erro: $error';
  }

  @override
  String sharedBatchUpdateSeriesPartial(int updated, int total, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total séries',
      one: '1 série',
    );
    return '$updated de $_temp0 atualizadas antes do erro: $error';
  }

  @override
  String get sharedDescending => 'Decrescente';

  @override
  String get sharedFailedToLoadTorrents => 'Falha ao carregar os torrents';

  @override
  String get sharedNoRadarrInstance =>
      'Nenhuma instância do Radarr configurada';

  @override
  String get sharedNoTorrentsInClient =>
      'Nenhum torrent no cliente de download';

  @override
  String sharedSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionados',
      one: '1 selecionado',
    );
    return '$_temp0';
  }

  @override
  String get sharedTorrents => 'Torrents';

  @override
  String get systemAppMaintenance => 'Manutenção do app';

  @override
  String get systemClearImageCache => 'Limpar cache de imagens';

  @override
  String get systemClearImageCacheSubtitle =>
      'Libere o espaço usado por pôsteres e imagens em cache';

  @override
  String get systemDaysHelper => '0 desativa o aviso';

  @override
  String get systemDaysInvalid => 'Informe um número válido (0 ou mais)';

  @override
  String get systemDaysLabel => 'Dias';

  @override
  String get systemDiagnosticsSubtitle =>
      'Teste endpoints, latência, rastros de requisições e exporte um relatório';

  @override
  String get systemHealth => 'Saúde';

  @override
  String get systemHealthSubtitle =>
      'Alertas do Radarr e Sonarr reportados pelo servidor';

  @override
  String get systemImageCacheCleared => 'Cache de imagens limpo';

  @override
  String get systemLogs => 'Logs';

  @override
  String get systemLogsSubtitle => 'Logs de eventos do sistema';

  @override
  String get systemManagementTitle => 'Gerenciamento do sistema';

  @override
  String get systemMinimumSeedingDays => 'Dias mínimos de semeadura';

  @override
  String get systemMinimumSeedingDaysDescription =>
      'Torrents que semearam por menos tempo que isso pedem confirmação antes de serem excluídos. Use 0 para desativar.';

  @override
  String get systemOverviewDiskSpace => 'Espaço em disco';

  @override
  String get systemOverviewDiskSpaceUnavailable =>
      'As informações de espaço em disco não estão disponíveis.';

  @override
  String get systemOverviewEmptySubtitle =>
      'Adicione uma instância do Radarr ou Sonarr para ver os dados do sistema.';

  @override
  String systemOverviewEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Episódios',
      one: '1 Episódio',
    );
    return '$_temp0';
  }

  @override
  String systemOverviewFreeOf(String free, String total) {
    return '$free livres de $total';
  }

  @override
  String systemOverviewLibrarySize(String size) {
    return '$size Biblioteca';
  }

  @override
  String get systemOverviewLibraryUnavailable =>
      'As estatísticas da biblioteca não estão disponíveis.';

  @override
  String get systemOverviewLoadFailed =>
      'Falha ao carregar a visão geral do sistema.';

  @override
  String get systemOverviewLoading => 'Carregando visão geral do sistema...';

  @override
  String systemOverviewMovieCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Filmes',
      one: '1 Filme',
    );
    return '$_temp0';
  }

  @override
  String get systemOverviewNoStorage =>
      'Nenhum local de armazenamento reportado.';

  @override
  String systemOverviewSeriesCount(int count) {
    return '$count Séries';
  }

  @override
  String get systemOverviewSubtitle =>
      'Armazenamento, versões e tamanho das bibliotecas';

  @override
  String get systemOverviewTitle => 'Visão geral do sistema';

  @override
  String systemOverviewUsed(String size, int percent) {
    return 'Usado $size ($percent%)';
  }

  @override
  String get systemOverviewVersionUnavailable =>
      'As informações de versão não estão disponíveis.';

  @override
  String get systemQualityProfilesSubtitle =>
      'Perfis disponíveis nas instâncias';

  @override
  String get systemResetConfirmBody =>
      'Isso restaura aparência, idioma, modo de visualização e preferências de notificação para os padrões. As instâncias configuradas são mantidas.';

  @override
  String get systemResetConfirmTitle => 'Redefinir configurações do app?';

  @override
  String get systemResetSettings => 'Redefinir configurações do app';

  @override
  String get systemResetSettingsSubtitle =>
      'Restaura os padrões de aparência, idioma, visualização e notificações';

  @override
  String systemSeedingDaysShort(int count) {
    return '${count}d';
  }

  @override
  String get systemSeedingWarningDisabled => 'Aviso de semeadura desativado';

  @override
  String systemSeedingWarningEnabled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return 'Avisar antes de excluir torrents que semearam por menos de $_temp0.';
  }

  @override
  String get systemServer => 'Servidor';

  @override
  String get systemSettingsReset =>
      'Configurações do app redefinidas para os padrões';

  @override
  String get systemTorrentProtection => 'Proteção de torrents';

  @override
  String get systemVersionHistorySubtitle =>
      'Novidades de cada versão publicada';

  @override
  String torrentAddFailed(String error) {
    return 'Falha ao adicionar torrent: $error';
  }

  @override
  String get torrentAddOptions => 'Opções';

  @override
  String get torrentAddOr => 'OU';

  @override
  String get torrentAddSource => 'Origem';

  @override
  String get torrentAddSourceRequired =>
      'Informe URLs ou selecione um arquivo .torrent';

  @override
  String get torrentAddTorrent => 'Adicionar torrent';

  @override
  String get torrentAdded => 'Torrent adicionado com sucesso';

  @override
  String get torrentAlsoDeleteFiles => 'Também excluir os arquivos do disco';

  @override
  String get torrentCategoriesLoadFailed =>
      'Não foi possível carregar as categorias. Usando texto livre.';

  @override
  String get torrentCategoryOptional => 'Categoria (opcional)';

  @override
  String get torrentChangeSaveLocation => 'Alterar local de salvamento';

  @override
  String get torrentChangeSaveLocationWarning =>
      'Isso moverá todos os dados baixados para o novo local.';

  @override
  String get torrentClearSearch => 'Limpar busca';

  @override
  String torrentConnectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conectados',
      one: '1 conectado',
    );
    return '$_temp0';
  }

  @override
  String get torrentCrossSeedExplanation =>
      'Identificado como cross-seed: mesmo nome de release do torrent que o Radarr/Sonarr capturou, infohash diferente.';

  @override
  String get torrentEmptySubtitle =>
      'Adicione um torrent para começar a baixar';

  @override
  String get torrentEmptyTitle => 'Nenhum torrent';

  @override
  String get torrentEnterValidPath => 'Informe um caminho válido';

  @override
  String torrentEta(String eta) {
    return 'Restante: $eta';
  }

  @override
  String get torrentFiles => 'Arquivos';

  @override
  String get torrentFilterLibraryLink => 'Vínculo com a biblioteca';

  @override
  String get torrentFilterTooltip => 'Filtrar torrents';

  @override
  String get torrentFiltersSubtitle => 'Combine quantos filtros quiser';

  @override
  String get torrentFiltersTitle => 'Filtros de torrent';

  @override
  String torrentImportFailed(String error) {
    return 'Falha ao importar: $error';
  }

  @override
  String torrentImportFilesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos importados com sucesso',
      one: '1 arquivo importado com sucesso',
    );
    return '$_temp0';
  }

  @override
  String torrentImportFilesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos selecionados para importação',
      one: '1 arquivo selecionado para importação',
    );
    return '$_temp0';
  }

  @override
  String get torrentImportLoadMoviesFailed => 'Falha ao carregar filmes';

  @override
  String get torrentImportLoadSeriesFailed => 'Falha ao carregar séries';

  @override
  String get torrentImportLoadingMovies => 'Carregando filmes...';

  @override
  String get torrentImportLoadingSeries => 'Carregando séries...';

  @override
  String get torrentImportNoFilesSelected => 'Nenhum arquivo selecionado';

  @override
  String torrentImportNoFilesSubtitle(String path) {
    return 'Nenhum arquivo importável encontrado em $path';
  }

  @override
  String get torrentImportNoFilesTitle => 'Nenhum arquivo encontrado';

  @override
  String get torrentImportNoMoviesSubtitle =>
      'Nenhum filme monitorado corresponde à sua busca.';

  @override
  String get torrentImportNoMoviesTitle => 'Nenhum filme encontrado';

  @override
  String get torrentImportNoSeriesSubtitle =>
      'Nenhuma série monitorada corresponde à sua busca.';

  @override
  String get torrentImportNoSeriesTitle => 'Nenhuma série encontrada';

  @override
  String get torrentImportSearchHint => 'Buscar...';

  @override
  String get torrentImportSelectFilesHint =>
      'Selecione os arquivos para importar. Toque em um arquivo para configurar o mapeamento.';

  @override
  String get torrentImportSelectTarget => 'Selecionar destino';

  @override
  String get torrentImportToLibrary => 'Importar para a biblioteca';

  @override
  String get torrentImportToMovie => 'Importar para filme';

  @override
  String get torrentImportToSeries => 'Importar para série';

  @override
  String get torrentInfoAddedOn => 'Adicionado em';

  @override
  String get torrentInfoCategory => 'Categoria';

  @override
  String get torrentInfoHash => 'Hash';

  @override
  String get torrentInfoInstance => 'Instância';

  @override
  String get torrentInfoMedia => 'Mídia';

  @override
  String get torrentInfoSavePath => 'Caminho';

  @override
  String get torrentLibraryLinksLoadFailed =>
      'Não foi possível carregar os vínculos com a biblioteca.';

  @override
  String get torrentLoadFailed => 'Falha ao carregar torrents';

  @override
  String torrentLoadFilesFailed(String error) {
    return 'Falha ao carregar arquivos: $error';
  }

  @override
  String get torrentLoadPeersFailed => 'Falha ao carregar peers';

  @override
  String get torrentLoadTrackersFailed => 'Falha ao carregar trackers';

  @override
  String get torrentLoading => 'Carregando torrents...';

  @override
  String get torrentLoadingFiles => 'Carregando arquivos...';

  @override
  String get torrentLoadingPeers => 'Carregando peers...';

  @override
  String get torrentLoadingTrackers => 'Carregando trackers...';

  @override
  String get torrentLocationMoved =>
      'Local alterado com sucesso. Os dados estão sendo movidos.';

  @override
  String get torrentMove => 'Mover';

  @override
  String torrentMoveFailed(String error) {
    return 'Falha ao mover: $error';
  }

  @override
  String get torrentNewLocation => 'Novo local';

  @override
  String get torrentNoFilesFound => 'Nenhum arquivo encontrado';

  @override
  String get torrentNoFilterMatches =>
      'Nenhum torrent corresponde aos filtros atuais';

  @override
  String get torrentNoPeers => 'Nenhum peer conectado';

  @override
  String get torrentNoPeersSubtitle =>
      'Os peers aparecerão quando o torrent estiver ativo';

  @override
  String get torrentNoTrackers => 'Nenhum tracker';

  @override
  String get torrentNoTrackersSubtitle =>
      'As URLs de anúncio aparecem aqui quando o qBittorrent as tiver';

  @override
  String get torrentPause => 'Pausar';

  @override
  String torrentPeerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peers',
      one: '1 peer',
    );
    return '$_temp0';
  }

  @override
  String get torrentPeers => 'Peers';

  @override
  String torrentPercentCompleted(String percent) {
    return '$percent concluído';
  }

  @override
  String torrentPercentDone(String percent) {
    return '$percent concluído';
  }

  @override
  String torrentPickFileFailed(String error) {
    return 'Falha ao selecionar arquivo: $error';
  }

  @override
  String get torrentRecheck => 'Verificar';

  @override
  String get torrentRememberFilters => 'Lembrar filtros';

  @override
  String get torrentRememberFiltersSubtitle =>
      'Manter esta configuração para as próximas sessões';

  @override
  String get torrentRemove => 'Remover';

  @override
  String torrentRemoveConfirm(String name) {
    return 'Tem certeza de que deseja remover \"$name\"?';
  }

  @override
  String torrentRemoveFailed(String error) {
    return 'Falha ao remover torrent: $error';
  }

  @override
  String get torrentRemoveTitle => 'Remover torrent?';

  @override
  String get torrentRemoveTorrent => 'Remover torrent';

  @override
  String torrentResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count torrents',
      one: '1 torrent',
    );
    return '$_temp0';
  }

  @override
  String torrentResultCountWithHidden(int count, int hidden) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count torrents · ocultos: $hidden',
      one: '1 torrent · ocultos: $hidden',
    );
    return '$_temp0';
  }

  @override
  String get torrentResume => 'Retomar';

  @override
  String get torrentSavePathOptional => 'Caminho de salvamento (opcional)';

  @override
  String get torrentSearchHint => 'Buscar torrents';

  @override
  String get torrentSectionActions => 'Ações';

  @override
  String get torrentSectionInformation => 'Informações';

  @override
  String get torrentSectionMediaLibrary => 'Biblioteca de mídia';

  @override
  String get torrentSectionProgress => 'Progresso';

  @override
  String get torrentSelectFile => 'Selecionar arquivo .torrent';

  @override
  String get torrentSetPriority => 'Definir prioridade';

  @override
  String get torrentSortAscending => 'Crescente';

  @override
  String get torrentSortDescending => 'Decrescente';

  @override
  String get torrentStartPaused => 'Iniciar pausado';

  @override
  String get torrentStatDlSpeed => 'Vel. download';

  @override
  String get torrentStatDownloaded => 'Baixado';

  @override
  String get torrentStatLeechers => 'Leechers';

  @override
  String get torrentStatRatio => 'Proporção';

  @override
  String get torrentStatSeedTime => 'Tempo semeando';

  @override
  String get torrentStatSeeds => 'Seeds';

  @override
  String get torrentStatTotalSize => 'Tamanho total';

  @override
  String get torrentStatUlSpeed => 'Vel. upload';

  @override
  String get torrentStatUploaded => 'Enviado';

  @override
  String get torrentTagsCommaSeparated => 'Separadas por vírgula';

  @override
  String get torrentTagsLoadFailed =>
      'Não foi possível carregar as tags. Usando texto livre.';

  @override
  String get torrentTagsOptional => 'Tags (opcional)';

  @override
  String get torrentTagsSearchHint => 'Digite para buscar ou adicionar tags';

  @override
  String torrentTrackerDownloads(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count downloads',
      one: '1 download',
    );
    return '$_temp0';
  }

  @override
  String torrentTrackerLeechers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leechers',
      one: '1 leecher',
    );
    return '$_temp0';
  }

  @override
  String torrentTrackerPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peers',
      one: '1 peer',
    );
    return '$_temp0';
  }

  @override
  String torrentTrackerSeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seeds',
      one: '1 seed',
    );
    return '$_temp0';
  }

  @override
  String torrentTrackerTier(int tier) {
    return 'Nível $tier';
  }

  @override
  String get torrentTrackers => 'Trackers';

  @override
  String get torrentUrlsHint =>
      'Cole links magnet ou URLs HTTP aqui\nUm por linha';

  @override
  String get torrentUrlsLabel => 'Link magnet ou URLs';

  @override
  String get tourActivityBody =>
      'Acompanhe aqui sua fila de downloads, o histórico e os torrents do qBittorrent.';

  @override
  String get tourActivityQueueBody =>
      'Os downloads ativos mostram o progresso, o tamanho restante e a previsão de conclusão. Toque em um para ver detalhes e ações.';

  @override
  String get tourActivityQueueTitle => 'Fila de downloads';

  @override
  String get tourAddInstanceBody =>
      'Toque aqui para criar uma nova conexão com um servidor. Os próximos passos explicam o formulário.';

  @override
  String get tourAddInstanceTitle => 'Adicionar instância';

  @override
  String get tourCalendarBody =>
      'Acompanhe os próximos lançamentos de filmes e episódios de séries.';

  @override
  String get tourCalendarEventsBody =>
      'Cada cartão mostra o que será exibido ou lançado em seguida, agrupado por dia e com cores por tipo de lançamento.';

  @override
  String get tourCalendarEventsTitle => 'Próximos lançamentos';

  @override
  String get tourInstanceApiKeyBody =>
      'Radarr/Sonarr exigem uma API Key, disponível em Settings → General. O qBittorrent usa um token Bearer (v5.2.0+) ou Basic Auth.';

  @override
  String get tourInstanceApiKeyTitle => 'API Key';

  @override
  String get tourInstanceNameBody =>
      'Um nome amigável para diferenciar seus servidores (ex.: \"Servidor de casa\").';

  @override
  String get tourInstanceNameTitle => 'Nome';

  @override
  String get tourInstanceTypeBody =>
      'Escolha Radarr (filmes), Sonarr (séries) ou qBittorrent (downloads). Cada um precisa da sua própria conexão.';

  @override
  String get tourInstanceTypeTitle => 'Escolha o tipo de servidor';

  @override
  String get tourInstanceUrlBody =>
      'O endereço do seu servidor com http(s):// e a porta, ex.: http://192.168.1.10:7878.';

  @override
  String get tourInstanceUrlTitle => 'URL';

  @override
  String get tourInstancesBody =>
      'Seus servidores Radarr, Sonarr e qBittorrent ficam aqui. Vamos adicionar o primeiro.';

  @override
  String get tourInstancesTitle => 'Instâncias';

  @override
  String get tourMockupBanner =>
      'Conteúdo de exemplo exibido durante o tour. Ele desaparece quando o tour termina.';

  @override
  String get tourMoviesLibraryBody =>
      'Todos os filmes gerenciados pelo Radarr aparecem aqui, com o status de monitoramento e de download.';

  @override
  String get tourMoviesLibraryTitle => 'Sua biblioteca de filmes';

  @override
  String get tourMoviesSearchBody =>
      'Encontre filmes na sua biblioteca pelo título.';

  @override
  String get tourMoviesSortBody =>
      'Reordene e filtre sua biblioteca para navegar mais rápido.';

  @override
  String get tourMoviesSortTitle => 'Ordenar e filtrar';

  @override
  String get tourNavigationBody =>
      'Alterne entre Filmes, Séries, Calendário, Atividade e Configurações a qualquer momento.';

  @override
  String get tourNavigationTitle => 'Navegação';

  @override
  String get tourSaveInstanceBody =>
      'Quando tudo estiver certo, salve para concluir a configuração. Você pode adicionar os outros servidores a qualquer momento em Configurações.';

  @override
  String get tourSaveInstanceTitle => 'Salvar instância';

  @override
  String get tourSeriesLibraryBody =>
      'Suas séries do Sonarr ficam aqui, com o número de temporadas e quanto de cada série já foi baixado.';

  @override
  String get tourSeriesLibraryTitle => 'Sua biblioteca de séries';

  @override
  String get tourSkip => 'Pular';

  @override
  String get tourTestConnectionBody =>
      'Verifica a URL e as credenciais antes de salvar.';

  @override
  String get tourTestConnectionTitle => 'Testar conexão';

  @override
  String get tourTorrentsBody =>
      'Os torrents do qBittorrent mostram velocidade, ratio e peers em tempo real, com ações para pausar, retomar e importar.';

  @override
  String get tourTorrentsTitle => 'Torrents';

  @override
  String get updateAndRestart => 'Atualizar e reiniciar';

  @override
  String get updateAvailableTitle => 'Nova versão disponível';

  @override
  String get updateChangelog => 'Changelog:';

  @override
  String get updateDownloadingTitle => 'Baixando atualização';

  @override
  String get updateInstallingTitle => 'Instalando...';

  @override
  String get updateLater => 'Mais tarde';

  @override
  String get updateNow => 'Atualizar agora';

  @override
  String get updatePreparing => 'Preparando a atualização...';

  @override
  String get updateRestartNotice =>
      'O aplicativo será fechado e reiniciado para concluir a atualização.';

  @override
  String get updateUnexpectedError => 'Ocorreu um erro inesperado.';

  @override
  String updateVersion(String version) {
    return 'Versão: $version';
  }

  @override
  String get versionHistoryEmptySubtitle =>
      'Não foi possível carregar o histórico de versões.';

  @override
  String get versionHistoryEmptyTitle => 'Nenhuma versão disponível';

  @override
  String get versionHistoryInstalled => 'Instalada';

  @override
  String versionHistoryLoadFailed(String error) {
    return 'Falha ao carregar o histórico de versões: $error';
  }

  @override
  String get versionHistoryLoading => 'Carregando histórico de versões...';

  @override
  String get versionHistoryTitle => 'Histórico de versões';

  @override
  String get watchingEmptySubtitle =>
      'As mídias que você pausar no Jellyfin aparecerão aqui.';

  @override
  String get watchingEmptyTitle => 'Nada em andamento';

  @override
  String get watchingLoading => 'Carregando continuar assistindo...';

  @override
  String get whatsNewNoNotes => 'Esta versão não inclui notas de lançamento.';

  @override
  String whatsNewTitle(String version) {
    return 'Novidades da v$version';
  }

  @override
  String get whatsNewViewAllVersions => 'Ver todas as versões';

  @override
  String get widgetsClosePoster => 'Fechar pôster';

  @override
  String widgetsCustomFormatScore(String score) {
    return 'Pontuação: $score';
  }

  @override
  String get widgetsDeleteFile => 'Excluir arquivo';

  @override
  String get widgetsEventAdditionalData => 'Dados adicionais';

  @override
  String get widgetsEventDate => 'Data';

  @override
  String get widgetsEventDetailsTitle => 'Detalhes do evento';

  @override
  String get widgetsEventSourceTitle => 'Título de origem';

  @override
  String get widgetsEventType => 'Tipo de evento';

  @override
  String get widgetsExtraFileMetadata => 'Metadados';

  @override
  String get widgetsExtraFileOther => 'Outro';

  @override
  String get widgetsExtraFileSubtitle => 'Legenda';

  @override
  String get widgetsFileAudioBitrate => 'Bitrate de áudio';

  @override
  String get widgetsFileAudioChannels => 'Canais de áudio';

  @override
  String get widgetsFileAudioCodec => 'Codec de áudio';

  @override
  String get widgetsFileAudioLanguages => 'Idiomas do áudio';

  @override
  String get widgetsFileAudioStreams => 'Faixas de áudio';

  @override
  String get widgetsFileBitDepth => 'Profundidade de bits';

  @override
  String get widgetsFileCustomFormats => 'Formatos personalizados';

  @override
  String get widgetsFileDateAdded => 'Data de adição';

  @override
  String get widgetsFileDetailsTitle => 'Detalhes do arquivo';

  @override
  String get widgetsFileDuration => 'Duração';

  @override
  String get widgetsFileDynamicRange => 'Faixa dinâmica';

  @override
  String get widgetsFileFrameRate => 'Taxa de quadros';

  @override
  String get widgetsFileGeneral => 'Geral';

  @override
  String get widgetsFileHdrType => 'Tipo de HDR';

  @override
  String get widgetsFileMediaInfo => 'Informações da mídia';

  @override
  String get widgetsFilePath => 'Caminho';

  @override
  String get widgetsFileResolution => 'Resolução';

  @override
  String get widgetsFileRevision => 'Revisão';

  @override
  String get widgetsFileScanType => 'Tipo de varredura';

  @override
  String get widgetsFileSource => 'Fonte';

  @override
  String get widgetsFileSubtitles => 'Legendas';

  @override
  String get widgetsFileVideoBitrate => 'Bitrate de vídeo';

  @override
  String get widgetsFileVideoCodec => 'Codec de vídeo';

  @override
  String get widgetsNoPreviousOnline =>
      'Nenhuma conexão online anterior registrada';

  @override
  String get widgetsNoTagsAvailable => 'Nenhuma tag disponível';

  @override
  String get widgetsNotifications => 'Notificações';

  @override
  String get widgetsOffline => 'Offline';

  @override
  String widgetsOfflineCacheCaveat(String lastOnline, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return '$lastOnline · As imagens em cache podem ter até $_temp0';
  }

  @override
  String get widgetsPlay => 'Reproduzir';

  @override
  String get widgetsQueueDownloadFailed => 'Falha no download';

  @override
  String get widgetsQueueDownloadPaused => 'Download pausado';

  @override
  String get widgetsQueueDownloadPending => 'Download pendente';

  @override
  String get widgetsQueueDownloadWarning => 'Aviso no download';

  @override
  String get widgetsQueueStatusUnknown => 'Status desconhecido';

  @override
  String widgetsSelectInstance(String type) {
    return 'Selecionar instância do $type';
  }

  @override
  String get widgetsSelectTags => 'Selecionar tags';

  @override
  String get widgetsSomeInstancesFailed =>
      'Algumas instâncias não puderam ser carregadas';

  @override
  String get widgetsSortBy => 'Ordenar por';

  @override
  String get widgetsSortOrder => 'Ordem';

  @override
  String widgetsTagButtonWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get widgetsUnknownFile => 'Arquivo desconhecido';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get activityTabHistory => 'Histórico';

  @override
  String get activityTabQueue => 'Fila';

  @override
  String get activityTabTorrents => 'Torrents';

  @override
  String get activityTabWatching => 'Assistindo';

  @override
  String get appInitErrorTitle => 'Erro de inicialização';

  @override
  String get appInitNotificationServicesFailed =>
      'Falha ao iniciar os serviços de notificação. Alguns recursos podem não funcionar corretamente.';

  @override
  String get appTitle => 'Arrmate';

  @override
  String get appleIntelligenceAssetsUnavailable =>
      'O modelo do Apple Intelligence ainda não está pronto. Tente novamente mais tarde.';

  @override
  String get appleIntelligenceBusy =>
      'O Apple Intelligence está ocupado. Tente novamente em instantes.';

  @override
  String get appleIntelligenceContextTooLong =>
      'A pergunta é longa demais para o Apple Intelligence. Tente uma mais curta.';

  @override
  String get appleIntelligenceDeclined =>
      'O Apple Intelligence se recusou a responder. Tente reformular a pergunta.';

  @override
  String get appleIntelligenceDeviceNotEligible =>
      'Este dispositivo não suporta o Apple Intelligence.';

  @override
  String get appleIntelligenceGenerationFailed =>
      'O Apple Intelligence não conseguiu gerar uma resposta.';

  @override
  String get appleIntelligenceModelNotReady =>
      'O modelo do Apple Intelligence ainda está sendo baixado. Tente novamente mais tarde.';

  @override
  String get appleIntelligenceNotEnabled =>
      'Ative o Apple Intelligence nos ajustes do sistema.';

  @override
  String get appleIntelligenceUnavailable =>
      'O Apple Intelligence não está disponível neste dispositivo.';

  @override
  String get appleIntelligenceUnsupportedLanguage =>
      'O Apple Intelligence não suporta este idioma neste dispositivo.';

  @override
  String get appleIntelligenceUnsupportedOs =>
      'O Apple Intelligence requer iOS 26 ou macOS 26.';

  @override
  String get assistantCloud => 'Cloud';

  @override
  String assistantDeleteModelContent(String model) {
    return 'Remover \"$model\" do seu dispositivo?';
  }

  @override
  String get assistantDeleteModelTitle => 'Excluir modelo';

  @override
  String get assistantDownloadModel => 'Baixar modelo';

  @override
  String get assistantDownloadingModel => 'Baixando modelo';

  @override
  String get assistantEmptyPrompt => 'Pergunte sobre o app';

  @override
  String get assistantInputHint => 'Pergunte sobre o Arrmate...';

  @override
  String get assistantInstalled => 'Instalado';

  @override
  String get assistantLinkNotOpened => 'Não foi possível abrir o link';

  @override
  String get assistantLocalModels => 'Modelos locais';

  @override
  String get assistantNoLocalModel => 'Nenhum modelo local selecionado';

  @override
  String get assistantOnDeviceModel => 'Modelo no dispositivo';

  @override
  String get assistantOnlineModel => 'Modelo online';

  @override
  String get assistantOnlyHttpsLinks => 'Somente links HTTPS são compatíveis';

  @override
  String assistantOpenLinkFailed(String error) {
    return 'Não foi possível abrir o link: $error';
  }

  @override
  String get assistantSelectModelFirst => 'Selecione um modelo primeiro';

  @override
  String get assistantStartingDownload => 'Iniciando download...';

  @override
  String get assistantSwitchModel => 'Trocar modelo';

  @override
  String get assistantTitle => 'Assistente';

  @override
  String get assistantUseCloud => 'Use o Cloud';

  @override
  String get assistantUseCloudOrLocal =>
      'Use o Cloud ou importe/baixe um modelo local';

  @override
  String backupAppVersion(String version) {
    return 'Versão do app: $version';
  }

  @override
  String get backupAutomaticNote =>
      'Os backups automáticos são feitos cerca de 30 segundos após você alterar instâncias ou configurações, enquanto estiver conectado. Algumas configurações (como a aba inicial) só são aplicadas por completo após reiniciar o app.';

  @override
  String backupCreated(String time) {
    return 'Criado: $time';
  }

  @override
  String get backupDriveDescription =>
      'Suas configurações, preferências e instâncias configuradas (incluindo as API Keys) ficam guardadas na pasta privada do app no seu Google Drive, invisível para outros apps.';

  @override
  String get backupDriveTitle => 'Backup no Google Drive';

  @override
  String get backupDriveUnavailableMessage =>
      'Esta versão foi compilada sem credenciais do Google. Peça ao desenvolvedor para compilar com a configuração do Google OAuth ou execute localmente com as flags --dart-define. Use o backup em arquivo local abaixo.';

  @override
  String get backupDriveUnavailableTitle =>
      'Backup no Google Drive indisponível';

  @override
  String get backupExportToFile => 'Exportar backup para arquivo';

  @override
  String get backupExportToFileSubtitle =>
      'Salvar uma cópia .json neste dispositivo';

  @override
  String backupExported(String fileName) {
    return 'Backup exportado para $fileName';
  }

  @override
  String backupFoundMessage(String time) {
    return 'Salvo em $time. Restaure-o para trazer as configurações e instâncias para este dispositivo. Os backups automáticos ficam pausados até você restaurar ou fazer um backup manual.';
  }

  @override
  String get backupFoundTitle => 'Backup encontrado no seu Google Drive';

  @override
  String backupInstanceCount(int count) {
    return 'Instâncias: $count';
  }

  @override
  String backupLastBackup(String time) {
    return 'Último backup: $time';
  }

  @override
  String get backupNever => 'nunca';

  @override
  String get backupNow => 'Fazer backup agora';

  @override
  String backupPlatform(String platform) {
    return 'Plataforma: $platform';
  }

  @override
  String get backupRestoreBackupMenu => 'Restaurar backup…';

  @override
  String get backupRestoreConfirmTitle => 'Restaurar backup?';

  @override
  String get backupRestoreFailed => 'Falha na restauração';

  @override
  String get backupRestoreFromFile => 'Restaurar de arquivo…';

  @override
  String get backupRestoreReplaceWarning =>
      'Isso substitui as configurações e instâncias atuais deste dispositivo.';

  @override
  String get backupRestored => 'Backup restaurado';

  @override
  String get backupSignInWithGoogle => 'Entrar com o Google';

  @override
  String get backupSignOut => 'Sair';

  @override
  String get backupTitle => 'Backup e restauração';

  @override
  String get calendarAnyInstance => 'Qualquer instância';

  @override
  String get calendarDataLoadFailed =>
      'Não foi possível carregar os dados do calendário.';

  @override
  String get calendarFilterByInstance => 'Filtrar por instância';

  @override
  String get calendarFilterByMediaType => 'Filtrar por tipo de mídia';

  @override
  String get calendarHideSpecials => 'Ocultar especiais';

  @override
  String get calendarInstanceAny => 'Instância: qualquer';

  @override
  String calendarInstanceNamed(String name) {
    return 'Instância: $name';
  }

  @override
  String get calendarLoadMore => 'Carregar mais';

  @override
  String get calendarLoading => 'Carregando calendário...';

  @override
  String get calendarNoMatchingEvents => 'Nenhum evento correspondente';

  @override
  String get calendarNoMatchingEventsHint =>
      'Ajuste os filtros do calendário para ver mais eventos.';

  @override
  String get calendarNoUpcomingEvents => 'Nenhum evento próximo';

  @override
  String get calendarNoUpcomingEventsHint =>
      'Volte mais tarde ou adicione conteúdo às suas bibliotecas.';

  @override
  String calendarOpenItemFailed(String error) {
    return 'Não foi possível abrir o item: $error';
  }

  @override
  String get calendarPremieres => 'Estreias';

  @override
  String get calendarToday => 'Hoje';

  @override
  String get calendarTomorrow => 'Amanhã';

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
  String coreGoogleSignInAccountLoadFailed(String status) {
    return 'Falha no login do Google: não foi possível carregar a conta (status $status).';
  }

  @override
  String get coreGoogleSignInBrowserFailed =>
      'Não foi possível abrir o navegador de login. Tente novamente.';

  @override
  String get coreGoogleSignInCancelled =>
      'O login no Google foi cancelado antes de terminar.';

  @override
  String get coreGoogleSignInConsentDenied =>
      'O login no Google foi cancelado: o consentimento foi negado.';

  @override
  String get coreGoogleSignInIncompleteToken =>
      'Falha no login do Google: a resposta do token veio incompleta.';

  @override
  String coreGoogleSignInNetworkError(String status) {
    return 'Falha no login do Google: erro de rede ou do servidor (status $status).';
  }

  @override
  String get coreGoogleSignInNoCode =>
      'Falha no login do Google: nenhum código de autorização foi retornado.';

  @override
  String get coreGoogleSignInNoEmail =>
      'Falha no login do Google: a conta não tem e-mail.';

  @override
  String coreGoogleSignInProviderError(String reason) {
    return 'Falha no login do Google: $reason';
  }

  @override
  String get coreGoogleSignInRedirectUnverified =>
      'Falha no login do Google: não foi possível verificar o redirecionamento.';

  @override
  String coreGoogleSignInServerStatus(String status) {
    return 'Falha no login do Google: o servidor retornou o status $status.';
  }

  @override
  String get coreGoogleSignInStatusUnavailable => 'indisponível';

  @override
  String get coreGoogleSignInTimedOut =>
      'O login no Google expirou. Tente novamente.';

  @override
  String get coreGoogleSignInUnavailableOnWeb =>
      'O login do Google não está disponível na web.';

  @override
  String get corePurgeNotificationTitle => 'Torrent removido';

  @override
  String corePurgeNotificationTitleSeason(int season) {
    return 'Torrent removido (temporada $season)';
  }

  @override
  String corePurgeSummaryMediaFiles(int count) {
    return 'Arquivos de mídia: $count';
  }

  @override
  String get corePurgeSummaryQbittorrentSkipped =>
      'qBittorrent ignorado — configure uma instância do qBittorrent.';

  @override
  String corePurgeSummaryQueueItems(int count) {
    return 'Itens da fila: $count';
  }

  @override
  String corePurgeSummaryTorrents(int count) {
    return 'Torrents: $count';
  }

  @override
  String corePurgeSummaryTorrentsWithCrossSeed(int count, int crossSeed) {
    return 'Torrents: $count (+$crossSeed cross-seed)';
  }

  @override
  String get coreUpdateArchiveMissingFiles =>
      'Faltam arquivos obrigatórios do aplicativo no arquivo da atualização.';

  @override
  String get coreUpdateArchiveTooLarge =>
      'O arquivo da atualização excede os limites de extração.';

  @override
  String get coreUpdateArchiveUnsafeLink =>
      'O arquivo da atualização contém um link simbólico inseguro.';

  @override
  String get coreUpdateArchiveUnsafePath =>
      'O arquivo da atualização contém um caminho inseguro.';

  @override
  String get coreUpdateArchiveWritesThroughLink =>
      'O arquivo da atualização grava através de um link simbólico.';

  @override
  String get coreUpdateCheckFailed =>
      'Não foi possível verificar se há atualizações. Tente novamente.';

  @override
  String get coreUpdateInstallerNotStarted =>
      'Não foi possível iniciar o instalador da atualização. O app não foi alterado.';

  @override
  String get coreUpdateLinuxRequiresAppImage =>
      'As atualizações automáticas no Linux exigem o AppImage. Baixe e execute primeiro a versão AppImage.';

  @override
  String get coreUpdateMacBundleRequired =>
      'Execute o pacote Arrmate.app instalado para atualizá-lo.';

  @override
  String get coreUpdateNotAppImage => 'A atualização não é um AppImage x64.';

  @override
  String coreUpdateOtaFailed(String status) {
    return 'Falha na atualização: $status';
  }

  @override
  String coreUpdatePrepareFailed(String tool) {
    return 'Não foi possível preparar o pacote de atualização ($tool).';
  }

  @override
  String get coreUpdateReadOnlyFolder =>
      'A pasta do aplicativo é somente leitura. Mova o Arrmate para uma pasta com permissão de escrita para o seu usuário e tente novamente.';

  @override
  String get coreUpdateUnverifiedPackage =>
      'A versão não contém um pacote verificado para esta plataforma.';

  @override
  String get coreUpdateVerificationFailed =>
      'A atualização falhou na verificação de tamanho ou SHA-256.';

  @override
  String get coreUpdateVersionMismatch =>
      'A versão do aplicativo baixado não corresponde à versão publicada.';

  @override
  String get coreUpdateWindowsIncomplete =>
      'Execute o Arrmate a partir da pasta completa da versão para Windows para atualizá-lo.';

  @override
  String diagnosticsCheckFailed(String error) {
    return 'Falhou · $error';
  }

  @override
  String diagnosticsCheckOk(int ms) {
    return 'OK · ${ms}ms';
  }

  @override
  String diagnosticsCheckOkWithVersion(int ms, String version) {
    return 'OK · ${ms}ms · v$version';
  }

  @override
  String get diagnosticsChecking => 'Verificando endpoints configurados...';

  @override
  String get diagnosticsEndpointActive => 'Endpoint ativo';

  @override
  String get diagnosticsEndpointAlternative => 'Endpoint alternativo';

  @override
  String get diagnosticsEndpointAlternativeActive =>
      'Endpoint alternativo · Ativo';

  @override
  String get diagnosticsEndpointConnectivity => 'Conectividade dos endpoints';

  @override
  String get diagnosticsEndpointPrimary => 'Endpoint principal';

  @override
  String get diagnosticsEndpointPrimaryActive => 'Endpoint principal · Ativo';

  @override
  String get diagnosticsEndpointsAvailable => 'Endpoints disponíveis';

  @override
  String get diagnosticsEndpointsUnavailable => 'Endpoints indisponíveis';

  @override
  String diagnosticsExportFailed(String error) {
    return 'Falha ao exportar o relatório: $error';
  }

  @override
  String get diagnosticsExportReport => 'Exportar relatório';

  @override
  String diagnosticsGenerated(String date) {
    return 'Gerado em $date';
  }

  @override
  String diagnosticsInterfaces(String interfaces) {
    return 'Interfaces: $interfaces';
  }

  @override
  String get diagnosticsNetworkAvailable => 'Rede disponível';

  @override
  String get diagnosticsNoInstances =>
      'Nenhuma instância do Radarr, Sonarr ou qBittorrent está configurada.';

  @override
  String get diagnosticsNoNetworkInterface => 'Nenhuma interface de rede';

  @override
  String get diagnosticsNoRecentRequests =>
      'Nenhuma requisição recente registrada.';

  @override
  String get diagnosticsPurposeBody =>
      'Testa a disponibilidade e a latência de cada endpoint configurado, mostra os rastros de requisições recentes e exporta um relatório sem dados sensíveis. Saúde mostra os alertas reportados pelo Radarr e Sonarr.';

  @override
  String get diagnosticsPurposeTitle => 'Solução de problemas de conexão';

  @override
  String get diagnosticsRecentRequests => 'Rastros de requisições recentes';

  @override
  String get diagnosticsRefreshing =>
      'Atualizando verificações dos endpoints...';

  @override
  String get diagnosticsRunAgain =>
      'Executar as verificações de conexão novamente';

  @override
  String diagnosticsRunFailed(String error) {
    return 'Falha ao executar o diagnóstico de conexão: $error';
  }

  @override
  String get diagnosticsSomeEndpointsUnavailable =>
      'Alguns endpoints indisponíveis';

  @override
  String get diagnosticsTitle => 'Diagnóstico de conexão';

  @override
  String get diagnosticsUnknownError => 'erro desconhecido';

  @override
  String get diagnosticsUnknownStatus => 'desconhecido';

  @override
  String get discoveryConfigureAddition => 'Configurar adição';

  @override
  String get discoveryHideAlreadyAdded => 'Ocultar já adicionados';

  @override
  String discoveryLoadFoldersFailed(String error) {
    return 'Erro ao carregar pastas: $error';
  }

  @override
  String discoveryLoadProfilesFailed(String error) {
    return 'Erro ao carregar perfis: $error';
  }

  @override
  String get discoveryNoOverview => 'Nenhuma sinopse disponível.';

  @override
  String get discoveryNoRating => 'Sem avaliação';

  @override
  String get discoveryNoResultsFound => 'Nenhum resultado encontrado';

  @override
  String discoveryRootFolderFreeSpace(String path, String free) {
    return '$path ($free GB livres)';
  }

  @override
  String discoveryRuntimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get discoverySearchPrompt =>
      'Busque por título, ID do provedor ou URL';

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
  String healthCheckCouldNotStart(String service) {
    return 'Não foi possível iniciar a verificação do $service';
  }

  @override
  String healthConnectionFailed(String service) {
    return 'Falha na conexão com o $service';
  }

  @override
  String get healthConnectionIssues => 'Problemas de conexão';

  @override
  String get healthLoadFailed => 'Falha ao carregar o status de saúde';

  @override
  String get healthLoadFailureSubtitle =>
      'Não foi possível carregar a saúde do servidor. Verifique a conexão e tente novamente.';

  @override
  String get healthNoInstancesSubtitle =>
      'Adicione uma instância do Radarr ou Sonarr para ver a saúde do servidor.';

  @override
  String get healthNoIssuesSubtitle =>
      'Os servidores conectados não reportaram alertas de saúde.';

  @override
  String get healthNoIssuesTitle => 'Nenhum problema no servidor';

  @override
  String get healthRunCheck => 'Executar verificação de saúde';

  @override
  String get healthRunFailureSubtitle =>
      'O status mais recente disponível do servidor é exibido abaixo.';

  @override
  String get healthServerWarnings => 'Alertas do servidor';

  @override
  String get healthTitle => 'Saúde do sistema';

  @override
  String healthWiki(String url) {
    return 'Wiki: $url';
  }

  @override
  String get historyAllEvents => 'Todos os eventos';

  @override
  String get historyAllInstances => 'Todas as instâncias';

  @override
  String get historyDetailDate => 'Data';

  @override
  String get historyDetailScore => 'Pontuação';

  @override
  String get historyEmpty => 'Nenhum evento no histórico';

  @override
  String get historyLoadFailed =>
      'Não foi possível carregar os dados do histórico.';

  @override
  String get historyLoadMore => 'Carregar mais';

  @override
  String get instanceAddBasicAuth => 'Adicionar Basic Auth';

  @override
  String get instanceAddHeader => 'Adicionar cabeçalho';

  @override
  String get instanceAdvancedSettings => 'Configurações avançadas';

  @override
  String get instanceAdvancedSettingsSubtitle =>
      'Cabeçalhos personalizados e autenticação';

  @override
  String get instanceAlternativeUrl => 'URL alternativa';

  @override
  String get instanceAlternativeUrlHelper =>
      'URL opcional usada fora da sua rede local';

  @override
  String get instanceAlternativeUrlSameAsPrimary =>
      'Deve ser diferente da URL principal';

  @override
  String get instanceApiKeyOrBasicAuthRequired =>
      'Informe uma API Key ou adicione Basic Auth abaixo';

  @override
  String get instanceApiKeySessionExpiredValidation =>
      'Adicione Basic Auth abaixo para entrar novamente ou informe uma API Key';

  @override
  String get instanceAuthCustomHeader => 'Cabeçalho personalizado';

  @override
  String get instanceAuthUsernamePassword => 'Usuário e senha';

  @override
  String get instanceBasicAuthBase64Note =>
      'As credenciais serão codificadas em Base64.';

  @override
  String get instanceBasicAuthTitle => 'Autenticação básica';

  @override
  String instanceDeleteFailed(String error) {
    return 'Falha ao excluir: $error';
  }

  @override
  String get instanceDeleteJellyfinWarning =>
      'O Arrmate também removerá a conexão do Jellyfin do Radarr/Sonarr, revogará a API Key do Arrmate que criou e sairá do Jellyfin. Esta ação não pode ser desfeita.';

  @override
  String get instanceDeleteTitle => 'Excluir instância?';

  @override
  String get instanceDeleteWarning => 'Esta ação não pode ser desfeita.';

  @override
  String get instanceEditTitle => 'Editar instância';

  @override
  String instanceErrorHttpStatus(String status) {
    return 'O servidor respondeu com HTTP $status.';
  }

  @override
  String get instanceErrorTimeout =>
      'O servidor demorou demais para responder. Tente novamente ou ative o Modo de instância lenta.';

  @override
  String get instanceErrorUnreachable =>
      'Servidor inacessível. Verifique a URL e sua rede.';

  @override
  String get instanceGoBack => 'Voltar';

  @override
  String get instanceHeaderName => 'Nome do cabeçalho';

  @override
  String get instanceHeaderValue => 'Valor do cabeçalho';

  @override
  String get instanceHideApiKey => 'Ocultar API Key';

  @override
  String get instanceJellyfinFallbackUser => 'um usuário do Jellyfin';

  @override
  String get instanceJellyfinHelperDefault =>
      'API Key (painel do Jellyfin → Avançado → Chaves de API). Deixe vazio se usar \"Adicionar Basic Auth\" abaixo para entrar com usuário e senha.';

  @override
  String get instanceJellyfinHelperSessionExpired =>
      'Sessão expirada — adicione Basic Auth abaixo para entrar novamente ou informe uma API Key';

  @override
  String instanceJellyfinHelperSignedIn(String user) {
    return 'Conectado como $user. Deixe vazio para manter a sessão, informe uma API Key para trocar ou adicione Basic Auth abaixo para entrar novamente.';
  }

  @override
  String get instanceJellyfinSessionExpiredBanner =>
      'Sua sessão do Jellyfin expirou. Adicione Basic Auth em Configurações avançadas com seu usuário e senha para entrar novamente.';

  @override
  String get instanceLibraryAutoUpdateSetupTitle =>
      'Configuração da atualização automática da biblioteca';

  @override
  String get instanceNameHint => 'ex.: Servidor de casa';

  @override
  String get instanceNameLabel => 'Nome';

  @override
  String get instanceNotFoundMessage =>
      'A instância solicitada não existe mais ou não pôde ser carregada.';

  @override
  String get instanceNotFoundTitle => 'Instância não encontrada';

  @override
  String get instancePassword => 'Senha';

  @override
  String get instanceQbittorrentApiKeyHelper =>
      'Token Bearer (qBittorrent ≥ v5.2.0). Deixe vazio se usar \"Adicionar Basic Auth\" abaixo para versões mais antigas.';

  @override
  String instanceRemovedCleanupFailed(String failures) {
    return 'Instância removida, mas parte da limpeza falhou:\n$failures';
  }

  @override
  String get instanceRequired => 'Obrigatório';

  @override
  String get instanceSave => 'Salvar instância';

  @override
  String get instanceSetUpLibraryAutoUpdate =>
      'Configurar atualização automática da biblioteca';

  @override
  String instanceSetupFailed(String error) {
    return 'Falha na configuração: $error';
  }

  @override
  String get instanceShowApiKey => 'Mostrar API Key';

  @override
  String get instanceSlowMode => 'Modo de instância lenta';

  @override
  String get instanceSlowModeSubtitle =>
      'Aumenta os tempos limite para conexões lentas';

  @override
  String get instanceTestConnection => 'Testar conexão';

  @override
  String instanceTestSuccessArr(String version, String name, int count) {
    return 'Conexão bem-sucedida!\nVersão: $version\nInstância: $name\nTags: $count disponíveis';
  }

  @override
  String instanceTestSuccessQbittorrent(String auth, int count) {
    return 'Conexão bem-sucedida!\nAutenticação: $auth\nTorrents: $count';
  }

  @override
  String get instanceUrlHelper => 'Inclua http:// ou https:// e a porta';

  @override
  String get instanceUrlInvalid => 'Deve ser uma URL HTTP ou HTTPS válida';

  @override
  String get instanceUsername => 'Usuário';

  @override
  String instanceValidationFailed(String error) {
    return 'Falha na validação: $error';
  }

  @override
  String get jellyfinSetupApiKeyRequired =>
      'API Key do Jellyfin necessária para atualizar a biblioteca automaticamente: informe uma API Key no campo ou entre com uma conta de administrador (Basic Auth)';

  @override
  String get jellyfinSetupNoConnection =>
      'Nenhuma conexão com o Jellyfin configurada no Arrmate.';

  @override
  String jellyfinSetupNotArrInstance(String name) {
    return '$name não é uma instância do Radarr ou do Sonarr.';
  }

  @override
  String jellyfinSetupRemoveConnectorFailed(String name, String error) {
    return 'Não foi possível remover a conexão do Jellyfin de $name: $error';
  }

  @override
  String jellyfinSetupRevokeKeyFailed(String error) {
    return 'Não foi possível revogar a API Key do Arrmate no Jellyfin: $error';
  }

  @override
  String jellyfinSetupSignOutFailed(String error) {
    return 'Não foi possível sair do Jellyfin: $error';
  }

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
  String get logsAllCopied =>
      'Todos os logs copiados para a área de transferência';

  @override
  String get logsAppLogsCleared => 'Logs do app limpos';

  @override
  String get logsClearAppLogs => 'Limpar logs do app';

  @override
  String get logsCopyAllVisible => 'Copiar todos os logs visíveis';

  @override
  String get logsDetailException => 'Exceção/Erro:';

  @override
  String get logsDetailLevel => 'Nível';

  @override
  String get logsDetailLogger => 'Logger';

  @override
  String get logsDetailMessage => 'Mensagem:';

  @override
  String get logsDetailTime => 'Hora';

  @override
  String get logsDetailTitle => 'Detalhes do log';

  @override
  String get logsLevelDebug => 'Debug';

  @override
  String get logsLevelInfo => 'Info';

  @override
  String get logsLevelWarn => 'Aviso';

  @override
  String get logsLogCopied => 'Log copiado';

  @override
  String get logsNoAppLogsMatchingFilter =>
      'Nenhum log do app encontrado para o filtro';

  @override
  String get logsNoLogsMatchingFilter => 'Nenhum log encontrado para o filtro';

  @override
  String get logsSource => 'Origem dos logs';

  @override
  String get logsTabApp => 'Logs do app';

  @override
  String get logsTabArr => 'Logs ARR';

  @override
  String get logsTitle => 'Logs do sistema';

  @override
  String get manualImportEmptySubtitle =>
      'Não há arquivos disponíveis para importação manual.';

  @override
  String get manualImportEmptyTitle => 'Nenhum arquivo importável';

  @override
  String manualImportFailed(String error) {
    return 'Falha ao importar: $error';
  }

  @override
  String manualImportIssueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count com problemas',
    );
    return '$_temp0';
  }

  @override
  String get manualImportLoadFailed =>
      'Falha ao carregar os arquivos importáveis';

  @override
  String get manualImportLoading => 'Carregando arquivos importáveis...';

  @override
  String get manualImportNoFilesSelected => 'Nenhum arquivo selecionado';

  @override
  String manualImportSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos selecionados',
      one: '1 arquivo selecionado',
    );
    return '$_temp0';
  }

  @override
  String manualImportSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos importados com sucesso',
      one: '1 arquivo importado com sucesso',
    );
    return '$_temp0';
  }

  @override
  String get manualImportTitle => 'Importação manual';

  @override
  String manualImportValidCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count válidos',
      one: '1 válido',
    );
    return '$_temp0';
  }

  @override
  String moviesAddFailed(String error) {
    return 'Erro ao adicionar o filme: $error';
  }

  @override
  String get moviesAddMissingSelection =>
      'Selecione um filme, um perfil de qualidade e uma pasta raiz';

  @override
  String get moviesAddMovieButton => 'Adicionar filme';

  @override
  String get moviesAddMovieTitle => 'Adicionar filme';

  @override
  String get moviesAddedSuccessfully => 'Filme adicionado com sucesso';

  @override
  String get moviesAllFolders => 'Todas as pastas';

  @override
  String get moviesAlsoDeleteFiles => 'Excluir também os arquivos do disco';

  @override
  String moviesDeleteFailed(String error) {
    return 'Falha ao excluir: $error';
  }

  @override
  String get moviesDeleteFileConfirm =>
      'Tem certeza de que deseja excluir este arquivo? Esta ação não pode ser desfeita.';

  @override
  String get moviesDeleteFileTitle => 'Excluir arquivo';

  @override
  String moviesDeleteFilesConfirm(String title) {
    return 'Excluir todos os arquivos de \"$title\"? Isso remove o arquivo do filme do disco; o filme continua no Radarr.';
  }

  @override
  String moviesDeleteFilesFailed(String error) {
    return 'Falha ao excluir arquivos: $error';
  }

  @override
  String moviesDeleteMovieConfirm(String title) {
    return 'Tem certeza de que deseja excluir \"$title\"?';
  }

  @override
  String get moviesDeleteMovieTitle => 'Excluir filme';

  @override
  String get moviesDeleted => 'Filme excluído';

  @override
  String moviesDeletedFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos excluídos',
      one: '1 arquivo excluído',
    );
    return '$_temp0';
  }

  @override
  String get moviesDeletedWithFiles => 'Filme e arquivos excluídos';

  @override
  String get moviesEditTitle => 'Editar filme';

  @override
  String get moviesEmptyFilteredSubtitle =>
      'Tente limpar ou ajustar sua busca ou seus filtros.';

  @override
  String get moviesEmptySubtitle =>
      'Adicione filmes à sua biblioteca do Radarr para vê-los aqui.';

  @override
  String get moviesEmptyTitle => 'Nenhum filme encontrado';

  @override
  String get moviesFileDeleted => 'Arquivo excluído';

  @override
  String get moviesFilesSection => 'Arquivos';

  @override
  String get moviesHistorySection => 'Histórico';

  @override
  String get moviesInfoPath => 'Caminho';

  @override
  String get moviesInfoStudio => 'Estúdio';

  @override
  String get moviesLoadFilesFailed => 'Falha ao carregar os arquivos';

  @override
  String get moviesLoadHistoryFailed => 'Falha ao carregar o histórico';

  @override
  String get moviesLoading => 'Carregando filmes...';

  @override
  String get moviesLoadingDetails => 'Carregando detalhes...';

  @override
  String get moviesMinimumAvailability => 'Disponibilidade mínima';

  @override
  String moviesMoveFilesConfirm(String path) {
    return 'Deseja mover os arquivos para \"$path\"?';
  }

  @override
  String get moviesMoveFilesTitle => 'Mover arquivos?';

  @override
  String get moviesNoFilesToDelete => 'Nenhum arquivo para excluir';

  @override
  String get moviesNoHistoryEvents => 'Nenhum evento no histórico';

  @override
  String get moviesNoMediaFiles => 'Nenhum arquivo de mídia';

  @override
  String moviesOpenLinkFailed(String error) {
    return 'Não foi possível abrir o link: $error';
  }

  @override
  String get moviesOverview => 'Sinopse';

  @override
  String get moviesPreventReAdd =>
      'Impedir que este filme seja adicionado novamente';

  @override
  String get moviesPreviewTitle => 'Prévia do filme';

  @override
  String moviesPurgeConfirm(String title) {
    return 'Isso removerá permanentemente \"$title\" do Radarr, excluirá seus arquivos de mídia e excluirá todos os torrents de origem (incluindo duplicatas Cross-seed) do qBittorrent. Libera o espaço em disco usado por dados com hardlink.';
  }

  @override
  String moviesPurgeFailed(String error) {
    return 'Falha ao purgar: $error';
  }

  @override
  String moviesPurgePreviewFailed(String error) {
    return 'Falha ao pré-visualizar: $error';
  }

  @override
  String get moviesPurgeTitle => 'Purgar filme';

  @override
  String get moviesPurged => 'Filme purgado.';

  @override
  String get moviesRefreshAndScan => 'Atualizar e escanear';

  @override
  String get moviesRefreshAndScanTriggered =>
      'Atualização e escaneamento iniciados';

  @override
  String get moviesRootFolderHelper =>
      'Alterar isso moverá os arquivos, se confirmado';

  @override
  String get moviesSearchHint => 'Buscar filmes...';

  @override
  String moviesSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionados',
      one: '1 selecionado',
    );
    return '$_temp0';
  }

  @override
  String get moviesSortAndFilter => 'Ordenar e filtrar';

  @override
  String get moviesSwitchToGrid => 'Alternar para grade';

  @override
  String get moviesSwitchToList => 'Alternar para lista';

  @override
  String get moviesTrailer => 'Trailer';

  @override
  String moviesUpdateFailed(String error) {
    return 'Erro ao atualizar o filme: $error';
  }

  @override
  String get moviesUpdated => 'Filme atualizado';

  @override
  String moviesViewPoster(String title) {
    return 'Ver pôster de $title';
  }

  @override
  String get notificationSettingsArrUpdate => 'Atualização da instância *arr';

  @override
  String get notificationSettingsArrUpdateSubtitle =>
      'Quando o servidor Radarr/Sonarr é atualizado';

  @override
  String get notificationSettingsAutoConfigure =>
      'Configurar instâncias *arr automaticamente';

  @override
  String get notificationSettingsAutoConfiguring =>
      'Configurando notificações automaticamente...';

  @override
  String notificationSettingsConfiguredCount(int success, int total) {
    return '$success/$total instâncias configuradas.';
  }

  @override
  String get notificationSettingsConnected => 'Conectado ao ntfy.sh';

  @override
  String get notificationSettingsCopyTopic => 'Copiar tópico';

  @override
  String get notificationSettingsDisconnected => 'Desconectado';

  @override
  String get notificationSettingsDownloads => 'Downloads';

  @override
  String get notificationSettingsEnable => 'Ativar notificações';

  @override
  String get notificationSettingsFailure => 'Notificar em falhas';

  @override
  String get notificationSettingsFailureSubtitle =>
      'Quando a importação de um download falha';

  @override
  String get notificationSettingsFileDeleted => 'Arquivo excluído';

  @override
  String get notificationSettingsFileDeletedSubtitle =>
      'Quando um arquivo de mídia é excluído';

  @override
  String get notificationSettingsGrab => 'Notificar ao capturar';

  @override
  String get notificationSettingsGrabSubtitle =>
      'Quando um release é enviado ao cliente de download';

  @override
  String get notificationSettingsHealthIssues => 'Problemas de saúde';

  @override
  String get notificationSettingsHealthIssuesSubtitle =>
      'Quando problemas de saúde do sistema são detectados';

  @override
  String get notificationSettingsHealthRestored => 'Saúde restaurada';

  @override
  String get notificationSettingsHealthRestoredSubtitle =>
      'Quando um problema de saúde é resolvido';

  @override
  String get notificationSettingsImport => 'Notificar ao importar';

  @override
  String get notificationSettingsImportSubtitle =>
      'Quando um arquivo é importado com sucesso';

  @override
  String get notificationSettingsInAppBody =>
      'As notificações chegam em tempo real enquanto o app está aberto. Ao fechar o app, as novas notificações serão buscadas na próxima vez que você abri-lo.';

  @override
  String get notificationSettingsInAppTitle => 'Notificações no app';

  @override
  String get notificationSettingsIncludeWarnings => 'Incluir alertas';

  @override
  String get notificationSettingsIncludeWarningsSubtitle =>
      'Notificar também alertas de saúde';

  @override
  String get notificationSettingsManualInteraction => 'Interação manual';

  @override
  String get notificationSettingsManualInteractionSubtitle =>
      'Quando uma intervenção manual é necessária';

  @override
  String get notificationSettingsManualSetup => 'OU CONFIGURAÇÃO MANUAL';

  @override
  String get notificationSettingsManualStep1 => '1. Vá em Settings > Connect';

  @override
  String get notificationSettingsManualStep2 =>
      '2. Adicione uma nova conexão > ntfy';

  @override
  String get notificationSettingsManualStep3 => '3. Configure:';

  @override
  String get notificationSettingsMediaAdded => 'Filme/série adicionado';

  @override
  String get notificationSettingsMediaAddedSubtitle =>
      'Quando um filme ou série é adicionado';

  @override
  String get notificationSettingsMediaDeleted => 'Filme/série excluído';

  @override
  String get notificationSettingsMediaDeletedSubtitle =>
      'Quando um filme ou série é excluído';

  @override
  String get notificationSettingsMediaUpdates => 'Atualizações de mídia';

  @override
  String get notificationSettingsNtfyDocs => 'Documentação do ntfy';

  @override
  String get notificationSettingsServerUrl => 'URL do servidor';

  @override
  String get notificationSettingsSetupInArr => 'Configuração no Radarr/Sonarr';

  @override
  String get notificationSettingsSetupResults => 'Resultados da configuração';

  @override
  String get notificationSettingsSetupSubtitle =>
      'Toque para gerar seu tópico exclusivo';

  @override
  String get notificationSettingsSetupTitle => 'Configurar notificações';

  @override
  String get notificationSettingsTopic => 'Tópico';

  @override
  String get notificationSettingsTopicCopied =>
      'Tópico copiado para a área de transferência';

  @override
  String notificationSettingsUnexpectedError(String error) {
    return 'Erro inesperado: $error';
  }

  @override
  String get notificationSettingsYourTopic => 'Seu tópico';

  @override
  String notificationSetupConfigured(String name) {
    return '$name configurado com sucesso.';
  }

  @override
  String notificationSetupFailed(String name, String error) {
    return 'Falha ao configurar $name: $error';
  }

  @override
  String get notificationSetupNoTopic =>
      'Nenhum tópico do ntfy configurado no Arrmate.';

  @override
  String notificationSetupUpdated(String name) {
    return '$name atualizado com sucesso.';
  }

  @override
  String get notificationsAllCleared => 'Todas as notificações foram removidas';

  @override
  String get notificationsAllMarkedRead =>
      'Todas as notificações foram marcadas como lidas';

  @override
  String get notificationsClearAll => 'Limpar tudo';

  @override
  String get notificationsClearAllConfirm =>
      'Isso removerá todas as notificações. Esta ação não pode ser desfeita.';

  @override
  String get notificationsClearAllTitle => 'Limpar todas as notificações?';

  @override
  String get notificationsDismissed => 'Notificação descartada';

  @override
  String get notificationsEmptySubtitle =>
      'Quando você receber notificações do Radarr ou do Sonarr, elas aparecerão aqui.';

  @override
  String get notificationsEmptyTitle => 'Nenhuma notificação';

  @override
  String get notificationsMarkAllRead => 'Marcar todas como lidas';

  @override
  String get notificationsNewBadge => 'NOVA';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String get playbackLoadMovieFileFailed =>
      'Não foi possível carregar o arquivo do filme';

  @override
  String get playbackNoEpisodeFile =>
      'Nenhum arquivo reproduzível encontrado para este episódio';

  @override
  String get playbackNoJellyfin => 'Nenhum servidor Jellyfin configurado';

  @override
  String get playbackNoMovieFile =>
      'Nenhum arquivo reproduzível encontrado para este filme';

  @override
  String get playbackNotFound =>
      'Não foi possível encontrar esta mídia no Jellyfin';

  @override
  String get playbackSearchingLibrary => 'Buscando na biblioteca do Jellyfin…';

  @override
  String get playbackSessionExpired =>
      'Sua sessão do Jellyfin expirou. Entre novamente.';

  @override
  String get playbackSignIn => 'Entrar';

  @override
  String playbackStartFailed(String error) {
    return 'Não foi possível iniciar a reprodução: $error';
  }

  @override
  String playbackTrackLabel(int index) {
    return 'Faixa $index';
  }

  @override
  String get playerAudio => 'Áudio';

  @override
  String get playerBack => 'Voltar';

  @override
  String get playerExternalOpenFailed =>
      'Não foi possível abrir um player externo';

  @override
  String get playerExternalUnavailable =>
      'Abrir esta mídia em um player externo não está disponível na configuração atual do servidor.';

  @override
  String get playerNoMediaRequested =>
      'Nenhuma mídia foi solicitada para reprodução.';

  @override
  String get playerQualityDataSaver => 'Economia de dados';

  @override
  String get playerQualityOriginal => 'Original';

  @override
  String playerQualityTooltip(String quality) {
    return 'Qualidade: $quality';
  }

  @override
  String get playerStartFailed =>
      'Não foi possível iniciar a reprodução. Verifique sua conexão e tente novamente.';

  @override
  String get playerSubtitleExternal => 'Externa';

  @override
  String get playerSubtitlesDisabled => 'Desativadas';

  @override
  String get playerTitle => 'Player';

  @override
  String get playerUnexpectedFailure => 'A reprodução falhou inesperadamente.';

  @override
  String get playerUnsupportedOnWeb =>
      'A reprodução no app ainda não é compatível com a web';

  @override
  String get providerAssistantDeleteFailed => 'Falha ao excluir o modelo.';

  @override
  String providerAssistantDownloadFailed(String error) {
    return 'Falha ao baixar o modelo: $error';
  }

  @override
  String get providerAssistantEnableOnlineFailed =>
      'Falha ao ativar o modelo online.';

  @override
  String get providerAssistantGenerateFailed => 'Falha ao gerar uma resposta.';

  @override
  String get providerAssistantImportFailed => 'Falha ao importar o modelo.';

  @override
  String get providerAssistantInitFailed =>
      'Falha ao inicializar os recursos do assistente.';

  @override
  String get providerAssistantLoadModelFailed =>
      'Falha ao carregar o modelo selecionado.';

  @override
  String get providerAssistantModelNotFound => 'Modelo não encontrado.';

  @override
  String get providerAssistantNoToolCalling =>
      'Este modelo não suporta tool-calling. Use um modelo Gemma.';

  @override
  String get providerAssistantRefreshModelsFailed =>
      'Falha ao atualizar os modelos instalados.';

  @override
  String get providerAssistantSelectModelFirst =>
      'Selecione um modelo antes de conversar.';

  @override
  String get providerBackupCompleted => 'Backup concluído.';

  @override
  String get providerBackupCorrupt =>
      'O arquivo de backup está corrompido ou é de uma versão não suportada.';

  @override
  String providerBackupExportFailed(String error) {
    return 'Falha ao exportar o backup: $error';
  }

  @override
  String get providerBackupExported => 'Backup exportado para arquivo.';

  @override
  String providerBackupFailed(String error) {
    return 'Falha no backup: $error';
  }

  @override
  String providerBackupLoadFailed(String error) {
    return 'Não foi possível carregar o backup: $error';
  }

  @override
  String get providerBackupNotFound =>
      'Nenhum backup encontrado no seu Google Drive.';

  @override
  String providerBackupReadFileFailed(String error) {
    return 'Não foi possível ler o arquivo de backup: $error';
  }

  @override
  String providerBackupRestoreFailed(String error) {
    return 'Falha na restauração: $error';
  }

  @override
  String providerBackupRestored(int settingsCount, int instanceCount) {
    return '$settingsCount configurações e $instanceCount instâncias restauradas.';
  }

  @override
  String get providerBackupSessionExpired =>
      'A sessão do Google expirou. Entre novamente.';

  @override
  String get providerBackupSignInFailed =>
      'Falha ao entrar. Verifique sua conexão e tente novamente.';

  @override
  String get providerBackupSignedOut => 'Entre com sua conta Google primeiro.';

  @override
  String get providerBackupUnknownError => 'erro desconhecido';

  @override
  String providerInstanceTypeMismatch(String expected, String actual) {
    return 'Esperava $expected, mas conectou a $actual';
  }

  @override
  String get purgeCrossSeedFoundContent =>
      'Foi encontrado um torrent com o mesmo nome de release. Excluí-lo também?';

  @override
  String get purgeCrossSeedFoundTitle => 'Torrent cross-seed encontrado';

  @override
  String get purgeDeleteAll => 'Excluir tudo';

  @override
  String get purgeDeleteAnyway => 'Excluir mesmo assim';

  @override
  String get purgeDeleteTorrent => 'Excluir torrent';

  @override
  String get purgeHash => 'Hash';

  @override
  String get purgeKeepSeeding => 'Continuar semeando';

  @override
  String get purgeKeepTorrent => 'Manter torrent';

  @override
  String get purgeNoTags => 'Sem tags';

  @override
  String get purgeSavePath => 'Caminho de salvamento';

  @override
  String purgeSeededFor(String duration) {
    return 'Semeado por $duration';
  }

  @override
  String get purgeTitleRemovedEitherWay =>
      'De qualquer forma, o título será removido da biblioteca e seus arquivos serão excluídos.';

  @override
  String purgeTorrentBelowMinimum(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return 'Este torrent semeou por menos que o mínimo de $_temp0:';
  }

  @override
  String get purgeTorrentStillSeeding => 'Torrent ainda semeando';

  @override
  String purgeTorrentsBelowMinimum(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Os $count torrents a seguir semearam',
      one: 'O torrent a seguir semeou',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return '$_temp0 por menos que o mínimo de $_temp1:';
  }

  @override
  String get purgeTorrentsStillSeeding => 'Torrents ainda semeando';

  @override
  String get qualityProfilesEmpty =>
      'Nenhum perfil encontrado ou instância não conectada';

  @override
  String qualityProfilesId(String id) {
    return 'ID: $id';
  }

  @override
  String get qualityProfilesRadarr => 'Perfis do Radarr';

  @override
  String get qualityProfilesSonarr => 'Perfis do Sonarr';

  @override
  String get qualityProfilesTitle => 'Perfis de qualidade';

  @override
  String get queueAddToBlocklist => 'Adicionar à lista de bloqueio';

  @override
  String get queueAddToBlocklistSubtitle =>
      'Impedir que este lançamento seja capturado novamente';

  @override
  String get queueAnyClient => 'Qualquer cliente';

  @override
  String get queueAnyInstance => 'Qualquer instância';

  @override
  String get queueAnyProtocol => 'Qualquer protocolo';

  @override
  String get queueAscending => 'Crescente';

  @override
  String get queueCustomFormatScore => 'Pontuação de formato personalizado';

  @override
  String get queueCustomFormats => 'Formatos personalizados';

  @override
  String get queueDescending => 'Decrescente';

  @override
  String get queueDetailPath => 'Caminho';

  @override
  String get queueDirection => 'Direção';

  @override
  String get queueEmptySubtitle => 'Nenhum download ativo no momento.';

  @override
  String get queueEmptyTitle => 'A fila está vazia';

  @override
  String queueEtaDays(int count) {
    return '${count}d';
  }

  @override
  String get queueEtaDone => 'Concluído';

  @override
  String queueEtaHours(int count) {
    return '${count}h';
  }

  @override
  String get queueEtaLessThanMinute => '<1min';

  @override
  String queueEtaMinutes(int count) {
    return '${count}min';
  }

  @override
  String get queueFilterSection => 'Filtro';

  @override
  String get queueGroupedTasks => 'Tarefas agrupadas';

  @override
  String get queueInformation => 'Informações';

  @override
  String get queueInstance => 'Instância';

  @override
  String get queueItemRemoved => 'Item removido da fila';

  @override
  String get queueLoadFailed => 'Não foi possível carregar os dados da fila.';

  @override
  String get queueLoading => 'Carregando fila...';

  @override
  String get queueManualImportDescription =>
      'Este download requer intervenção manual. Selecione quais arquivos importar.';

  @override
  String get queueManualImportRequired => 'Importação manual necessária';

  @override
  String get queueNoMatchSubtitle => 'Ajuste ou redefina os filtros da fila.';

  @override
  String get queueNoMatchTitle => 'Nenhuma tarefa encontrada';

  @override
  String get queueOpenDetails => 'Abrir detalhes';

  @override
  String get queueOpenMovie => 'Abrir filme';

  @override
  String get queueOpenSeries => 'Abrir série';

  @override
  String get queueOptions => 'Opções da fila';

  @override
  String queueProblemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count problemas)',
      one: '(1 problema)',
    );
    return '$_temp0';
  }

  @override
  String get queueProblemsOnly => 'Somente problemas';

  @override
  String get queueProblemsOnlySubtitle =>
      'Mostrar tarefas que precisam de atenção ou importação manual';

  @override
  String get queueRemovalOptions => 'Opções de remoção';

  @override
  String get queueRemoveFromClient => 'Remover do cliente de download';

  @override
  String get queueRemoveFromClientSubtitle => 'Excluir o download do cliente';

  @override
  String get queueRemoveFromQueue => 'Remover da fila';

  @override
  String get queueSearchReplacement => 'Buscar substituto';

  @override
  String get queueSearchReplacementSubtitle =>
      'Buscar automaticamente outro lançamento';

  @override
  String queueSizeLeft(String size) {
    return '$size restantes';
  }

  @override
  String queueTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarefas',
      one: '1 tarefa',
    );
    return '$_temp0';
  }

  @override
  String queueTimeRemainingDaysHours(int days, int hours) {
    return '${days}d ${hours}h restantes';
  }

  @override
  String queueTimeRemainingHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}min restantes';
  }

  @override
  String get queueTimeRemainingLessThanMinute => 'Menos de um minuto';

  @override
  String queueTimeRemainingMinutes(int minutes) {
    return '${minutes}min restantes';
  }

  @override
  String get queueUnableToImport => 'Não foi possível importar automaticamente';

  @override
  String get queueUnknownError => 'Erro desconhecido';

  @override
  String get releasesAge => 'Idade';

  @override
  String releasesAgeDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String releasesAgeShort(int days) {
    return '${days}d';
  }

  @override
  String get releasesApproval => 'Aprovação';

  @override
  String get releasesApproved => 'Aprovada';

  @override
  String get releasesClearSearch => 'Limpar busca';

  @override
  String get releasesCustomFormat => 'Formato personalizado';

  @override
  String get releasesCustomFormatScore => 'Pontuação de formato personalizado';

  @override
  String get releasesCustomFormats => 'Formatos personalizados';

  @override
  String get releasesDetailsTitle => 'Detalhes da release';

  @override
  String get releasesDownload => 'Baixar';

  @override
  String get releasesDownloadRelease => 'Baixar release';

  @override
  String get releasesDownloadTitle => 'Baixar release';

  @override
  String get releasesEpisodeOrMovie => 'Episódio ou filme';

  @override
  String get releasesEpisodes => 'Episódios';

  @override
  String get releasesExcludeFreeleech => 'Excluir freeleech';

  @override
  String get releasesFilterTooltip => 'Filtrar releases';

  @override
  String get releasesFiltersSubtitle => 'Combine quantos filtros quiser';

  @override
  String get releasesFiltersTitle => 'Filtros de releases';

  @override
  String get releasesFreeleech => 'Freeleech';

  @override
  String get releasesFreeleechOnly => 'Somente freeleech';

  @override
  String releasesGrabConfirm(String title) {
    return 'Tem certeza de que deseja capturar \"$title\"?';
  }

  @override
  String releasesGrabError(String error) {
    return 'Erro ao capturar a release: $error';
  }

  @override
  String get releasesGrabSuccess => 'Release capturada com sucesso';

  @override
  String get releasesIndexerFlags => 'Flags do indexador';

  @override
  String get releasesLanguages => 'Idiomas';

  @override
  String get releasesMappedEpisodes => 'Episódios mapeados';

  @override
  String get releasesNoMatch =>
      'Nenhuma release corresponde aos filtros atuais';

  @override
  String get releasesNoneFound => 'Nenhuma release encontrada';

  @override
  String get releasesOriginalLanguageOnly => 'Somente idioma original';

  @override
  String get releasesQualityWeight => 'Peso da qualidade';

  @override
  String get releasesRejected => 'Rejeitada';

  @override
  String get releasesRejectedTooltip => 'Release rejeitada';

  @override
  String get releasesRejectionReasons => 'Motivos da rejeição';

  @override
  String get releasesReleaseRejected => 'Release rejeitada';

  @override
  String get releasesReleaseType => 'Tipo de release';

  @override
  String get releasesReleaseWeight => 'Peso da release';

  @override
  String get releasesRememberFilters => 'Lembrar filtros';

  @override
  String get releasesRememberFiltersSubtitle =>
      'Manter esta configuração para buscas futuras';

  @override
  String get releasesRequestedEpisode => 'Episódio solicitado';

  @override
  String releasesResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String releasesResultCountHidden(int count, int hidden) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hidden,
      locale: localeName,
      other: '$hidden ocultos',
      one: '1 oculto',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get releasesSearchHint => 'Buscar releases';

  @override
  String get releasesSeasonPack => 'Pacote da temporada';

  @override
  String get releasesSeasonPacks => 'Pacotes de temporada';

  @override
  String get releasesSeeders => 'Seeders';

  @override
  String get releasesSeedsPeers => 'Seeds / peers';

  @override
  String get releasesSendingTooltip =>
      'Enviando release para o cliente de download';

  @override
  String seriesAddFailed(String error) {
    return 'Erro ao adicionar a série: $error';
  }

  @override
  String get seriesAddMissingSelection =>
      'Selecione uma série, um perfil de qualidade e uma pasta raiz';

  @override
  String get seriesAddSeries => 'Adicionar série';

  @override
  String get seriesAddSeriesTitle => 'Adicionar série';

  @override
  String get seriesAddedSuccessfully => 'Série adicionada com sucesso';

  @override
  String get seriesAirDate => 'Data de exibição';

  @override
  String get seriesAllFolders => 'Todas as pastas';

  @override
  String get seriesAllSeasonsMonitored => 'Todas as temporadas monitoradas';

  @override
  String get seriesAllSeasonsUnmonitored =>
      'Todas as temporadas desmonitoradas';

  @override
  String get seriesAlsoDeleteFiles => 'Excluir também os arquivos do disco';

  @override
  String get seriesAndFilesDeleted => 'Série e arquivos excluídos';

  @override
  String get seriesConfigureAddition => 'Configurar adição';

  @override
  String seriesDeleteFailed(String error) {
    return 'Falha ao excluir: $error';
  }

  @override
  String get seriesDeleteFile => 'Excluir arquivo';

  @override
  String get seriesDeleteFileConfirm =>
      'Tem certeza de que deseja excluir este arquivo? Esta ação não pode ser desfeita.';

  @override
  String seriesDeleteFilesConfirm(String title) {
    return 'Excluir todos os arquivos de \"$title\"? Isso remove do disco todos os arquivos de episódio; a série continua no Sonarr.';
  }

  @override
  String seriesDeleteFilesFailed(String error) {
    return 'Falha ao excluir arquivos: $error';
  }

  @override
  String seriesDeleteFilesForSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir arquivos de $count temporadas',
      one: 'Excluir arquivos de 1 temporada',
    );
    return '$_temp0';
  }

  @override
  String get seriesDeleteSeasonFiles => 'Excluir arquivos da temporada';

  @override
  String seriesDeleteSeasonFilesConfirm(String title, int season) {
    return 'Excluir todos os arquivos de \"$title - Temporada $season\"? Isso remove do disco todos os arquivos de episódio desta temporada.';
  }

  @override
  String get seriesDeleteSeasonsFilesContent =>
      'Isso exclui do disco os arquivos de episódio das temporadas selecionadas. A série continua no Sonarr.';

  @override
  String get seriesDeleteSeries => 'Excluir série';

  @override
  String seriesDeleteSeriesConfirm(String title) {
    return 'Tem certeza de que deseja excluir \"$title\"?';
  }

  @override
  String get seriesDeleted => 'Série excluída';

  @override
  String seriesDeletedFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos excluídos',
      one: '1 arquivo excluído',
    );
    return '$_temp0';
  }

  @override
  String get seriesEditSeries => 'Editar série';

  @override
  String get seriesEmptySubtitle =>
      'Adicione séries à sua biblioteca do Sonarr para vê-las aqui.';

  @override
  String get seriesEpisodeActions => 'Ações do episódio';

  @override
  String seriesEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episódios',
      one: '1 episódio',
    );
    return '$_temp0';
  }

  @override
  String seriesEpisodeLoadFailed(String error) {
    return 'Falha ao carregar o episódio: $error';
  }

  @override
  String get seriesEpisodeLoading => 'Carregando episódio...';

  @override
  String get seriesEpisodeMonitored => 'Episódio monitorado';

  @override
  String get seriesEpisodeUnmonitored => 'Episódio desmonitorado';

  @override
  String get seriesFile => 'Arquivo';

  @override
  String get seriesFileDeleted => 'Arquivo excluído';

  @override
  String get seriesHideAlreadyAdded => 'Ocultar já adicionadas';

  @override
  String get seriesHistory => 'Histórico';

  @override
  String seriesLoadEpisodesFailed(String error) {
    return 'Falha ao carregar episódios: $error';
  }

  @override
  String get seriesLoadFileInfoFailed =>
      'Falha ao carregar informações do arquivo';

  @override
  String seriesLoadFoldersError(String error) {
    return 'Erro ao carregar pastas: $error';
  }

  @override
  String get seriesLoadHistoryFailed => 'Falha ao carregar o histórico';

  @override
  String seriesLoadProfilesError(String error) {
    return 'Erro ao carregar perfis: $error';
  }

  @override
  String get seriesLoadingDetails => 'Carregando detalhes...';

  @override
  String get seriesLoadingSeries => 'Carregando séries...';

  @override
  String get seriesMonitorEpisode => 'Monitorar episódio';

  @override
  String get seriesMonitorNewSeasons => 'Monitorar novas temporadas';

  @override
  String get seriesMonitorNewSeasonsSubtitle =>
      'Monitorar automaticamente temporadas adicionadas no futuro';

  @override
  String get seriesMonitoredSubtitle => 'Monitorar episódios desta série';

  @override
  String get seriesMoveFilesContent =>
      'Você alterou a pasta raiz. Deseja mover os arquivos existentes para o novo local?';

  @override
  String get seriesMoveFilesTitle => 'Mover arquivos?';

  @override
  String get seriesNetwork => 'Emissora';

  @override
  String get seriesNoEpisodesFound => 'Nenhum episódio encontrado';

  @override
  String get seriesNoFileAvailable => 'Nenhum arquivo disponível';

  @override
  String get seriesNoFilesToDelete => 'Nenhum arquivo para excluir';

  @override
  String get seriesNoHistoryEvents => 'Nenhum evento no histórico';

  @override
  String get seriesNoOverview => 'Nenhuma sinopse disponível.';

  @override
  String get seriesNoRating => 'Sem avaliação';

  @override
  String get seriesNoResultsFound => 'Nenhum resultado encontrado';

  @override
  String get seriesNoResultsSubtitle =>
      'Tente limpar ou ajustar sua busca ou filtros.';

  @override
  String get seriesNoSeriesFound => 'Nenhuma série encontrada';

  @override
  String get seriesNoSonarrInstance =>
      'Nenhuma instância do Sonarr configurada';

  @override
  String get seriesOverview => 'Sinopse';

  @override
  String get seriesPath => 'Caminho';

  @override
  String get seriesPreventReAdd =>
      'Impedir que esta série seja adicionada novamente';

  @override
  String get seriesPreview => 'Prévia da série';

  @override
  String seriesPreviewCrossSeedsFailed(String error) {
    return 'Falha ao gerar a prévia de cross-seeds: $error';
  }

  @override
  String seriesPreviewFailed(String error) {
    return 'Falha ao gerar a prévia: $error';
  }

  @override
  String seriesPurgeFailed(String error) {
    return 'Falha ao expurgar: $error';
  }

  @override
  String get seriesPurgeSeason => 'Expurgar temporada';

  @override
  String seriesPurgeSeasonConfirm(String title, int season) {
    return 'Excluir todos os arquivos de \"$title - Temporada $season\" e remover os torrents de origem do qBittorrent? A série continua no Sonarr.';
  }

  @override
  String get seriesPurgeSeasonsContent =>
      'Isso exclui os arquivos de episódio das temporadas selecionadas e seus torrents de origem do qBittorrent. A série continua no Sonarr.';

  @override
  String seriesPurgeSeasonsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expurgar $count temporadas',
      one: 'Expurgar 1 temporada',
    );
    return '$_temp0';
  }

  @override
  String get seriesPurgeSeries => 'Expurgar série';

  @override
  String seriesPurgeSeriesConfirm(String title) {
    return 'Isso removerá permanentemente \"$title\" e todos os seus episódios do Sonarr, excluirá seus arquivos de mídia e excluirá todos os torrents de origem (incluindo duplicatas de cross-seed) do qBittorrent. Libera o espaço em disco usado por dados com hardlink.';
  }

  @override
  String get seriesPurged => 'Série expurgada.';

  @override
  String seriesPurgedSeasonsSummary(int seasons, int files, int torrents) {
    String _temp0 = intl.Intl.pluralLogic(
      seasons,
      locale: localeName,
      other: '$seasons temporadas expurgadas',
      one: '1 temporada expurgada',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files arquivos',
      one: '1 arquivo',
    );
    String _temp2 = intl.Intl.pluralLogic(
      torrents,
      locale: localeName,
      other: '$torrents torrents',
      one: '1 torrent',
    );
    return '$_temp0: $_temp1, $_temp2.';
  }

  @override
  String seriesPurgedSummary(int files, int torrents) {
    String _temp0 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files arquivos',
      one: '1 arquivo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      torrents,
      locale: localeName,
      other: '$torrents torrents',
      one: '1 torrent',
    );
    return 'Expurgado: $_temp0, $_temp1.';
  }

  @override
  String get seriesRefreshAndScan => 'Atualizar e escanear';

  @override
  String get seriesRefreshScanTriggered =>
      'Atualização e escaneamento iniciados';

  @override
  String seriesRootFolderFreeSpace(String path, String free) {
    return '$path ($free GB livres)';
  }

  @override
  String get seriesRootFolderHeader => 'PASTA RAIZ';

  @override
  String seriesRuntimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get seriesSearchByHint => 'Busque por título, ID do provedor ou URL';

  @override
  String seriesSearchFailed(String error) {
    return 'Falha na busca: $error';
  }

  @override
  String get seriesSearchHint => 'Buscar séries...';

  @override
  String seriesSearchStartedFor(String name) {
    return 'Busca iniciada para $name';
  }

  @override
  String seriesSearchStartedForSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Busca iniciada para $count temporadas',
      one: 'Busca iniciada para 1 temporada',
    );
    return '$_temp0';
  }

  @override
  String seriesSearchingFor(String name) {
    return 'Buscando $name...';
  }

  @override
  String get seriesSeasonActions => 'Ações da temporada';

  @override
  String seriesSeasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temporadas',
      one: '1 temporada',
    );
    return '$_temp0';
  }

  @override
  String get seriesSeasonFolder => 'Pasta de temporada';

  @override
  String get seriesSeasonFolders => 'Pastas de temporada';

  @override
  String get seriesSeasonFoldersSubtitle =>
      'Usar pastas por temporada (ex.: Season 01/...)';

  @override
  String seriesSeasonLoadFailed(String error) {
    return 'Falha ao carregar a temporada: $error';
  }

  @override
  String get seriesSeasonLoading => 'Carregando temporada...';

  @override
  String get seriesSeasonTitle => 'Temporada';

  @override
  String get seriesSeasons => 'Temporadas';

  @override
  String get seriesSelect => 'Selecionar';

  @override
  String get seriesSelectPath => 'Selecionar caminho';

  @override
  String seriesSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionadas',
      one: '1 selecionada',
    );
    return '$_temp0';
  }

  @override
  String get seriesSeriesType => 'Tipo de série';

  @override
  String get seriesSortAndFilter => 'Ordenar e filtrar';

  @override
  String get seriesSwitchToGrid => 'Mudar para grade';

  @override
  String get seriesSwitchToList => 'Mudar para lista';

  @override
  String seriesTitleWithSeason(String title, int season) {
    return '$title - Temporada $season';
  }

  @override
  String seriesUnableToOpenLink(String error) {
    return 'Não foi possível abrir o link: $error';
  }

  @override
  String get seriesUnmonitorEpisode => 'Desmonitorar episódio';

  @override
  String seriesUnmonitoredSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temporadas desmonitoradas',
      one: '1 temporada desmonitorada',
    );
    return '$_temp0';
  }

  @override
  String seriesUpdateEpisodeFailed(String error) {
    return 'Falha ao atualizar o episódio: $error';
  }

  @override
  String seriesUpdateFailed(String error) {
    return 'Erro ao atualizar a série: $error';
  }

  @override
  String seriesViewPoster(String title) {
    return 'Ver pôster de $title';
  }

  @override
  String get seriesWatch => 'Assistir';

  @override
  String get seriesYesMoveFiles => 'Sim, mover arquivos';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsAddInstance => 'Adicionar instância';

  @override
  String get settingsAppUpToDate => 'O app está atualizado';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsAssistant => 'Assistente';

  @override
  String get settingsAssistantSubtitle => 'Pergunte como o app funciona';

  @override
  String get settingsBackupLocalFileSubtitle =>
      'Importar ou exportar um arquivo local';

  @override
  String get settingsColorScheme => 'Esquema de cores';

  @override
  String get settingsCouldNotCheckUpdates =>
      'Não foi possível verificar atualizações';

  @override
  String get settingsGettingStarted => 'Primeiros passos';

  @override
  String get settingsGettingStartedSubtitle => 'Repetir o tour de configuração';

  @override
  String get settingsHomeTab => 'Aba inicial';

  @override
  String settingsInstanceTagCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return '$_temp0';
  }

  @override
  String get settingsInstances => 'Instâncias';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsNoArrInstancesConfigured =>
      'Nenhuma instância Arr configurada';

  @override
  String get settingsNoInstances => 'Nenhuma instância configurada';

  @override
  String get settingsNoRadarrSonarrInstances =>
      'Nenhuma instância do Radarr ou Sonarr configurada';

  @override
  String get settingsNotificationCenter => 'Central de notificações';

  @override
  String get settingsNotificationSettings => 'Configurações de notificação';

  @override
  String get settingsNotifications => 'Notificações';

  @override
  String get settingsNotificationsEnabledSubtitle =>
      'Ativado · integração com ntfy.sh';

  @override
  String get settingsNotificationsSetupSubtitle => 'Configurar notificações';

  @override
  String get settingsSelectColor => 'Selecionar cor';

  @override
  String get settingsSelectHomeTab => 'Selecionar aba inicial';

  @override
  String get settingsSelectLanguage => 'Selecionar idioma';

  @override
  String get settingsSelectMode => 'Selecionar modo';

  @override
  String get settingsSessionExpiredSignIn =>
      'Sessão expirada · toque para entrar';

  @override
  String get settingsSourceCode => 'Código-fonte';

  @override
  String get settingsSystem => 'Sistema';

  @override
  String get settingsSystemManagementSubtitle =>
      'Diagnóstico, status, logs e manutenção do app';

  @override
  String get settingsThemeMode => 'Modo do tema';

  @override
  String settingsUnreadNotifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificações não lidas',
      one: '1 notificação não lida',
    );
    return '$_temp0';
  }

  @override
  String get settingsVersion => 'Versão';

  @override
  String settingsVersionViaAltStore(String version) {
    return '$version • atualizações via AltStore';
  }

  @override
  String get settingsViewAllNotifications => 'Ver todas as notificações';

  @override
  String get sharedAddImportExclusion =>
      'Adicionar à lista de exclusão de importação';

  @override
  String get sharedAddImportExclusionSubtitle =>
      'Impede que o item seja adicionado novamente por uma lista de importação.';

  @override
  String get sharedAscending => 'Crescente';

  @override
  String sharedBatchDeleteFilesFailed(String error) {
    return 'Falha ao excluir arquivos: $error';
  }

  @override
  String get sharedBatchDeleteMovieFilesContent =>
      'Isso exclui do disco os arquivos de mídia dos filmes selecionados. Eles permanecem no Radarr.';

  @override
  String sharedBatchDeleteMovieFilesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir arquivos de $count filmes',
      one: 'Excluir arquivos de 1 filme',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteMoviesKeepFiles =>
      'Isso remove os filmes selecionados do Radarr. Os arquivos permanecem no disco.';

  @override
  String sharedBatchDeleteMoviesPartial(int deleted, int total, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total filmes',
      one: '1 filme',
    );
    return '$deleted de $_temp0 excluídos antes do erro: $error';
  }

  @override
  String sharedBatchDeleteMoviesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count filmes',
      one: 'Excluir 1 filme',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteMoviesWithFiles =>
      'Isso remove os filmes selecionados do Radarr e exclui os arquivos deles do disco.';

  @override
  String get sharedBatchDeleteSeriesFilesContent =>
      'Isso exclui do disco os arquivos de mídia das séries selecionadas. Elas permanecem no Sonarr.';

  @override
  String sharedBatchDeleteSeriesFilesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir arquivos de $count séries',
      one: 'Excluir arquivos de 1 série',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteSeriesKeepFiles =>
      'Isso remove as séries selecionadas do Sonarr. Os arquivos permanecem no disco.';

  @override
  String sharedBatchDeleteSeriesPartial(int deleted, int total, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total séries',
      one: '1 série',
    );
    return '$deleted de $_temp0 excluídas antes do erro: $error';
  }

  @override
  String sharedBatchDeleteSeriesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count séries',
      one: 'Excluir 1 série',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteSeriesWithFiles =>
      'Isso remove as séries selecionadas do Sonarr e exclui os arquivos delas do disco.';

  @override
  String sharedBatchDeletedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos excluídos',
      one: '1 arquivo excluído',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filmes excluídos',
      one: '1 filme excluído',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedMoviesAndFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filmes e arquivos excluídos',
      one: '1 filme e arquivos excluídos',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries excluídas',
      one: '1 série excluída',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedSeriesAndFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries e arquivos excluídos',
      one: '1 série e arquivos excluídos',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchMonitoredMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filmes monitorados',
      one: '1 filme monitorado',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchMonitoredSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries monitoradas',
      one: '1 série monitorada',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchPreviewCrossSeedsFailed(String error) {
    return 'Falha ao gerar a prévia dos cross-seeds: $error';
  }

  @override
  String sharedBatchPreviewFailed(String error) {
    return 'Falha ao gerar a prévia: $error';
  }

  @override
  String sharedBatchPurgeFailed(String error) {
    return 'Falha ao expurgar: $error';
  }

  @override
  String get sharedBatchPurgeMoviesContent =>
      'Isso remove permanentemente os filmes selecionados do Radarr, exclui os arquivos deles e exclui todos os torrents de origem do qBittorrent.';

  @override
  String sharedBatchPurgeMoviesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expurgar $count filmes',
      one: 'Expurgar 1 filme',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchPurgeSeriesContent =>
      'Isso remove permanentemente as séries selecionadas do Sonarr, exclui os arquivos delas e exclui todos os torrents de origem do qBittorrent.';

  @override
  String sharedBatchPurgeSeriesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expurgar $count séries',
      one: 'Expurgar 1 série',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchPurgedMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filmes expurgados.',
      one: '1 filme expurgado.',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchPurgedSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries expurgadas.',
      one: '1 série expurgada.',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchUnmonitoredMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filmes deixaram de ser monitorados',
      one: '1 filme deixou de ser monitorado',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchUnmonitoredSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries deixaram de ser monitoradas',
      one: '1 série deixou de ser monitorada',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchUpdateMoviesPartial(int updated, int total, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total filmes',
      one: '1 filme',
    );
    return '$updated de $_temp0 atualizados antes do erro: $error';
  }

  @override
  String sharedBatchUpdateSeriesPartial(int updated, int total, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total séries',
      one: '1 série',
    );
    return '$updated de $_temp0 atualizadas antes do erro: $error';
  }

  @override
  String get sharedDescending => 'Decrescente';

  @override
  String get sharedFailedToLoadTorrents => 'Falha ao carregar os torrents';

  @override
  String get sharedNoRadarrInstance =>
      'Nenhuma instância do Radarr configurada';

  @override
  String get sharedNoTorrentsInClient =>
      'Nenhum torrent no cliente de download';

  @override
  String sharedSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionados',
      one: '1 selecionado',
    );
    return '$_temp0';
  }

  @override
  String get sharedTorrents => 'Torrents';

  @override
  String get systemAppMaintenance => 'Manutenção do app';

  @override
  String get systemClearImageCache => 'Limpar cache de imagens';

  @override
  String get systemClearImageCacheSubtitle =>
      'Libere o espaço usado por pôsteres e imagens em cache';

  @override
  String get systemDaysHelper => '0 desativa o aviso';

  @override
  String get systemDaysInvalid => 'Informe um número válido (0 ou mais)';

  @override
  String get systemDaysLabel => 'Dias';

  @override
  String get systemDiagnosticsSubtitle =>
      'Teste endpoints, latência, rastros de requisições e exporte um relatório';

  @override
  String get systemHealth => 'Saúde';

  @override
  String get systemHealthSubtitle =>
      'Alertas do Radarr e Sonarr reportados pelo servidor';

  @override
  String get systemImageCacheCleared => 'Cache de imagens limpo';

  @override
  String get systemLogs => 'Logs';

  @override
  String get systemLogsSubtitle => 'Logs de eventos do sistema';

  @override
  String get systemManagementTitle => 'Gerenciamento do sistema';

  @override
  String get systemMinimumSeedingDays => 'Dias mínimos de semeadura';

  @override
  String get systemMinimumSeedingDaysDescription =>
      'Torrents que semearam por menos tempo que isso pedem confirmação antes de serem excluídos. Use 0 para desativar.';

  @override
  String get systemOverviewDiskSpace => 'Espaço em disco';

  @override
  String get systemOverviewDiskSpaceUnavailable =>
      'As informações de espaço em disco não estão disponíveis.';

  @override
  String get systemOverviewEmptySubtitle =>
      'Adicione uma instância do Radarr ou Sonarr para ver os dados do sistema.';

  @override
  String systemOverviewEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Episódios',
      one: '1 Episódio',
    );
    return '$_temp0';
  }

  @override
  String systemOverviewFreeOf(String free, String total) {
    return '$free livres de $total';
  }

  @override
  String systemOverviewLibrarySize(String size) {
    return '$size Biblioteca';
  }

  @override
  String get systemOverviewLibraryUnavailable =>
      'As estatísticas da biblioteca não estão disponíveis.';

  @override
  String get systemOverviewLoadFailed =>
      'Falha ao carregar a visão geral do sistema.';

  @override
  String get systemOverviewLoading => 'Carregando visão geral do sistema...';

  @override
  String systemOverviewMovieCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Filmes',
      one: '1 Filme',
    );
    return '$_temp0';
  }

  @override
  String get systemOverviewNoStorage =>
      'Nenhum local de armazenamento reportado.';

  @override
  String systemOverviewSeriesCount(int count) {
    return '$count Séries';
  }

  @override
  String get systemOverviewSubtitle =>
      'Armazenamento, versões e tamanho das bibliotecas';

  @override
  String get systemOverviewTitle => 'Visão geral do sistema';

  @override
  String systemOverviewUsed(String size, int percent) {
    return 'Usado $size ($percent%)';
  }

  @override
  String get systemOverviewVersionUnavailable =>
      'As informações de versão não estão disponíveis.';

  @override
  String get systemQualityProfilesSubtitle =>
      'Perfis disponíveis nas instâncias';

  @override
  String get systemResetConfirmBody =>
      'Isso restaura aparência, idioma, modo de visualização e preferências de notificação para os padrões. As instâncias configuradas são mantidas.';

  @override
  String get systemResetConfirmTitle => 'Redefinir configurações do app?';

  @override
  String get systemResetSettings => 'Redefinir configurações do app';

  @override
  String get systemResetSettingsSubtitle =>
      'Restaura os padrões de aparência, idioma, visualização e notificações';

  @override
  String systemSeedingDaysShort(int count) {
    return '${count}d';
  }

  @override
  String get systemSeedingWarningDisabled => 'Aviso de semeadura desativado';

  @override
  String systemSeedingWarningEnabled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return 'Avisar antes de excluir torrents que semearam por menos de $_temp0.';
  }

  @override
  String get systemServer => 'Servidor';

  @override
  String get systemSettingsReset =>
      'Configurações do app redefinidas para os padrões';

  @override
  String get systemTorrentProtection => 'Proteção de torrents';

  @override
  String get systemVersionHistorySubtitle =>
      'Novidades de cada versão publicada';

  @override
  String torrentAddFailed(String error) {
    return 'Falha ao adicionar torrent: $error';
  }

  @override
  String get torrentAddOptions => 'Opções';

  @override
  String get torrentAddOr => 'OU';

  @override
  String get torrentAddSource => 'Origem';

  @override
  String get torrentAddSourceRequired =>
      'Informe URLs ou selecione um arquivo .torrent';

  @override
  String get torrentAddTorrent => 'Adicionar torrent';

  @override
  String get torrentAdded => 'Torrent adicionado com sucesso';

  @override
  String get torrentAlsoDeleteFiles => 'Também excluir os arquivos do disco';

  @override
  String get torrentCategoriesLoadFailed =>
      'Não foi possível carregar as categorias. Usando texto livre.';

  @override
  String get torrentCategoryOptional => 'Categoria (opcional)';

  @override
  String get torrentChangeSaveLocation => 'Alterar local de salvamento';

  @override
  String get torrentChangeSaveLocationWarning =>
      'Isso moverá todos os dados baixados para o novo local.';

  @override
  String get torrentClearSearch => 'Limpar busca';

  @override
  String torrentConnectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conectados',
      one: '1 conectado',
    );
    return '$_temp0';
  }

  @override
  String get torrentCrossSeedExplanation =>
      'Identificado como cross-seed: mesmo nome de release do torrent que o Radarr/Sonarr capturou, infohash diferente.';

  @override
  String get torrentEmptySubtitle =>
      'Adicione um torrent para começar a baixar';

  @override
  String get torrentEmptyTitle => 'Nenhum torrent';

  @override
  String get torrentEnterValidPath => 'Informe um caminho válido';

  @override
  String torrentEta(String eta) {
    return 'Restante: $eta';
  }

  @override
  String get torrentFiles => 'Arquivos';

  @override
  String get torrentFilterLibraryLink => 'Vínculo com a biblioteca';

  @override
  String get torrentFilterTooltip => 'Filtrar torrents';

  @override
  String get torrentFiltersSubtitle => 'Combine quantos filtros quiser';

  @override
  String get torrentFiltersTitle => 'Filtros de torrent';

  @override
  String torrentImportFailed(String error) {
    return 'Falha ao importar: $error';
  }

  @override
  String torrentImportFilesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos importados com sucesso',
      one: '1 arquivo importado com sucesso',
    );
    return '$_temp0';
  }

  @override
  String torrentImportFilesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos selecionados para importação',
      one: '1 arquivo selecionado para importação',
    );
    return '$_temp0';
  }

  @override
  String get torrentImportLoadMoviesFailed => 'Falha ao carregar filmes';

  @override
  String get torrentImportLoadSeriesFailed => 'Falha ao carregar séries';

  @override
  String get torrentImportLoadingMovies => 'Carregando filmes...';

  @override
  String get torrentImportLoadingSeries => 'Carregando séries...';

  @override
  String get torrentImportNoFilesSelected => 'Nenhum arquivo selecionado';

  @override
  String torrentImportNoFilesSubtitle(String path) {
    return 'Nenhum arquivo importável encontrado em $path';
  }

  @override
  String get torrentImportNoFilesTitle => 'Nenhum arquivo encontrado';

  @override
  String get torrentImportNoMoviesSubtitle =>
      'Nenhum filme monitorado corresponde à sua busca.';

  @override
  String get torrentImportNoMoviesTitle => 'Nenhum filme encontrado';

  @override
  String get torrentImportNoSeriesSubtitle =>
      'Nenhuma série monitorada corresponde à sua busca.';

  @override
  String get torrentImportNoSeriesTitle => 'Nenhuma série encontrada';

  @override
  String get torrentImportSearchHint => 'Buscar...';

  @override
  String get torrentImportSelectFilesHint =>
      'Selecione os arquivos para importar. Toque em um arquivo para configurar o mapeamento.';

  @override
  String get torrentImportSelectTarget => 'Selecionar destino';

  @override
  String get torrentImportToLibrary => 'Importar para a biblioteca';

  @override
  String get torrentImportToMovie => 'Importar para filme';

  @override
  String get torrentImportToSeries => 'Importar para série';

  @override
  String get torrentInfoAddedOn => 'Adicionado em';

  @override
  String get torrentInfoCategory => 'Categoria';

  @override
  String get torrentInfoHash => 'Hash';

  @override
  String get torrentInfoInstance => 'Instância';

  @override
  String get torrentInfoMedia => 'Mídia';

  @override
  String get torrentInfoSavePath => 'Caminho';

  @override
  String get torrentLibraryLinksLoadFailed =>
      'Não foi possível carregar os vínculos com a biblioteca.';

  @override
  String get torrentLoadFailed => 'Falha ao carregar torrents';

  @override
  String torrentLoadFilesFailed(String error) {
    return 'Falha ao carregar arquivos: $error';
  }

  @override
  String get torrentLoadPeersFailed => 'Falha ao carregar peers';

  @override
  String get torrentLoadTrackersFailed => 'Falha ao carregar trackers';

  @override
  String get torrentLoading => 'Carregando torrents...';

  @override
  String get torrentLoadingFiles => 'Carregando arquivos...';

  @override
  String get torrentLoadingPeers => 'Carregando peers...';

  @override
  String get torrentLoadingTrackers => 'Carregando trackers...';

  @override
  String get torrentLocationMoved =>
      'Local alterado com sucesso. Os dados estão sendo movidos.';

  @override
  String get torrentMove => 'Mover';

  @override
  String torrentMoveFailed(String error) {
    return 'Falha ao mover: $error';
  }

  @override
  String get torrentNewLocation => 'Novo local';

  @override
  String get torrentNoFilesFound => 'Nenhum arquivo encontrado';

  @override
  String get torrentNoFilterMatches =>
      'Nenhum torrent corresponde aos filtros atuais';

  @override
  String get torrentNoPeers => 'Nenhum peer conectado';

  @override
  String get torrentNoPeersSubtitle =>
      'Os peers aparecerão quando o torrent estiver ativo';

  @override
  String get torrentNoTrackers => 'Nenhum tracker';

  @override
  String get torrentNoTrackersSubtitle =>
      'As URLs de anúncio aparecem aqui quando o qBittorrent as tiver';

  @override
  String get torrentPause => 'Pausar';

  @override
  String torrentPeerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peers',
      one: '1 peer',
    );
    return '$_temp0';
  }

  @override
  String get torrentPeers => 'Peers';

  @override
  String torrentPercentCompleted(String percent) {
    return '$percent concluído';
  }

  @override
  String torrentPercentDone(String percent) {
    return '$percent concluído';
  }

  @override
  String torrentPickFileFailed(String error) {
    return 'Falha ao selecionar arquivo: $error';
  }

  @override
  String get torrentRecheck => 'Verificar';

  @override
  String get torrentRememberFilters => 'Lembrar filtros';

  @override
  String get torrentRememberFiltersSubtitle =>
      'Manter esta configuração para as próximas sessões';

  @override
  String get torrentRemove => 'Remover';

  @override
  String torrentRemoveConfirm(String name) {
    return 'Tem certeza de que deseja remover \"$name\"?';
  }

  @override
  String torrentRemoveFailed(String error) {
    return 'Falha ao remover torrent: $error';
  }

  @override
  String get torrentRemoveTitle => 'Remover torrent?';

  @override
  String get torrentRemoveTorrent => 'Remover torrent';

  @override
  String torrentResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count torrents',
      one: '1 torrent',
    );
    return '$_temp0';
  }

  @override
  String torrentResultCountWithHidden(int count, int hidden) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count torrents · ocultos: $hidden',
      one: '1 torrent · ocultos: $hidden',
    );
    return '$_temp0';
  }

  @override
  String get torrentResume => 'Retomar';

  @override
  String get torrentSavePathOptional => 'Caminho de salvamento (opcional)';

  @override
  String get torrentSearchHint => 'Buscar torrents';

  @override
  String get torrentSectionActions => 'Ações';

  @override
  String get torrentSectionInformation => 'Informações';

  @override
  String get torrentSectionMediaLibrary => 'Biblioteca de mídia';

  @override
  String get torrentSectionProgress => 'Progresso';

  @override
  String get torrentSelectFile => 'Selecionar arquivo .torrent';

  @override
  String get torrentSetPriority => 'Definir prioridade';

  @override
  String get torrentSortAscending => 'Crescente';

  @override
  String get torrentSortDescending => 'Decrescente';

  @override
  String get torrentStartPaused => 'Iniciar pausado';

  @override
  String get torrentStatDlSpeed => 'Vel. download';

  @override
  String get torrentStatDownloaded => 'Baixado';

  @override
  String get torrentStatLeechers => 'Leechers';

  @override
  String get torrentStatRatio => 'Proporção';

  @override
  String get torrentStatSeedTime => 'Tempo semeando';

  @override
  String get torrentStatSeeds => 'Seeds';

  @override
  String get torrentStatTotalSize => 'Tamanho total';

  @override
  String get torrentStatUlSpeed => 'Vel. upload';

  @override
  String get torrentStatUploaded => 'Enviado';

  @override
  String get torrentTagsCommaSeparated => 'Separadas por vírgula';

  @override
  String get torrentTagsLoadFailed =>
      'Não foi possível carregar as tags. Usando texto livre.';

  @override
  String get torrentTagsOptional => 'Tags (opcional)';

  @override
  String get torrentTagsSearchHint => 'Digite para buscar ou adicionar tags';

  @override
  String torrentTrackerDownloads(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count downloads',
      one: '1 download',
    );
    return '$_temp0';
  }

  @override
  String torrentTrackerLeechers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leechers',
      one: '1 leecher',
    );
    return '$_temp0';
  }

  @override
  String torrentTrackerPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peers',
      one: '1 peer',
    );
    return '$_temp0';
  }

  @override
  String torrentTrackerSeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seeds',
      one: '1 seed',
    );
    return '$_temp0';
  }

  @override
  String torrentTrackerTier(int tier) {
    return 'Nível $tier';
  }

  @override
  String get torrentTrackers => 'Trackers';

  @override
  String get torrentUrlsHint =>
      'Cole links magnet ou URLs HTTP aqui\nUm por linha';

  @override
  String get torrentUrlsLabel => 'Link magnet ou URLs';

  @override
  String get tourActivityBody =>
      'Acompanhe aqui sua fila de downloads, o histórico e os torrents do qBittorrent.';

  @override
  String get tourActivityQueueBody =>
      'Os downloads ativos mostram o progresso, o tamanho restante e a previsão de conclusão. Toque em um para ver detalhes e ações.';

  @override
  String get tourActivityQueueTitle => 'Fila de downloads';

  @override
  String get tourAddInstanceBody =>
      'Toque aqui para criar uma nova conexão com um servidor. Os próximos passos explicam o formulário.';

  @override
  String get tourAddInstanceTitle => 'Adicionar instância';

  @override
  String get tourCalendarBody =>
      'Acompanhe os próximos lançamentos de filmes e episódios de séries.';

  @override
  String get tourCalendarEventsBody =>
      'Cada cartão mostra o que será exibido ou lançado em seguida, agrupado por dia e com cores por tipo de lançamento.';

  @override
  String get tourCalendarEventsTitle => 'Próximos lançamentos';

  @override
  String get tourInstanceApiKeyBody =>
      'Radarr/Sonarr exigem uma API Key, disponível em Settings → General. O qBittorrent usa um token Bearer (v5.2.0+) ou Basic Auth.';

  @override
  String get tourInstanceApiKeyTitle => 'API Key';

  @override
  String get tourInstanceNameBody =>
      'Um nome amigável para diferenciar seus servidores (ex.: \"Servidor de casa\").';

  @override
  String get tourInstanceNameTitle => 'Nome';

  @override
  String get tourInstanceTypeBody =>
      'Escolha Radarr (filmes), Sonarr (séries) ou qBittorrent (downloads). Cada um precisa da sua própria conexão.';

  @override
  String get tourInstanceTypeTitle => 'Escolha o tipo de servidor';

  @override
  String get tourInstanceUrlBody =>
      'O endereço do seu servidor com http(s):// e a porta, ex.: http://192.168.1.10:7878.';

  @override
  String get tourInstanceUrlTitle => 'URL';

  @override
  String get tourInstancesBody =>
      'Seus servidores Radarr, Sonarr e qBittorrent ficam aqui. Vamos adicionar o primeiro.';

  @override
  String get tourInstancesTitle => 'Instâncias';

  @override
  String get tourMockupBanner =>
      'Conteúdo de exemplo exibido durante o tour. Ele desaparece quando o tour termina.';

  @override
  String get tourMoviesLibraryBody =>
      'Todos os filmes gerenciados pelo Radarr aparecem aqui, com o status de monitoramento e de download.';

  @override
  String get tourMoviesLibraryTitle => 'Sua biblioteca de filmes';

  @override
  String get tourMoviesSearchBody =>
      'Encontre filmes na sua biblioteca pelo título.';

  @override
  String get tourMoviesSortBody =>
      'Reordene e filtre sua biblioteca para navegar mais rápido.';

  @override
  String get tourMoviesSortTitle => 'Ordenar e filtrar';

  @override
  String get tourNavigationBody =>
      'Alterne entre Filmes, Séries, Calendário, Atividade e Configurações a qualquer momento.';

  @override
  String get tourNavigationTitle => 'Navegação';

  @override
  String get tourSaveInstanceBody =>
      'Quando tudo estiver certo, salve para concluir a configuração. Você pode adicionar os outros servidores a qualquer momento em Configurações.';

  @override
  String get tourSaveInstanceTitle => 'Salvar instância';

  @override
  String get tourSeriesLibraryBody =>
      'Suas séries do Sonarr ficam aqui, com o número de temporadas e quanto de cada série já foi baixado.';

  @override
  String get tourSeriesLibraryTitle => 'Sua biblioteca de séries';

  @override
  String get tourSkip => 'Pular';

  @override
  String get tourTestConnectionBody =>
      'Verifica a URL e as credenciais antes de salvar.';

  @override
  String get tourTestConnectionTitle => 'Testar conexão';

  @override
  String get tourTorrentsBody =>
      'Os torrents do qBittorrent mostram velocidade, ratio e peers em tempo real, com ações para pausar, retomar e importar.';

  @override
  String get tourTorrentsTitle => 'Torrents';

  @override
  String get updateAndRestart => 'Atualizar e reiniciar';

  @override
  String get updateAvailableTitle => 'Nova versão disponível';

  @override
  String get updateChangelog => 'Changelog:';

  @override
  String get updateDownloadingTitle => 'Baixando atualização';

  @override
  String get updateInstallingTitle => 'Instalando...';

  @override
  String get updateLater => 'Mais tarde';

  @override
  String get updateNow => 'Atualizar agora';

  @override
  String get updatePreparing => 'Preparando a atualização...';

  @override
  String get updateRestartNotice =>
      'O aplicativo será fechado e reiniciado para concluir a atualização.';

  @override
  String get updateUnexpectedError => 'Ocorreu um erro inesperado.';

  @override
  String updateVersion(String version) {
    return 'Versão: $version';
  }

  @override
  String get versionHistoryEmptySubtitle =>
      'Não foi possível carregar o histórico de versões.';

  @override
  String get versionHistoryEmptyTitle => 'Nenhuma versão disponível';

  @override
  String get versionHistoryInstalled => 'Instalada';

  @override
  String versionHistoryLoadFailed(String error) {
    return 'Falha ao carregar o histórico de versões: $error';
  }

  @override
  String get versionHistoryLoading => 'Carregando histórico de versões...';

  @override
  String get versionHistoryTitle => 'Histórico de versões';

  @override
  String get watchingEmptySubtitle =>
      'As mídias que você pausar no Jellyfin aparecerão aqui.';

  @override
  String get watchingEmptyTitle => 'Nada em andamento';

  @override
  String get watchingLoading => 'Carregando continuar assistindo...';

  @override
  String get whatsNewNoNotes => 'Esta versão não inclui notas de lançamento.';

  @override
  String whatsNewTitle(String version) {
    return 'Novidades da v$version';
  }

  @override
  String get whatsNewViewAllVersions => 'Ver todas as versões';

  @override
  String get widgetsClosePoster => 'Fechar pôster';

  @override
  String widgetsCustomFormatScore(String score) {
    return 'Pontuação: $score';
  }

  @override
  String get widgetsDeleteFile => 'Excluir arquivo';

  @override
  String get widgetsEventAdditionalData => 'Dados adicionais';

  @override
  String get widgetsEventDate => 'Data';

  @override
  String get widgetsEventDetailsTitle => 'Detalhes do evento';

  @override
  String get widgetsEventSourceTitle => 'Título de origem';

  @override
  String get widgetsEventType => 'Tipo de evento';

  @override
  String get widgetsExtraFileMetadata => 'Metadados';

  @override
  String get widgetsExtraFileOther => 'Outro';

  @override
  String get widgetsExtraFileSubtitle => 'Legenda';

  @override
  String get widgetsFileAudioBitrate => 'Bitrate de áudio';

  @override
  String get widgetsFileAudioChannels => 'Canais de áudio';

  @override
  String get widgetsFileAudioCodec => 'Codec de áudio';

  @override
  String get widgetsFileAudioLanguages => 'Idiomas do áudio';

  @override
  String get widgetsFileAudioStreams => 'Faixas de áudio';

  @override
  String get widgetsFileBitDepth => 'Profundidade de bits';

  @override
  String get widgetsFileCustomFormats => 'Formatos personalizados';

  @override
  String get widgetsFileDateAdded => 'Data de adição';

  @override
  String get widgetsFileDetailsTitle => 'Detalhes do arquivo';

  @override
  String get widgetsFileDuration => 'Duração';

  @override
  String get widgetsFileDynamicRange => 'Faixa dinâmica';

  @override
  String get widgetsFileFrameRate => 'Taxa de quadros';

  @override
  String get widgetsFileGeneral => 'Geral';

  @override
  String get widgetsFileHdrType => 'Tipo de HDR';

  @override
  String get widgetsFileMediaInfo => 'Informações da mídia';

  @override
  String get widgetsFilePath => 'Caminho';

  @override
  String get widgetsFileResolution => 'Resolução';

  @override
  String get widgetsFileRevision => 'Revisão';

  @override
  String get widgetsFileScanType => 'Tipo de varredura';

  @override
  String get widgetsFileSource => 'Fonte';

  @override
  String get widgetsFileSubtitles => 'Legendas';

  @override
  String get widgetsFileVideoBitrate => 'Bitrate de vídeo';

  @override
  String get widgetsFileVideoCodec => 'Codec de vídeo';

  @override
  String get widgetsNoPreviousOnline =>
      'Nenhuma conexão online anterior registrada';

  @override
  String get widgetsNoTagsAvailable => 'Nenhuma tag disponível';

  @override
  String get widgetsNotifications => 'Notificações';

  @override
  String get widgetsOffline => 'Offline';

  @override
  String widgetsOfflineCacheCaveat(String lastOnline, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return '$lastOnline · As imagens em cache podem ter até $_temp0';
  }

  @override
  String get widgetsPlay => 'Reproduzir';

  @override
  String get widgetsQueueDownloadFailed => 'Falha no download';

  @override
  String get widgetsQueueDownloadPaused => 'Download pausado';

  @override
  String get widgetsQueueDownloadPending => 'Download pendente';

  @override
  String get widgetsQueueDownloadWarning => 'Aviso no download';

  @override
  String get widgetsQueueStatusUnknown => 'Status desconhecido';

  @override
  String widgetsSelectInstance(String type) {
    return 'Selecionar instância do $type';
  }

  @override
  String get widgetsSelectTags => 'Selecionar tags';

  @override
  String get widgetsSomeInstancesFailed =>
      'Algumas instâncias não puderam ser carregadas';

  @override
  String get widgetsSortBy => 'Ordenar por';

  @override
  String get widgetsSortOrder => 'Ordem';

  @override
  String widgetsTagButtonWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get widgetsUnknownFile => 'Arquivo desconhecido';
}
