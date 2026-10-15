// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appInitErrorTitle => 'Error de inicialización';

  @override
  String get appInitNotificationServicesFailed =>
      'No se pudieron iniciar los servicios de notificación. Algunas funciones pueden no funcionar correctamente.';

  @override
  String get appTitle => 'Arrmate';

  @override
  String get commonAdd => 'Añadir';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get commonAutomaticSearch => 'Búsqueda automática';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClear => 'Borrar';

  @override
  String get commonClearFilters => 'Borrar filtros';

  @override
  String get commonClient => 'Cliente';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonDeleteFiles => 'Eliminar archivos';

  @override
  String get commonDismiss => 'Descartar';

  @override
  String get commonEdit => 'Editar';

  @override
  String commonErrorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get commonFilter => 'Filtrar';

  @override
  String get commonImport => 'Importar';

  @override
  String get commonIndexer => 'Indexador';

  @override
  String get commonInteractiveSearch => 'Búsqueda interactiva';

  @override
  String get commonLanguage => 'Idioma';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonMonitor => 'Monitorizar';

  @override
  String get commonMonitored => 'Monitorizado';

  @override
  String get commonMovies => 'Películas';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonOpenExternally => 'Abrir externamente';

  @override
  String get commonOpenInLibrary => 'Abrir en la biblioteca';

  @override
  String get commonProtocol => 'Protocolo';

  @override
  String get commonPurge => 'Purgar';

  @override
  String get commonQuality => 'Calidad';

  @override
  String get commonQualityProfile => 'Perfil de calidad';

  @override
  String get commonRefresh => 'Actualizar';

  @override
  String get commonReset => 'Restablecer';

  @override
  String get commonRestore => 'Restaurar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonRootFolder => 'Carpeta raíz';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonSearchStarted => 'Búsqueda iniciada';

  @override
  String get commonSelectAll => 'Seleccionar todo';

  @override
  String get commonSeries => 'Series';

  @override
  String get commonSize => 'Tamaño';

  @override
  String get commonSort => 'Ordenar';

  @override
  String get commonSortBy => 'Ordenar por';

  @override
  String get commonStatus => 'Estado';

  @override
  String get commonTags => 'Etiquetas';

  @override
  String get commonUnknown => 'Desconocido';

  @override
  String get commonUnmonitor => 'Dejar de monitorizar';

  @override
  String get commonUnmonitored => 'No monitorizado';

  @override
  String get commonWatchInJellyfin => 'Ver en Jellyfin';

  @override
  String get commonYes => 'Sí';

  @override
  String get errorConnectionFailed => 'Error de conexión. Comprueba tu red.';

  @override
  String errorInvalidUrl(String url) {
    return 'URL no válida: $url';
  }

  @override
  String get errorNotFound => 'Recurso no encontrado.';

  @override
  String get errorRequestCancelled => 'Solicitud cancelada';

  @override
  String get errorRequestTimedOut =>
      'La solicitud agotó el tiempo de espera. Inténtalo de nuevo.';

  @override
  String get errorServer => 'Error del servidor. Inténtalo de nuevo más tarde.';

  @override
  String get errorUnauthorized => 'No autorizado. Comprueba tu API Key.';

  @override
  String get errorUnknown => 'Se produjo un error desconocido.';

  @override
  String get errorValidationFailed => 'La validación falló.';

  @override
  String formatDaysAgo(int count) {
    return 'hace $count d';
  }

  @override
  String formatHoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String get formatJustNow => 'Justo ahora';

  @override
  String formatLastOnline(String time) {
    return 'Última conexión $time';
  }

  @override
  String formatMinutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String formatMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count meses',
      one: 'hace 1 mes',
    );
    return '$_temp0';
  }

  @override
  String formatSeason(int number) {
    return 'Temporada $number';
  }

  @override
  String formatSeasonEpisode(int season, int episode) {
    return 'Temporada $season, Episodio $episode';
  }

  @override
  String formatTitleWithSeason(String title, int season) {
    return '$title (Temporada $season)';
  }

  @override
  String formatWeeksAgo(int count) {
    return 'hace $count sem';
  }

  @override
  String formatYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count años',
      one: 'hace 1 año',
    );
    return '$_temp0';
  }

  @override
  String get formatYesterday => 'Ayer';

  @override
  String get labelAll => 'Todos';

  @override
  String get labelAppearanceDark => 'Oscuro';

  @override
  String get labelAppearanceLight => 'Claro';

  @override
  String get labelAppearanceSystem => 'Sistema';

  @override
  String get labelCalendarAllMedia => 'Todo el contenido';

  @override
  String get labelCalendarUnknownMovie => 'Película desconocida';

  @override
  String get labelCalendarUnknownSeries => 'Serie desconocida';

  @override
  String get labelColorAmber => 'Ámbar';

  @override
  String get labelColorBlue => 'Azul';

  @override
  String get labelColorGreen => 'Verde';

  @override
  String get labelColorIndigo => 'Índigo';

  @override
  String get labelColorOrange => 'Naranja';

  @override
  String get labelColorPink => 'Rosa';

  @override
  String get labelColorPurple => 'Morado';

  @override
  String get labelColorRed => 'Rojo';

  @override
  String get labelColorTeal => 'Verde azulado';

  @override
  String get labelDangling => 'Abandonado';

  @override
  String get labelDeleted => 'Eliminado';

  @override
  String get labelDigitalRelease => 'Estreno digital';

  @override
  String get labelDiscoverySortLatest => 'Más recientes';

  @override
  String get labelDiscoverySortRelevant => 'Relevantes';

  @override
  String get labelDownloaded => 'Descargado';

  @override
  String get labelDownloading => 'Descargando';

  @override
  String get labelEpisode => 'Episodio';

  @override
  String get labelError => 'Error';

  @override
  String get labelFailed => 'Fallido';

  @override
  String get labelFilePriorityDoNotDownload => 'No descargar';

  @override
  String get labelFilePriorityHigh => 'Prioridad alta';

  @override
  String get labelFilePriorityLow => 'Prioridad baja';

  @override
  String get labelFilePriorityMaximal => 'Prioridad máxima';

  @override
  String get labelFilePriorityNormal => 'Prioridad normal';

  @override
  String get labelFilterAllMovies => 'Todas las películas';

  @override
  String get labelFilterAllSeries => 'Todas las series';

  @override
  String get labelGrabbed => 'Capturado';

  @override
  String get labelHistoryDeletedGeneric => 'El archivo se eliminó.';

  @override
  String get labelHistoryDeletedManual =>
      'El archivo se eliminó manualmente o desde un cliente a través de la API.';

  @override
  String get labelHistoryDeletedMissingFromDisk =>
      'El archivo no se encontró en el disco, así que se desvinculó de la base de datos.';

  @override
  String get labelHistoryDeletedUpgrade =>
      'El archivo se eliminó para importar una mejora.';

  @override
  String get labelHistoryDownloadFailedDescription => 'La descarga falló.';

  @override
  String get labelHistoryDownloadIgnoredDescription => 'Descarga ignorada.';

  @override
  String labelHistoryEpisodeGrabbed(String indexer, String client) {
    return 'Episodio obtenido de $indexer y enviado a $client.';
  }

  @override
  String labelHistoryEpisodeImported(String client) {
    return 'Episodio descargado correctamente e importado desde $client.';
  }

  @override
  String get labelHistoryEpisodeRenamed =>
      'Se renombró el archivo del episodio.';

  @override
  String get labelHistoryFallbackClient => 'cliente de descarga';

  @override
  String get labelHistoryFallbackIndexer => 'indexador';

  @override
  String get labelHistoryIgnored => 'Ignorado';

  @override
  String get labelHistoryImported => 'Importado';

  @override
  String labelHistoryMovieGrabbed(String indexer, String client) {
    return 'Película obtenida de $indexer y enviada a $client.';
  }

  @override
  String labelHistoryMovieImported(String client) {
    return 'Película descargada correctamente e importada desde $client.';
  }

  @override
  String get labelHistoryMovieRenamed =>
      'Se renombró el archivo de la película.';

  @override
  String get labelHistoryRenamed => 'Renombrado';

  @override
  String get labelHistoryTitleDeleted => 'Archivo eliminado';

  @override
  String get labelHistoryTitleFailed => 'Descarga fallida';

  @override
  String get labelHistoryTitleGrabbed => 'Release capturado';

  @override
  String get labelHistoryTitleIgnored => 'Descarga ignorada';

  @override
  String get labelHistoryTitleImported => 'Carpeta importada';

  @override
  String get labelHistoryTitleRenamed => 'Archivo renombrado';

  @override
  String get labelHistoryTitleUnknown => 'Evento desconocido';

  @override
  String get labelHistoryUnknownEventDescription => 'Evento desconocido.';

  @override
  String get labelInCinemas => 'En cines';

  @override
  String get labelMissing => 'Ausente';

  @override
  String get labelMovieMonitorMovieAndCollection => 'Película + Colección';

  @override
  String get labelMovieMonitorMovieOnly => 'Película';

  @override
  String get labelMovieStateUnreleased => 'Sin estrenar';

  @override
  String get labelMovieStateUnwanted => 'No deseada';

  @override
  String get labelMovieStateWaiting => 'En espera';

  @override
  String get labelMovieStatusAnnounced => 'Anunciada';

  @override
  String get labelMovieStatusReleased => 'Estrenada';

  @override
  String get labelMovieStatusTba => 'No anunciada';

  @override
  String get labelNone => 'Ninguno';

  @override
  String get labelPaused => 'Pausado';

  @override
  String get labelPhysicalRelease => 'Estreno físico';

  @override
  String get labelQueueCompleted => 'Completado';

  @override
  String get labelQueuePending => 'Pendiente';

  @override
  String get labelQueueWarning => 'Advertencia';

  @override
  String get labelQueued => 'En cola';

  @override
  String get labelSeeding => 'Sembrando';

  @override
  String get labelSeriesMonitorAll => 'Todos los episodios';

  @override
  String get labelSeriesMonitorExisting => 'Episodios existentes';

  @override
  String get labelSeriesMonitorFirstSeason => 'Primera temporada';

  @override
  String get labelSeriesMonitorFuture => 'Episodios futuros';

  @override
  String get labelSeriesMonitorLastSeason => 'Última temporada';

  @override
  String get labelSeriesMonitorMissing => 'Episodios ausentes';

  @override
  String get labelSeriesMonitorPilot => 'Episodio piloto';

  @override
  String get labelSeriesMonitorRecent => 'Episodios recientes';

  @override
  String get labelSeriesMonitorSpecials => 'Monitorizar especiales';

  @override
  String get labelSeriesStatusContinuing => 'En emisión';

  @override
  String get labelSeriesStatusEnded => 'Finalizada';

  @override
  String get labelSeriesStatusUpcoming => 'Próximamente';

  @override
  String get labelSeriesTypeAnime => 'Anime';

  @override
  String get labelSeriesTypeDaily => 'Diaria';

  @override
  String get labelSeriesTypeStandard => 'Estándar';

  @override
  String get labelSeriesUnmonitorSpecials => 'No monitorizar especiales';

  @override
  String get labelSortAdded => 'Añadido';

  @override
  String get labelSortNextAiring => 'Próxima emisión';

  @override
  String get labelSortPreviousAiring => 'Emisión anterior';

  @override
  String get labelSortRating => 'Valoración';

  @override
  String get labelSortRuntime => 'Duración';

  @override
  String get labelSortTitle => 'Título';

  @override
  String get labelSortYear => 'Año';

  @override
  String get labelSpecials => 'Especiales';

  @override
  String get labelTabActivity => 'Actividad';

  @override
  String get labelTabCalendar => 'Calendario';

  @override
  String get labelTabSettings => 'Ajustes';

  @override
  String get labelTba => 'Por anunciar';

  @override
  String get labelTorrentChecking => 'Comprobando';

  @override
  String get labelTorrentLinkExternal => 'Fuera de la biblioteca';

  @override
  String get labelTorrentLinkExternalDescription =>
      'Este torrent se descargó fuera de la biblioteca multimedia.';

  @override
  String get labelTorrentLinkFileMissing => 'Archivo eliminado';

  @override
  String get labelTorrentLinkFileMissingDescription =>
      'El elemento del catálogo sigue existiendo, pero su archivo multimedia se eliminó.';

  @override
  String get labelTorrentLinkLinked => 'En la biblioteca';

  @override
  String get labelTorrentLinkLinkedDescription =>
      'Este torrent respalda un elemento que sigue en la biblioteca multimedia.';

  @override
  String get labelTorrentLinkOrphan => 'Huérfano';

  @override
  String get labelTorrentLinkOrphanDescription =>
      'Radarr/Sonarr descargó este torrent, pero el elemento del catálogo ya no existe. Solo queda el torrent.';

  @override
  String get labelTorrentLinkUnknownDescription =>
      'No se pudo determinar la relación con la biblioteca.';

  @override
  String get labelTorrentMissingFiles => 'Archivos ausentes';

  @override
  String get labelTorrentPausedDl => 'Pausado (DL)';

  @override
  String get labelTorrentPausedUp => 'Pausado (UP)';

  @override
  String get labelTorrentQueuedDl => 'En cola (DL)';

  @override
  String get labelTorrentQueuedUp => 'En cola (UP)';

  @override
  String get labelTorrentSortActivity => 'Actividad';

  @override
  String get labelTorrentSortAddedDate => 'Fecha de añadido';

  @override
  String get labelTorrentSortDownloadSpeed => 'Velocidad de descarga';

  @override
  String get labelTorrentSortName => 'Nombre';

  @override
  String get labelTorrentSortProgress => 'Progreso';

  @override
  String get labelTorrentSortRatio => 'Ratio';

  @override
  String get labelTorrentSortSeedTime => 'Tiempo sembrando';

  @override
  String get labelTorrentStalledDl => 'Detenido (DL)';

  @override
  String get labelTorrentStalledUp => 'Detenido (UP)';

  @override
  String get labelTrackerDisabled => 'Desactivado';

  @override
  String get labelTrackerNotContacted => 'Sin contactar';

  @override
  String get labelTrackerNotWorking => 'No funciona';

  @override
  String get labelTrackerUpdating => 'Actualizando';

  @override
  String get labelTrackerWorking => 'Funcionando';

  @override
  String get labelUnnamedFile => 'un archivo sin nombre';

  @override
  String get labelViewModeGrid => 'Cuadrícula';

  @override
  String get labelViewModeList => 'Lista';

  @override
  String get labelWanted => 'Deseado';

  @override
  String get languagePromptSubtitle => 'Puedes cambiarlo más tarde en Ajustes.';

  @override
  String get languagePromptTitle => 'Elige tu idioma';

  @override
  String get languageSystemDefault => 'Predeterminado del sistema';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsSelectLanguage => 'Seleccionar idioma';
}
