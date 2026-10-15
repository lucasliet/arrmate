// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get activityTabHistory => 'Historial';

  @override
  String get activityTabQueue => 'Cola';

  @override
  String get activityTabTorrents => 'Torrents';

  @override
  String get activityTabWatching => 'Viendo';

  @override
  String get appInitErrorTitle => 'Error de inicialización';

  @override
  String get appInitNotificationServicesFailed =>
      'No se pudieron iniciar los servicios de notificación. Algunas funciones pueden no funcionar correctamente.';

  @override
  String get appTitle => 'Arrmate';

  @override
  String get appleIntelligenceAssetsUnavailable =>
      'El modelo de Apple Intelligence aún no está listo. Inténtalo de nuevo más tarde.';

  @override
  String get appleIntelligenceBusy =>
      'Apple Intelligence está ocupado. Inténtalo de nuevo en un momento.';

  @override
  String get appleIntelligenceContextTooLong =>
      'La pregunta es demasiado larga para Apple Intelligence. Prueba con una más corta.';

  @override
  String get appleIntelligenceDeclined =>
      'Apple Intelligence se negó a responder. Prueba a reformular la pregunta.';

  @override
  String get appleIntelligenceDeviceNotEligible =>
      'Este dispositivo no es compatible con Apple Intelligence.';

  @override
  String get appleIntelligenceGenerationFailed =>
      'Apple Intelligence no pudo generar una respuesta.';

  @override
  String get appleIntelligenceModelNotReady =>
      'El modelo de Apple Intelligence aún se está descargando. Inténtalo de nuevo más tarde.';

  @override
  String get appleIntelligenceNotEnabled =>
      'Activa Apple Intelligence en los ajustes del sistema.';

  @override
  String get appleIntelligenceUnavailable =>
      'Apple Intelligence no está disponible en este dispositivo.';

  @override
  String get appleIntelligenceUnsupportedLanguage =>
      'Apple Intelligence no admite este idioma en este dispositivo.';

  @override
  String get appleIntelligenceUnsupportedOs =>
      'Apple Intelligence requiere iOS 26 o macOS 26.';

  @override
  String get assistantCloud => 'Cloud';

  @override
  String assistantDeleteModelContent(String model) {
    return '¿Quitar \"$model\" de tu dispositivo?';
  }

  @override
  String get assistantDeleteModelTitle => 'Eliminar modelo';

  @override
  String get assistantDownloadModel => 'Descargar modelo';

  @override
  String get assistantDownloadingModel => 'Descargando modelo';

  @override
  String get assistantEmptyPrompt => 'Pregunta sobre la app';

  @override
  String get assistantInputHint => 'Pregunta sobre Arrmate...';

  @override
  String get assistantInstalled => 'Instalado';

  @override
  String get assistantLinkNotOpened => 'No se pudo abrir el enlace';

  @override
  String get assistantLocalModels => 'Modelos locales';

  @override
  String get assistantNoLocalModel => 'Ningún modelo local seleccionado';

  @override
  String get assistantOnDeviceModel => 'Modelo en el dispositivo';

  @override
  String get assistantOnlineModel => 'Modelo en línea';

  @override
  String get assistantOnlyHttpsLinks => 'Solo se admiten enlaces HTTPS';

  @override
  String assistantOpenLinkFailed(String error) {
    return 'No se pudo abrir el enlace: $error';
  }

  @override
  String get assistantSelectModelFirst => 'Selecciona primero un modelo';

  @override
  String get assistantStartingDownload => 'Iniciando descarga...';

  @override
  String get assistantSwitchModel => 'Cambiar modelo';

  @override
  String get assistantTitle => 'Asistente';

  @override
  String get assistantUseCloud => 'Usa Cloud';

  @override
  String get assistantUseCloudOrLocal =>
      'Usa Cloud o importa/descarga un modelo local';

  @override
  String backupAppVersion(String version) {
    return 'Versión de la app: $version';
  }

  @override
  String get backupAutomaticNote =>
      'Las copias automáticas se hacen unos 30 segundos después de cambiar instancias o ajustes, mientras tengas la sesión iniciada. Algunos ajustes (como la pestaña de inicio) se aplican por completo tras reiniciar la app.';

  @override
  String backupCreated(String time) {
    return 'Creada: $time';
  }

  @override
  String get backupDriveDescription =>
      'Tus ajustes, preferencias e instancias configuradas (incluidas sus API Keys) se guardan en la carpeta privada de la app en tu Google Drive, invisible para otras apps.';

  @override
  String get backupDriveTitle => 'Copia de seguridad en Google Drive';

  @override
  String get backupDriveUnavailableMessage =>
      'Esta versión se compiló sin credenciales de Google. Pide al desarrollador que compile con la configuración de Google OAuth o ejecútala localmente con los flags --dart-define. Usa la copia en archivo local de abajo.';

  @override
  String get backupDriveUnavailableTitle =>
      'Copia de seguridad en Google Drive no disponible';

  @override
  String get backupExportToFile => 'Exportar copia a un archivo';

  @override
  String get backupExportToFileSubtitle =>
      'Guardar una copia .json en este dispositivo';

  @override
  String backupExported(String fileName) {
    return 'Copia exportada a $fileName';
  }

  @override
  String backupFoundMessage(String time) {
    return 'Guardada el $time. Restáurala para traer sus ajustes e instancias a este dispositivo. Las copias automáticas quedan en pausa hasta que restaures o hagas una copia manual.';
  }

  @override
  String get backupFoundTitle =>
      'Copia de seguridad encontrada en tu Google Drive';

  @override
  String backupInstanceCount(int count) {
    return 'Instancias: $count';
  }

  @override
  String backupLastBackup(String time) {
    return 'Última copia: $time';
  }

  @override
  String get backupNever => 'nunca';

  @override
  String get backupNow => 'Hacer copia ahora';

  @override
  String backupPlatform(String platform) {
    return 'Plataforma: $platform';
  }

  @override
  String get backupRestoreBackupMenu => 'Restaurar copia…';

  @override
  String get backupRestoreConfirmTitle => '¿Restaurar copia?';

  @override
  String get backupRestoreFailed => 'Error al restaurar';

  @override
  String get backupRestoreFromFile => 'Restaurar desde archivo…';

  @override
  String get backupRestoreReplaceWarning =>
      'Esto reemplaza los ajustes e instancias actuales de este dispositivo.';

  @override
  String get backupRestored => 'Copia restaurada';

  @override
  String get backupSignInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get backupSignOut => 'Cerrar sesión';

  @override
  String get backupTitle => 'Copia de seguridad y restauración';

  @override
  String get calendarAnyInstance => 'Cualquier instancia';

  @override
  String get calendarDataLoadFailed =>
      'No se pudieron cargar los datos del calendario.';

  @override
  String get calendarFilterByInstance => 'Filtrar por instancia';

  @override
  String get calendarFilterByMediaType => 'Filtrar por tipo de contenido';

  @override
  String get calendarHideSpecials => 'Ocultar especiales';

  @override
  String get calendarInstanceAny => 'Instancia: cualquiera';

  @override
  String calendarInstanceNamed(String name) {
    return 'Instancia: $name';
  }

  @override
  String get calendarLoadMore => 'Cargar más';

  @override
  String get calendarLoading => 'Cargando calendario...';

  @override
  String get calendarNoMatchingEvents => 'No hay eventos que coincidan';

  @override
  String get calendarNoMatchingEventsHint =>
      'Ajusta los filtros del calendario para ver más eventos.';

  @override
  String get calendarNoUpcomingEvents => 'No hay próximos eventos';

  @override
  String get calendarNoUpcomingEventsHint =>
      'Vuelve más tarde o añade contenido a tus bibliotecas.';

  @override
  String calendarOpenItemFailed(String error) {
    return 'No se pudo abrir el elemento: $error';
  }

  @override
  String get calendarPremieres => 'Estrenos';

  @override
  String get calendarToday => 'Hoy';

  @override
  String get calendarTomorrow => 'Mañana';

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
  String coreGoogleSignInAccountLoadFailed(String status) {
    return 'Error al iniciar sesión en Google: no se pudo cargar la cuenta (estado $status).';
  }

  @override
  String get coreGoogleSignInBrowserFailed =>
      'No se pudo abrir el navegador de inicio de sesión. Inténtalo de nuevo.';

  @override
  String get coreGoogleSignInCancelled =>
      'El inicio de sesión en Google se canceló antes de terminar.';

  @override
  String get coreGoogleSignInConsentDenied =>
      'El inicio de sesión en Google se canceló: se denegó el consentimiento.';

  @override
  String get coreGoogleSignInIncompleteToken =>
      'Error al iniciar sesión en Google: la respuesta del token estaba incompleta.';

  @override
  String coreGoogleSignInNetworkError(String status) {
    return 'Error al iniciar sesión en Google: error de red o del servidor (estado $status).';
  }

  @override
  String get coreGoogleSignInNoCode =>
      'Error al iniciar sesión en Google: no se devolvió ningún código de autorización.';

  @override
  String get coreGoogleSignInNoEmail =>
      'Error al iniciar sesión en Google: la cuenta no tiene correo electrónico.';

  @override
  String coreGoogleSignInProviderError(String reason) {
    return 'Error al iniciar sesión en Google: $reason';
  }

  @override
  String get coreGoogleSignInRedirectUnverified =>
      'Error al iniciar sesión en Google: no se pudo verificar la redirección.';

  @override
  String coreGoogleSignInServerStatus(String status) {
    return 'Error al iniciar sesión en Google: el servidor devolvió el estado $status.';
  }

  @override
  String get coreGoogleSignInStatusUnavailable => 'no disponible';

  @override
  String get coreGoogleSignInTimedOut =>
      'El inicio de sesión en Google ha caducado. Inténtalo de nuevo.';

  @override
  String get coreGoogleSignInUnavailableOnWeb =>
      'El inicio de sesión de Google no está disponible en la web.';

  @override
  String get corePurgeNotificationTitle => 'Torrent purgado';

  @override
  String corePurgeNotificationTitleSeason(int season) {
    return 'Torrent purgado (temporada $season)';
  }

  @override
  String corePurgeSummaryMediaFiles(int count) {
    return 'Archivos multimedia: $count';
  }

  @override
  String get corePurgeSummaryQbittorrentSkipped =>
      'qBittorrent omitido — configura una instancia de qBittorrent.';

  @override
  String corePurgeSummaryQueueItems(int count) {
    return 'Elementos de la cola: $count';
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
      'Faltan archivos obligatorios de la aplicación en el archivo de la actualización.';

  @override
  String get coreUpdateArchiveTooLarge =>
      'El archivo de la actualización supera los límites de extracción.';

  @override
  String get coreUpdateArchiveUnsafeLink =>
      'El archivo de la actualización contiene un enlace simbólico no seguro.';

  @override
  String get coreUpdateArchiveUnsafePath =>
      'El archivo de la actualización contiene una ruta no segura.';

  @override
  String get coreUpdateArchiveWritesThroughLink =>
      'El archivo de la actualización escribe a través de un enlace simbólico.';

  @override
  String get coreUpdateCheckFailed =>
      'No se pudieron buscar actualizaciones. Inténtalo de nuevo.';

  @override
  String get coreUpdateInstallerNotStarted =>
      'No se pudo iniciar el instalador de la actualización. La app no se ha modificado.';

  @override
  String get coreUpdateLinuxRequiresAppImage =>
      'Las actualizaciones automáticas en Linux requieren el AppImage. Descarga y ejecuta primero la versión AppImage.';

  @override
  String get coreUpdateMacBundleRequired =>
      'Ejecuta el paquete Arrmate.app instalado para actualizarlo.';

  @override
  String get coreUpdateNotAppImage => 'La actualización no es un AppImage x64.';

  @override
  String coreUpdateOtaFailed(String status) {
    return 'Error en la actualización: $status';
  }

  @override
  String coreUpdatePrepareFailed(String tool) {
    return 'No se pudo preparar el paquete de actualización ($tool).';
  }

  @override
  String get coreUpdateReadOnlyFolder =>
      'La carpeta de la aplicación es de solo lectura. Mueve Arrmate a una carpeta en la que tu usuario pueda escribir e inténtalo de nuevo.';

  @override
  String get coreUpdateUnverifiedPackage =>
      'La versión no contiene un paquete verificado para esta plataforma.';

  @override
  String get coreUpdateVerificationFailed =>
      'La actualización no superó la verificación de tamaño o SHA-256.';

  @override
  String get coreUpdateVersionMismatch =>
      'La versión de la aplicación descargada no coincide con la publicada.';

  @override
  String get coreUpdateWindowsIncomplete =>
      'Ejecuta Arrmate desde la carpeta completa de la versión para Windows para actualizarlo.';

  @override
  String diagnosticsCheckFailed(String error) {
    return 'Falló · $error';
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
  String get diagnosticsChecking => 'Comprobando endpoints configurados...';

  @override
  String get diagnosticsEndpointActive => 'Endpoint activo';

  @override
  String get diagnosticsEndpointAlternative => 'Endpoint alternativo';

  @override
  String get diagnosticsEndpointAlternativeActive =>
      'Endpoint alternativo · Activo';

  @override
  String get diagnosticsEndpointConnectivity => 'Conectividad de endpoints';

  @override
  String get diagnosticsEndpointPrimary => 'Endpoint principal';

  @override
  String get diagnosticsEndpointPrimaryActive => 'Endpoint principal · Activo';

  @override
  String get diagnosticsEndpointsAvailable => 'Endpoints disponibles';

  @override
  String get diagnosticsEndpointsUnavailable => 'Endpoints no disponibles';

  @override
  String diagnosticsExportFailed(String error) {
    return 'Error al exportar el informe: $error';
  }

  @override
  String get diagnosticsExportReport => 'Exportar informe';

  @override
  String diagnosticsGenerated(String date) {
    return 'Generado el $date';
  }

  @override
  String diagnosticsInterfaces(String interfaces) {
    return 'Interfaces: $interfaces';
  }

  @override
  String get diagnosticsNetworkAvailable => 'Red disponible';

  @override
  String get diagnosticsNoInstances =>
      'No hay instancias de Radarr, Sonarr o qBittorrent configuradas.';

  @override
  String get diagnosticsNoNetworkInterface => 'Sin interfaz de red';

  @override
  String get diagnosticsNoRecentRequests =>
      'No hay solicitudes recientes registradas.';

  @override
  String get diagnosticsPurposeBody =>
      'Comprueba la disponibilidad y la latencia de cada endpoint configurado, muestra las trazas de solicitudes recientes y exporta un informe sin datos sensibles. Salud muestra las alertas reportadas por Radarr y Sonarr.';

  @override
  String get diagnosticsPurposeTitle => 'Solución de problemas de conexión';

  @override
  String get diagnosticsRecentRequests => 'Trazas de solicitudes recientes';

  @override
  String get diagnosticsRefreshing =>
      'Actualizando comprobaciones de endpoints...';

  @override
  String get diagnosticsRunAgain =>
      'Volver a ejecutar las comprobaciones de conexión';

  @override
  String diagnosticsRunFailed(String error) {
    return 'Error al ejecutar el diagnóstico de conexión: $error';
  }

  @override
  String get diagnosticsSomeEndpointsUnavailable =>
      'Algunos endpoints no disponibles';

  @override
  String get diagnosticsTitle => 'Diagnóstico de conexión';

  @override
  String get diagnosticsUnknownError => 'error desconocido';

  @override
  String get diagnosticsUnknownStatus => 'desconocido';

  @override
  String get discoveryConfigureAddition => 'Configurar adición';

  @override
  String get discoveryHideAlreadyAdded => 'Ocultar ya añadidos';

  @override
  String discoveryLoadFoldersFailed(String error) {
    return 'Error al cargar las carpetas: $error';
  }

  @override
  String discoveryLoadProfilesFailed(String error) {
    return 'Error al cargar los perfiles: $error';
  }

  @override
  String get discoveryNoOverview => 'No hay sinopsis disponible.';

  @override
  String get discoveryNoRating => 'Sin valoración';

  @override
  String get discoveryNoResultsFound => 'No se encontraron resultados';

  @override
  String discoveryRootFolderFreeSpace(String path, String free) {
    return '$path ($free GB libres)';
  }

  @override
  String discoveryRuntimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get discoverySearchPrompt =>
      'Busca por título, ID del proveedor o URL';

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
  String healthCheckCouldNotStart(String service) {
    return 'No se pudo iniciar la comprobación de $service';
  }

  @override
  String healthConnectionFailed(String service) {
    return 'Falló la conexión con $service';
  }

  @override
  String get healthConnectionIssues => 'Problemas de conexión';

  @override
  String get healthLoadFailed => 'Error al cargar el estado de salud';

  @override
  String get healthLoadFailureSubtitle =>
      'No se pudo cargar la salud del servidor. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get healthNoInstancesSubtitle =>
      'Añade una instancia de Radarr o Sonarr para ver la salud del servidor.';

  @override
  String get healthNoIssuesSubtitle =>
      'Los servidores conectados no reportaron avisos de salud.';

  @override
  String get healthNoIssuesTitle =>
      'No se encontraron problemas en el servidor';

  @override
  String get healthRunCheck => 'Ejecutar comprobación de salud';

  @override
  String get healthRunFailureSubtitle =>
      'Abajo se muestra el último estado disponible del servidor.';

  @override
  String get healthServerWarnings => 'Avisos del servidor';

  @override
  String get healthTitle => 'Salud del sistema';

  @override
  String healthWiki(String url) {
    return 'Wiki: $url';
  }

  @override
  String get historyAllEvents => 'Todos los eventos';

  @override
  String get historyAllInstances => 'Todas las instancias';

  @override
  String get historyDetailDate => 'Fecha';

  @override
  String get historyDetailScore => 'Puntuación';

  @override
  String get historyEmpty => 'No hay eventos en el historial';

  @override
  String get historyLoadFailed =>
      'No se pudieron cargar los datos del historial.';

  @override
  String get historyLoadMore => 'Cargar más';

  @override
  String get instanceAddBasicAuth => 'Añadir Basic Auth';

  @override
  String get instanceAddHeader => 'Añadir encabezado';

  @override
  String get instanceAdvancedSettings => 'Ajustes avanzados';

  @override
  String get instanceAdvancedSettingsSubtitle =>
      'Encabezados personalizados y autenticación';

  @override
  String get instanceAlternativeUrl => 'URL alternativa';

  @override
  String get instanceAlternativeUrlHelper =>
      'URL opcional usada fuera de tu red local';

  @override
  String get instanceAlternativeUrlSameAsPrimary =>
      'Debe ser distinta de la URL principal';

  @override
  String get instanceApiKeyOrBasicAuthRequired =>
      'Introduce una API Key o añade Basic Auth abajo';

  @override
  String get instanceApiKeySessionExpiredValidation =>
      'Añade Basic Auth abajo para volver a iniciar sesión o introduce una API Key';

  @override
  String get instanceAuthCustomHeader => 'Encabezado personalizado';

  @override
  String get instanceAuthUsernamePassword => 'Usuario y contraseña';

  @override
  String get instanceBasicAuthBase64Note =>
      'Las credenciales se codificarán en Base64.';

  @override
  String get instanceBasicAuthTitle => 'Autenticación básica';

  @override
  String instanceDeleteFailed(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get instanceDeleteJellyfinWarning =>
      'Arrmate también eliminará su conexión de Jellyfin de Radarr/Sonarr, revocará la API Key de Arrmate que creó y cerrará la sesión en Jellyfin. Esta acción no se puede deshacer.';

  @override
  String get instanceDeleteTitle => '¿Eliminar instancia?';

  @override
  String get instanceDeleteWarning => 'Esta acción no se puede deshacer.';

  @override
  String get instanceEditTitle => 'Editar instancia';

  @override
  String instanceErrorHttpStatus(String status) {
    return 'El servidor respondió con HTTP $status.';
  }

  @override
  String get instanceErrorTimeout =>
      'El servidor tardó demasiado en responder. Inténtalo de nuevo o activa el Modo de instancia lenta.';

  @override
  String get instanceErrorUnreachable =>
      'Servidor inaccesible. Revisa la URL y tu red.';

  @override
  String get instanceGoBack => 'Volver';

  @override
  String get instanceHeaderName => 'Nombre del encabezado';

  @override
  String get instanceHeaderValue => 'Valor del encabezado';

  @override
  String get instanceHideApiKey => 'Ocultar API Key';

  @override
  String get instanceJellyfinFallbackUser => 'un usuario de Jellyfin';

  @override
  String get instanceJellyfinHelperDefault =>
      'API Key (panel de Jellyfin → Avanzado → Claves de API). Déjalo vacío si usas \"Añadir Basic Auth\" abajo para iniciar sesión con usuario y contraseña.';

  @override
  String get instanceJellyfinHelperSessionExpired =>
      'Sesión caducada — añade Basic Auth abajo para volver a iniciar sesión o introduce una API Key';

  @override
  String instanceJellyfinHelperSignedIn(String user) {
    return 'Sesión iniciada como $user. Déjalo vacío para mantener la sesión, introduce una API Key para cambiar o añade Basic Auth abajo para volver a iniciar sesión.';
  }

  @override
  String get instanceJellyfinSessionExpiredBanner =>
      'Tu sesión de Jellyfin ha caducado. Añade Basic Auth en Ajustes avanzados con tu usuario y contraseña para volver a iniciar sesión.';

  @override
  String get instanceLibraryAutoUpdateSetupTitle =>
      'Configuración de actualización automática de la biblioteca';

  @override
  String get instanceNameHint => 'p. ej. Servidor de casa';

  @override
  String get instanceNameLabel => 'Nombre';

  @override
  String get instanceNotFoundMessage =>
      'La instancia solicitada ya no existe o no se pudo cargar.';

  @override
  String get instanceNotFoundTitle => 'Instancia no encontrada';

  @override
  String get instancePassword => 'Contraseña';

  @override
  String get instanceQbittorrentApiKeyHelper =>
      'Token Bearer (qBittorrent ≥ v5.2.0). Déjalo vacío si usas \"Añadir Basic Auth\" abajo para versiones anteriores.';

  @override
  String instanceRemovedCleanupFailed(String failures) {
    return 'Instancia eliminada, pero parte de la limpieza falló:\n$failures';
  }

  @override
  String get instanceRequired => 'Obligatorio';

  @override
  String get instanceSave => 'Guardar instancia';

  @override
  String get instanceSetUpLibraryAutoUpdate =>
      'Configurar actualización automática de la biblioteca';

  @override
  String instanceSetupFailed(String error) {
    return 'Error de configuración: $error';
  }

  @override
  String get instanceShowApiKey => 'Mostrar API Key';

  @override
  String get instanceSlowMode => 'Modo de instancia lenta';

  @override
  String get instanceSlowModeSubtitle =>
      'Aumenta los tiempos de espera para conexiones lentas';

  @override
  String get instanceTestConnection => 'Probar conexión';

  @override
  String instanceTestSuccessArr(String version, String name, int count) {
    return '¡Conexión correcta!\nVersión: $version\nInstancia: $name\nEtiquetas: $count disponibles';
  }

  @override
  String instanceTestSuccessQbittorrent(String auth, int count) {
    return '¡Conexión correcta!\nAutenticación: $auth\nTorrents: $count';
  }

  @override
  String get instanceUrlHelper => 'Incluye http:// o https:// y el puerto';

  @override
  String get instanceUrlInvalid => 'Debe ser una URL HTTP o HTTPS válida';

  @override
  String get instanceUsername => 'Usuario';

  @override
  String instanceValidationFailed(String error) {
    return 'Error de validación: $error';
  }

  @override
  String get jellyfinSetupApiKeyRequired =>
      'Se necesita una API Key de Jellyfin para actualizar la biblioteca automáticamente: introduce una API Key en el campo o inicia sesión con una cuenta de administrador (Basic Auth)';

  @override
  String get jellyfinSetupNoConnection =>
      'No hay ninguna conexión de Jellyfin configurada en Arrmate.';

  @override
  String jellyfinSetupNotArrInstance(String name) {
    return '$name no es una instancia de Radarr ni de Sonarr.';
  }

  @override
  String jellyfinSetupRemoveConnectorFailed(String name, String error) {
    return 'No se pudo quitar la conexión de Jellyfin de $name: $error';
  }

  @override
  String jellyfinSetupRevokeKeyFailed(String error) {
    return 'No se pudo revocar la API Key de Arrmate en Jellyfin: $error';
  }

  @override
  String jellyfinSetupSignOutFailed(String error) {
    return 'No se pudo cerrar la sesión de Jellyfin: $error';
  }

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
  String get logsAllCopied => 'Todos los registros copiados al portapapeles';

  @override
  String get logsAppLogsCleared => 'Registros de la app borrados';

  @override
  String get logsClearAppLogs => 'Borrar registros de la app';

  @override
  String get logsCopyAllVisible => 'Copiar todos los registros visibles';

  @override
  String get logsDetailException => 'Excepción/Error:';

  @override
  String get logsDetailLevel => 'Nivel';

  @override
  String get logsDetailLogger => 'Logger';

  @override
  String get logsDetailMessage => 'Mensaje:';

  @override
  String get logsDetailTime => 'Hora';

  @override
  String get logsDetailTitle => 'Detalle del registro';

  @override
  String get logsLevelDebug => 'Depuración';

  @override
  String get logsLevelInfo => 'Info';

  @override
  String get logsLevelWarn => 'Aviso';

  @override
  String get logsLogCopied => 'Registro copiado';

  @override
  String get logsNoAppLogsMatchingFilter =>
      'No se encontraron registros de la app para el filtro';

  @override
  String get logsNoLogsMatchingFilter =>
      'No se encontraron registros para el filtro';

  @override
  String get logsSource => 'Origen de los registros';

  @override
  String get logsTabApp => 'Registros de la app';

  @override
  String get logsTabArr => 'Registros ARR';

  @override
  String get logsTitle => 'Registros del sistema';

  @override
  String get manualImportEmptySubtitle =>
      'No hay archivos disponibles para la importación manual.';

  @override
  String get manualImportEmptyTitle => 'No hay archivos importables';

  @override
  String manualImportFailed(String error) {
    return 'No se pudo importar: $error';
  }

  @override
  String manualImportIssueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count con problemas',
    );
    return '$_temp0';
  }

  @override
  String get manualImportLoadFailed =>
      'No se pudieron cargar los archivos importables';

  @override
  String get manualImportLoading => 'Cargando archivos importables...';

  @override
  String get manualImportNoFilesSelected => 'No hay archivos seleccionados';

  @override
  String manualImportSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos seleccionados',
      one: '1 archivo seleccionado',
    );
    return '$_temp0';
  }

  @override
  String manualImportSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos importados correctamente',
      one: '1 archivo importado correctamente',
    );
    return '$_temp0';
  }

  @override
  String get manualImportTitle => 'Importación manual';

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
    return 'Error al añadir la película: $error';
  }

  @override
  String get moviesAddMissingSelection =>
      'Selecciona una película, un perfil de calidad y una carpeta raíz';

  @override
  String get moviesAddMovieButton => 'Añadir película';

  @override
  String get moviesAddMovieTitle => 'Añadir película';

  @override
  String get moviesAddedSuccessfully => 'Película añadida correctamente';

  @override
  String get moviesAllFolders => 'Todas las carpetas';

  @override
  String get moviesAlsoDeleteFiles => 'Eliminar también los archivos del disco';

  @override
  String moviesDeleteFailed(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get moviesDeleteFileConfirm =>
      '¿Seguro que quieres eliminar este archivo? Esta acción no se puede deshacer.';

  @override
  String get moviesDeleteFileTitle => 'Eliminar archivo';

  @override
  String moviesDeleteFilesConfirm(String title) {
    return '¿Eliminar todos los archivos de \"$title\"? Esto borra el archivo de la película del disco; la película sigue en Radarr.';
  }

  @override
  String moviesDeleteFilesFailed(String error) {
    return 'Error al eliminar archivos: $error';
  }

  @override
  String moviesDeleteMovieConfirm(String title) {
    return '¿Seguro que quieres eliminar \"$title\"?';
  }

  @override
  String get moviesDeleteMovieTitle => 'Eliminar película';

  @override
  String get moviesDeleted => 'Película eliminada';

  @override
  String moviesDeletedFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos eliminados',
      one: '1 archivo eliminado',
    );
    return '$_temp0';
  }

  @override
  String get moviesDeletedWithFiles => 'Película y archivos eliminados';

  @override
  String get moviesEditTitle => 'Editar película';

  @override
  String get moviesEmptyFilteredSubtitle =>
      'Prueba a borrar o ajustar tu búsqueda o tus filtros.';

  @override
  String get moviesEmptySubtitle =>
      'Añade películas a tu biblioteca de Radarr para verlas aquí.';

  @override
  String get moviesEmptyTitle => 'No se encontraron películas';

  @override
  String get moviesFileDeleted => 'Archivo eliminado';

  @override
  String get moviesFilesSection => 'Archivos';

  @override
  String get moviesHistorySection => 'Historial';

  @override
  String get moviesInfoPath => 'Ruta';

  @override
  String get moviesInfoStudio => 'Estudio';

  @override
  String get moviesLoadFilesFailed => 'Error al cargar los archivos';

  @override
  String get moviesLoadHistoryFailed => 'Error al cargar el historial';

  @override
  String get moviesLoading => 'Cargando películas...';

  @override
  String get moviesLoadingDetails => 'Cargando detalles...';

  @override
  String get moviesMinimumAvailability => 'Disponibilidad mínima';

  @override
  String moviesMoveFilesConfirm(String path) {
    return '¿Quieres mover los archivos a \"$path\"?';
  }

  @override
  String get moviesMoveFilesTitle => '¿Mover archivos?';

  @override
  String get moviesNoFilesToDelete => 'No hay archivos para eliminar';

  @override
  String get moviesNoHistoryEvents => 'No hay eventos en el historial';

  @override
  String get moviesNoMediaFiles => 'No hay archivos multimedia';

  @override
  String moviesOpenLinkFailed(String error) {
    return 'No se pudo abrir el enlace: $error';
  }

  @override
  String get moviesOverview => 'Sinopsis';

  @override
  String get moviesPreventReAdd =>
      'Evitar que esta película se vuelva a añadir';

  @override
  String get moviesPreviewTitle => 'Vista previa de la película';

  @override
  String moviesPurgeConfirm(String title) {
    return 'Esto eliminará permanentemente \"$title\" de Radarr, borrará sus archivos multimedia y eliminará todos los torrents de origen (incluidos los duplicados Cross-seed) de qBittorrent. Libera el espacio en disco usado por datos con hardlink.';
  }

  @override
  String moviesPurgeFailed(String error) {
    return 'Error al purgar: $error';
  }

  @override
  String moviesPurgePreviewFailed(String error) {
    return 'Error al previsualizar: $error';
  }

  @override
  String get moviesPurgeTitle => 'Purgar película';

  @override
  String get moviesPurged => 'Película purgada.';

  @override
  String get moviesRefreshAndScan => 'Actualizar y escanear';

  @override
  String get moviesRefreshAndScanTriggered =>
      'Actualización y escaneo iniciados';

  @override
  String get moviesRootFolderHelper =>
      'Cambiar esto moverá los archivos si lo confirmas';

  @override
  String get moviesSearchHint => 'Buscar películas...';

  @override
  String moviesSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionados',
      one: '1 seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get moviesSortAndFilter => 'Ordenar y filtrar';

  @override
  String get moviesSwitchToGrid => 'Cambiar a cuadrícula';

  @override
  String get moviesSwitchToList => 'Cambiar a lista';

  @override
  String get moviesTrailer => 'Tráiler';

  @override
  String moviesUpdateFailed(String error) {
    return 'Error al actualizar la película: $error';
  }

  @override
  String get moviesUpdated => 'Película actualizada';

  @override
  String moviesViewPoster(String title) {
    return 'Ver póster de $title';
  }

  @override
  String get notificationSettingsArrUpdate => 'Actualización de instancia *arr';

  @override
  String get notificationSettingsArrUpdateSubtitle =>
      'Cuando se actualiza el servidor de Radarr/Sonarr';

  @override
  String get notificationSettingsAutoConfigure =>
      'Configurar instancias *arr automáticamente';

  @override
  String get notificationSettingsAutoConfiguring =>
      'Configurando notificaciones automáticamente...';

  @override
  String notificationSettingsConfiguredCount(int success, int total) {
    return '$success/$total instancias configuradas.';
  }

  @override
  String get notificationSettingsConnected => 'Conectado a ntfy.sh';

  @override
  String get notificationSettingsCopyTopic => 'Copiar tema';

  @override
  String get notificationSettingsDisconnected => 'Desconectado';

  @override
  String get notificationSettingsDownloads => 'Descargas';

  @override
  String get notificationSettingsEnable => 'Activar notificaciones';

  @override
  String get notificationSettingsFailure => 'Notificar fallos';

  @override
  String get notificationSettingsFailureSubtitle =>
      'Cuando una descarga no se puede importar';

  @override
  String get notificationSettingsFileDeleted => 'Archivo eliminado';

  @override
  String get notificationSettingsFileDeletedSubtitle =>
      'Cuando se elimina un archivo multimedia';

  @override
  String get notificationSettingsGrab => 'Notificar al capturar';

  @override
  String get notificationSettingsGrabSubtitle =>
      'Cuando un release se envía al cliente de descargas';

  @override
  String get notificationSettingsHealthIssues => 'Problemas de salud';

  @override
  String get notificationSettingsHealthIssuesSubtitle =>
      'Cuando se detectan problemas de salud del sistema';

  @override
  String get notificationSettingsHealthRestored => 'Salud restablecida';

  @override
  String get notificationSettingsHealthRestoredSubtitle =>
      'Cuando se resuelve un problema de salud';

  @override
  String get notificationSettingsImport => 'Notificar al importar';

  @override
  String get notificationSettingsImportSubtitle =>
      'Cuando un archivo se importa correctamente';

  @override
  String get notificationSettingsInAppBody =>
      'Las notificaciones llegan en tiempo real mientras la app está abierta. Al cerrar la app, las nuevas notificaciones se obtendrán la próxima vez que la abras.';

  @override
  String get notificationSettingsInAppTitle => 'Notificaciones en la app';

  @override
  String get notificationSettingsIncludeWarnings => 'Incluir avisos';

  @override
  String get notificationSettingsIncludeWarningsSubtitle =>
      'Notificar también avisos de salud';

  @override
  String get notificationSettingsManualInteraction => 'Interacción manual';

  @override
  String get notificationSettingsManualInteractionSubtitle =>
      'Cuando se requiere intervención manual';

  @override
  String get notificationSettingsManualSetup => 'O CONFIGURACIÓN MANUAL';

  @override
  String get notificationSettingsManualStep1 => '1. Ve a Settings > Connect';

  @override
  String get notificationSettingsManualStep2 =>
      '2. Añade una nueva conexión > ntfy';

  @override
  String get notificationSettingsManualStep3 => '3. Configura:';

  @override
  String get notificationSettingsMediaAdded => 'Película/serie añadida';

  @override
  String get notificationSettingsMediaAddedSubtitle =>
      'Cuando se añade una película o serie';

  @override
  String get notificationSettingsMediaDeleted => 'Película/serie eliminada';

  @override
  String get notificationSettingsMediaDeletedSubtitle =>
      'Cuando se elimina una película o serie';

  @override
  String get notificationSettingsMediaUpdates => 'Actualizaciones de contenido';

  @override
  String get notificationSettingsNtfyDocs => 'Documentación de ntfy';

  @override
  String get notificationSettingsServerUrl => 'URL del servidor';

  @override
  String get notificationSettingsSetupInArr => 'Configuración en Radarr/Sonarr';

  @override
  String get notificationSettingsSetupResults =>
      'Resultados de la configuración';

  @override
  String get notificationSettingsSetupSubtitle =>
      'Toca para generar tu tema único';

  @override
  String get notificationSettingsSetupTitle => 'Configurar notificaciones';

  @override
  String get notificationSettingsTopic => 'Tema';

  @override
  String get notificationSettingsTopicCopied => 'Tema copiado al portapapeles';

  @override
  String notificationSettingsUnexpectedError(String error) {
    return 'Error inesperado: $error';
  }

  @override
  String get notificationSettingsYourTopic => 'Tu tema';

  @override
  String notificationSetupConfigured(String name) {
    return '$name configurado correctamente.';
  }

  @override
  String notificationSetupFailed(String name, String error) {
    return 'No se pudo configurar $name: $error';
  }

  @override
  String get notificationSetupNoTopic =>
      'No hay ningún tema de ntfy configurado en Arrmate.';

  @override
  String notificationSetupUpdated(String name) {
    return '$name actualizado correctamente.';
  }

  @override
  String get notificationsAllCleared => 'Se borraron todas las notificaciones';

  @override
  String get notificationsAllMarkedRead =>
      'Todas las notificaciones se marcaron como leídas';

  @override
  String get notificationsClearAll => 'Borrar todo';

  @override
  String get notificationsClearAllConfirm =>
      'Esto eliminará todas las notificaciones. Esta acción no se puede deshacer.';

  @override
  String get notificationsClearAllTitle => '¿Borrar todas las notificaciones?';

  @override
  String get notificationsDismissed => 'Notificación descartada';

  @override
  String get notificationsEmptySubtitle =>
      'Cuando recibas notificaciones de Radarr o Sonarr, aparecerán aquí.';

  @override
  String get notificationsEmptyTitle => 'No hay notificaciones';

  @override
  String get notificationsMarkAllRead => 'Marcar todas como leídas';

  @override
  String get notificationsNewBadge => 'NUEVA';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get playbackLoadMovieFileFailed =>
      'No se pudo cargar el archivo de la película';

  @override
  String get playbackNoEpisodeFile =>
      'No se encontró ningún archivo reproducible para este episodio';

  @override
  String get playbackNoJellyfin =>
      'No hay ningún servidor Jellyfin configurado';

  @override
  String get playbackNoMovieFile =>
      'No se encontró ningún archivo reproducible para esta película';

  @override
  String get playbackNotFound => 'No se encontró este contenido en Jellyfin';

  @override
  String get playbackSearchingLibrary =>
      'Buscando en la biblioteca de Jellyfin…';

  @override
  String get playbackSessionExpired =>
      'Tu sesión de Jellyfin ha caducado. Vuelve a iniciar sesión.';

  @override
  String get playbackSignIn => 'Iniciar sesión';

  @override
  String playbackStartFailed(String error) {
    return 'No se pudo iniciar la reproducción: $error';
  }

  @override
  String playbackTrackLabel(int index) {
    return 'Pista $index';
  }

  @override
  String get playerAudio => 'Audio';

  @override
  String get playerBack => 'Volver';

  @override
  String get playerExternalOpenFailed =>
      'No se pudo abrir un reproductor externo';

  @override
  String get playerExternalUnavailable =>
      'Abrir este contenido en un reproductor externo no está disponible con la configuración actual del servidor.';

  @override
  String get playerNoMediaRequested =>
      'No se solicitó ningún contenido para reproducir.';

  @override
  String get playerQualityDataSaver => 'Ahorro de datos';

  @override
  String get playerQualityOriginal => 'Original';

  @override
  String playerQualityTooltip(String quality) {
    return 'Calidad: $quality';
  }

  @override
  String get playerStartFailed =>
      'No se pudo iniciar la reproducción. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get playerSubtitleExternal => 'Externo';

  @override
  String get playerSubtitlesDisabled => 'Desactivados';

  @override
  String get playerTitle => 'Reproductor';

  @override
  String get playerUnexpectedFailure =>
      'La reproducción falló de forma inesperada.';

  @override
  String get playerUnsupportedOnWeb =>
      'La reproducción en la app aún no es compatible con la web';

  @override
  String get providerAssistantDeleteFailed => 'No se pudo eliminar el modelo.';

  @override
  String providerAssistantDownloadFailed(String error) {
    return 'No se pudo descargar el modelo: $error';
  }

  @override
  String get providerAssistantEnableOnlineFailed =>
      'No se pudo activar el modelo en línea.';

  @override
  String get providerAssistantGenerateFailed =>
      'No se pudo generar una respuesta.';

  @override
  String get providerAssistantImportFailed => 'No se pudo importar el modelo.';

  @override
  String get providerAssistantInitFailed =>
      'No se pudieron inicializar los recursos del asistente.';

  @override
  String get providerAssistantLoadModelFailed =>
      'No se pudo cargar el modelo seleccionado.';

  @override
  String get providerAssistantModelNotFound => 'Modelo no encontrado.';

  @override
  String get providerAssistantNoToolCalling =>
      'Este modelo no admite tool-calling. Usa un modelo Gemma.';

  @override
  String get providerAssistantRefreshModelsFailed =>
      'No se pudieron actualizar los modelos instalados.';

  @override
  String get providerAssistantSelectModelFirst =>
      'Selecciona un modelo antes de chatear.';

  @override
  String get providerBackupCompleted => 'Copia de seguridad completada.';

  @override
  String get providerBackupCorrupt =>
      'El archivo de copia de seguridad está dañado o es de una versión no compatible.';

  @override
  String providerBackupExportFailed(String error) {
    return 'Error al exportar la copia de seguridad: $error';
  }

  @override
  String get providerBackupExported =>
      'Copia de seguridad exportada a un archivo.';

  @override
  String providerBackupFailed(String error) {
    return 'Error en la copia de seguridad: $error';
  }

  @override
  String providerBackupLoadFailed(String error) {
    return 'No se pudo cargar la copia de seguridad: $error';
  }

  @override
  String get providerBackupNotFound =>
      'No se encontró ninguna copia de seguridad en tu Google Drive.';

  @override
  String providerBackupReadFileFailed(String error) {
    return 'No se pudo leer el archivo de copia de seguridad: $error';
  }

  @override
  String providerBackupRestoreFailed(String error) {
    return 'Error al restaurar: $error';
  }

  @override
  String providerBackupRestored(int settingsCount, int instanceCount) {
    return 'Se restauraron $settingsCount ajustes y $instanceCount instancias.';
  }

  @override
  String get providerBackupSessionExpired =>
      'La sesión de Google ha caducado. Vuelve a iniciar sesión.';

  @override
  String get providerBackupSignInFailed =>
      'No se pudo iniciar sesión. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get providerBackupSignedOut => 'Inicia sesión en Google primero.';

  @override
  String get providerBackupUnknownError => 'error desconocido';

  @override
  String providerInstanceTypeMismatch(String expected, String actual) {
    return 'Se esperaba $expected, pero se conectó a $actual';
  }

  @override
  String get purgeCrossSeedFoundContent =>
      'Se encontró un torrent con el mismo nombre de release. ¿Eliminarlo también?';

  @override
  String get purgeCrossSeedFoundTitle => 'Torrent cross-seed encontrado';

  @override
  String get purgeDeleteAll => 'Eliminar todo';

  @override
  String get purgeDeleteAnyway => 'Eliminar de todos modos';

  @override
  String get purgeDeleteTorrent => 'Eliminar torrent';

  @override
  String get purgeHash => 'Hash';

  @override
  String get purgeKeepSeeding => 'Seguir sembrando';

  @override
  String get purgeKeepTorrent => 'Mantener torrent';

  @override
  String get purgeNoTags => 'Sin etiquetas';

  @override
  String get purgeSavePath => 'Ruta de guardado';

  @override
  String purgeSeededFor(String duration) {
    return 'Sembrado durante $duration';
  }

  @override
  String get purgeTitleRemovedEitherWay =>
      'En cualquier caso, el título se quitará de la biblioteca y sus archivos se eliminarán.';

  @override
  String purgeTorrentBelowMinimum(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return 'Este torrent sembró menos del mínimo de $_temp0:';
  }

  @override
  String get purgeTorrentStillSeeding => 'Torrent aún sembrando';

  @override
  String purgeTorrentsBelowMinimum(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Los siguientes $count torrents sembraron',
      one: 'El siguiente torrent sembró',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return '$_temp0 menos del mínimo de $_temp1:';
  }

  @override
  String get purgeTorrentsStillSeeding => 'Torrents aún sembrando';

  @override
  String get qualityProfilesEmpty =>
      'No se encontraron perfiles o la instancia no está conectada';

  @override
  String qualityProfilesId(String id) {
    return 'ID: $id';
  }

  @override
  String get qualityProfilesRadarr => 'Perfiles de Radarr';

  @override
  String get qualityProfilesSonarr => 'Perfiles de Sonarr';

  @override
  String get qualityProfilesTitle => 'Perfiles de calidad';

  @override
  String get queueAddToBlocklist => 'Añadir a la lista de bloqueo';

  @override
  String get queueAddToBlocklistSubtitle =>
      'Evitar que esta versión se vuelva a capturar';

  @override
  String get queueAnyClient => 'Cualquier cliente';

  @override
  String get queueAnyInstance => 'Cualquier instancia';

  @override
  String get queueAnyProtocol => 'Cualquier protocolo';

  @override
  String get queueAscending => 'Ascendente';

  @override
  String get queueCustomFormatScore => 'Puntuación de formato personalizado';

  @override
  String get queueCustomFormats => 'Formatos personalizados';

  @override
  String get queueDescending => 'Descendente';

  @override
  String get queueDetailPath => 'Ruta';

  @override
  String get queueDirection => 'Dirección';

  @override
  String get queueEmptySubtitle => 'No hay descargas activas en este momento.';

  @override
  String get queueEmptyTitle => 'La cola está vacía';

  @override
  String queueEtaDays(int count) {
    return '${count}d';
  }

  @override
  String get queueEtaDone => 'Listo';

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
  String get queueGroupedTasks => 'Tareas agrupadas';

  @override
  String get queueInformation => 'Información';

  @override
  String get queueInstance => 'Instancia';

  @override
  String get queueItemRemoved => 'Elemento quitado de la cola';

  @override
  String get queueLoadFailed => 'No se pudieron cargar los datos de la cola.';

  @override
  String get queueLoading => 'Cargando cola...';

  @override
  String get queueManualImportDescription =>
      'Esta descarga requiere intervención manual. Selecciona qué archivos importar.';

  @override
  String get queueManualImportRequired => 'Importación manual necesaria';

  @override
  String get queueNoMatchSubtitle =>
      'Ajusta o restablece los filtros de la cola.';

  @override
  String get queueNoMatchTitle => 'No hay tareas coincidentes';

  @override
  String get queueOpenDetails => 'Abrir detalles';

  @override
  String get queueOpenMovie => 'Abrir película';

  @override
  String get queueOpenSeries => 'Abrir serie';

  @override
  String get queueOptions => 'Opciones de la cola';

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
  String get queueProblemsOnly => 'Solo problemas';

  @override
  String get queueProblemsOnlySubtitle =>
      'Mostrar tareas que requieren atención o importación manual';

  @override
  String get queueRemovalOptions => 'Opciones de eliminación';

  @override
  String get queueRemoveFromClient => 'Quitar del cliente de descarga';

  @override
  String get queueRemoveFromClientSubtitle =>
      'Eliminar la descarga del cliente';

  @override
  String get queueRemoveFromQueue => 'Quitar de la cola';

  @override
  String get queueSearchReplacement => 'Buscar reemplazo';

  @override
  String get queueSearchReplacementSubtitle =>
      'Buscar automáticamente otra versión';

  @override
  String queueSizeLeft(String size) {
    return '$size restantes';
  }

  @override
  String queueTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tareas',
      one: '1 tarea',
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
  String get queueTimeRemainingLessThanMinute => 'Menos de un minuto';

  @override
  String queueTimeRemainingMinutes(int minutes) {
    return '${minutes}min restantes';
  }

  @override
  String get queueUnableToImport => 'No se pudo importar automáticamente';

  @override
  String get queueUnknownError => 'Error desconocido';

  @override
  String get releasesAge => 'Antigüedad';

  @override
  String releasesAgeDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String releasesAgeShort(int days) {
    return '${days}d';
  }

  @override
  String get releasesApproval => 'Aprobación';

  @override
  String get releasesApproved => 'Aprobada';

  @override
  String get releasesClearSearch => 'Borrar búsqueda';

  @override
  String get releasesCustomFormat => 'Formato personalizado';

  @override
  String get releasesCustomFormatScore => 'Puntuación de formato personalizado';

  @override
  String get releasesCustomFormats => 'Formatos personalizados';

  @override
  String get releasesDetailsTitle => 'Detalles de la release';

  @override
  String get releasesDownload => 'Descargar';

  @override
  String get releasesDownloadRelease => 'Descargar release';

  @override
  String get releasesDownloadTitle => 'Descargar release';

  @override
  String get releasesEpisodeOrMovie => 'Episodio o película';

  @override
  String get releasesEpisodes => 'Episodios';

  @override
  String get releasesExcludeFreeleech => 'Excluir freeleech';

  @override
  String get releasesFilterTooltip => 'Filtrar releases';

  @override
  String get releasesFiltersSubtitle => 'Combina tantos filtros como quieras';

  @override
  String get releasesFiltersTitle => 'Filtros de releases';

  @override
  String get releasesFreeleech => 'Freeleech';

  @override
  String get releasesFreeleechOnly => 'Solo freeleech';

  @override
  String releasesGrabConfirm(String title) {
    return '¿Seguro que quieres capturar \"$title\"?';
  }

  @override
  String releasesGrabError(String error) {
    return 'Error al capturar la release: $error';
  }

  @override
  String get releasesGrabSuccess => 'Release capturada correctamente';

  @override
  String get releasesIndexerFlags => 'Indicadores del indexador';

  @override
  String get releasesLanguages => 'Idiomas';

  @override
  String get releasesMappedEpisodes => 'Episodios asignados';

  @override
  String get releasesNoMatch =>
      'Ninguna release coincide con los filtros actuales';

  @override
  String get releasesNoneFound => 'No se encontraron releases';

  @override
  String get releasesOriginalLanguageOnly => 'Solo idioma original';

  @override
  String get releasesQualityWeight => 'Peso de la calidad';

  @override
  String get releasesRejected => 'Rechazada';

  @override
  String get releasesRejectedTooltip => 'Release rechazada';

  @override
  String get releasesRejectionReasons => 'Motivos del rechazo';

  @override
  String get releasesReleaseRejected => 'Release rechazada';

  @override
  String get releasesReleaseType => 'Tipo de release';

  @override
  String get releasesReleaseWeight => 'Peso de la release';

  @override
  String get releasesRememberFilters => 'Recordar filtros';

  @override
  String get releasesRememberFiltersSubtitle =>
      'Mantener esta configuración para futuras búsquedas';

  @override
  String get releasesRequestedEpisode => 'Episodio solicitado';

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
  String get releasesSeasonPack => 'Pack de temporada';

  @override
  String get releasesSeasonPacks => 'Packs de temporada';

  @override
  String get releasesSeeders => 'Seeders';

  @override
  String get releasesSeedsPeers => 'Seeds / peers';

  @override
  String get releasesSendingTooltip =>
      'Enviando release al cliente de descargas';

  @override
  String seriesAddFailed(String error) {
    return 'Error al añadir la serie: $error';
  }

  @override
  String get seriesAddMissingSelection =>
      'Selecciona una serie, un perfil de calidad y una carpeta raíz';

  @override
  String get seriesAddSeries => 'Añadir serie';

  @override
  String get seriesAddSeriesTitle => 'Añadir serie';

  @override
  String get seriesAddedSuccessfully => 'Serie añadida correctamente';

  @override
  String get seriesAirDate => 'Fecha de emisión';

  @override
  String get seriesAllFolders => 'Todas las carpetas';

  @override
  String get seriesAllSeasonsMonitored => 'Todas las temporadas monitorizadas';

  @override
  String get seriesAllSeasonsUnmonitored =>
      'Todas las temporadas sin monitorizar';

  @override
  String get seriesAlsoDeleteFiles => 'Eliminar también los archivos del disco';

  @override
  String get seriesAndFilesDeleted => 'Serie y archivos eliminados';

  @override
  String get seriesConfigureAddition => 'Configurar adición';

  @override
  String seriesDeleteFailed(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get seriesDeleteFile => 'Eliminar archivo';

  @override
  String get seriesDeleteFileConfirm =>
      '¿Seguro que quieres eliminar este archivo? Esta acción no se puede deshacer.';

  @override
  String seriesDeleteFilesConfirm(String title) {
    return '¿Eliminar todos los archivos de \"$title\"? Esto borra del disco todos los archivos de episodios; la serie permanece en Sonarr.';
  }

  @override
  String seriesDeleteFilesFailed(String error) {
    return 'Error al eliminar los archivos: $error';
  }

  @override
  String seriesDeleteFilesForSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminar archivos de $count temporadas',
      one: 'Eliminar archivos de 1 temporada',
    );
    return '$_temp0';
  }

  @override
  String get seriesDeleteSeasonFiles => 'Eliminar archivos de la temporada';

  @override
  String seriesDeleteSeasonFilesConfirm(String title, int season) {
    return '¿Eliminar todos los archivos de \"$title - Temporada $season\"? Esto borra del disco todos los archivos de episodios de esta temporada.';
  }

  @override
  String get seriesDeleteSeasonsFilesContent =>
      'Esto borra del disco los archivos de episodios de las temporadas seleccionadas. La serie permanece en Sonarr.';

  @override
  String get seriesDeleteSeries => 'Eliminar serie';

  @override
  String seriesDeleteSeriesConfirm(String title) {
    return '¿Seguro que quieres eliminar \"$title\"?';
  }

  @override
  String get seriesDeleted => 'Serie eliminada';

  @override
  String seriesDeletedFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos eliminados',
      one: '1 archivo eliminado',
    );
    return '$_temp0';
  }

  @override
  String get seriesEditSeries => 'Editar serie';

  @override
  String get seriesEmptySubtitle =>
      'Añade series a tu biblioteca de Sonarr para verlas aquí.';

  @override
  String get seriesEpisodeActions => 'Acciones del episodio';

  @override
  String seriesEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodios',
      one: '1 episodio',
    );
    return '$_temp0';
  }

  @override
  String seriesEpisodeLoadFailed(String error) {
    return 'Error al cargar el episodio: $error';
  }

  @override
  String get seriesEpisodeLoading => 'Cargando episodio...';

  @override
  String get seriesEpisodeMonitored => 'Episodio monitorizado';

  @override
  String get seriesEpisodeUnmonitored => 'Episodio no monitorizado';

  @override
  String get seriesFile => 'Archivo';

  @override
  String get seriesFileDeleted => 'Archivo eliminado';

  @override
  String get seriesHideAlreadyAdded => 'Ocultar ya añadidas';

  @override
  String get seriesHistory => 'Historial';

  @override
  String seriesLoadEpisodesFailed(String error) {
    return 'Error al cargar los episodios: $error';
  }

  @override
  String get seriesLoadFileInfoFailed =>
      'Error al cargar la información del archivo';

  @override
  String seriesLoadFoldersError(String error) {
    return 'Error al cargar las carpetas: $error';
  }

  @override
  String get seriesLoadHistoryFailed => 'Error al cargar el historial';

  @override
  String seriesLoadProfilesError(String error) {
    return 'Error al cargar los perfiles: $error';
  }

  @override
  String get seriesLoadingDetails => 'Cargando detalles...';

  @override
  String get seriesLoadingSeries => 'Cargando series...';

  @override
  String get seriesMonitorEpisode => 'Monitorizar episodio';

  @override
  String get seriesMonitorNewSeasons => 'Monitorizar nuevas temporadas';

  @override
  String get seriesMonitorNewSeasonsSubtitle =>
      'Monitorizar automáticamente las temporadas que se añadan en el futuro';

  @override
  String get seriesMonitoredSubtitle => 'Monitorizar episodios de esta serie';

  @override
  String get seriesMoveFilesContent =>
      'Cambiaste la carpeta raíz. ¿Quieres mover los archivos existentes a la nueva ubicación?';

  @override
  String get seriesMoveFilesTitle => '¿Mover archivos?';

  @override
  String get seriesNetwork => 'Cadena';

  @override
  String get seriesNoEpisodesFound => 'No se encontraron episodios';

  @override
  String get seriesNoFileAvailable => 'No hay archivo disponible';

  @override
  String get seriesNoFilesToDelete => 'No hay archivos para eliminar';

  @override
  String get seriesNoHistoryEvents => 'No hay eventos en el historial';

  @override
  String get seriesNoOverview => 'No hay sinopsis disponible.';

  @override
  String get seriesNoRating => 'Sin valoración';

  @override
  String get seriesNoResultsFound => 'No se encontraron resultados';

  @override
  String get seriesNoResultsSubtitle =>
      'Intenta borrar o ajustar tu búsqueda o filtros.';

  @override
  String get seriesNoSeriesFound => 'No se encontraron series';

  @override
  String get seriesNoSonarrInstance =>
      'No hay ninguna instancia de Sonarr configurada';

  @override
  String get seriesOverview => 'Sinopsis';

  @override
  String get seriesPath => 'Ruta';

  @override
  String get seriesPreventReAdd => 'Evitar que esta serie se vuelva a añadir';

  @override
  String get seriesPreview => 'Vista previa de la serie';

  @override
  String seriesPreviewCrossSeedsFailed(String error) {
    return 'Error al generar la vista previa de cross-seeds: $error';
  }

  @override
  String seriesPreviewFailed(String error) {
    return 'Error al generar la vista previa: $error';
  }

  @override
  String seriesPurgeFailed(String error) {
    return 'Error al purgar: $error';
  }

  @override
  String get seriesPurgeSeason => 'Purgar temporada';

  @override
  String seriesPurgeSeasonConfirm(String title, int season) {
    return '¿Eliminar todos los archivos de \"$title - Temporada $season\" y quitar sus torrents de origen de qBittorrent? La serie permanece en Sonarr.';
  }

  @override
  String get seriesPurgeSeasonsContent =>
      'Esto borra los archivos de episodios de las temporadas seleccionadas y sus torrents de origen de qBittorrent. La serie permanece en Sonarr.';

  @override
  String seriesPurgeSeasonsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Purgar $count temporadas',
      one: 'Purgar 1 temporada',
    );
    return '$_temp0';
  }

  @override
  String get seriesPurgeSeries => 'Purgar serie';

  @override
  String seriesPurgeSeriesConfirm(String title) {
    return 'Esto eliminará permanentemente \"$title\" y todos sus episodios de Sonarr, borrará sus archivos multimedia y eliminará todos los torrents de origen (incluidos los duplicados de cross-seed) de qBittorrent. Libera el espacio en disco usado por datos con hardlinks.';
  }

  @override
  String get seriesPurged => 'Serie purgada.';

  @override
  String seriesPurgedSeasonsSummary(int seasons, int files, int torrents) {
    String _temp0 = intl.Intl.pluralLogic(
      seasons,
      locale: localeName,
      other: '$seasons temporadas purgadas',
      one: '1 temporada purgada',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files archivos',
      one: '1 archivo',
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
      other: '$files archivos',
      one: '1 archivo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      torrents,
      locale: localeName,
      other: '$torrents torrents',
      one: '1 torrent',
    );
    return 'Purgado: $_temp0, $_temp1.';
  }

  @override
  String get seriesRefreshAndScan => 'Actualizar y escanear';

  @override
  String get seriesRefreshScanTriggered => 'Actualización y escaneo iniciados';

  @override
  String seriesRootFolderFreeSpace(String path, String free) {
    return '$path ($free GB libres)';
  }

  @override
  String get seriesRootFolderHeader => 'CARPETA RAÍZ';

  @override
  String seriesRuntimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get seriesSearchByHint => 'Busca por título, ID del proveedor o URL';

  @override
  String seriesSearchFailed(String error) {
    return 'Error en la búsqueda: $error';
  }

  @override
  String get seriesSearchHint => 'Buscar series...';

  @override
  String seriesSearchStartedFor(String name) {
    return 'Búsqueda iniciada para $name';
  }

  @override
  String seriesSearchStartedForSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Búsqueda iniciada para $count temporadas',
      one: 'Búsqueda iniciada para 1 temporada',
    );
    return '$_temp0';
  }

  @override
  String seriesSearchingFor(String name) {
    return 'Buscando $name...';
  }

  @override
  String get seriesSeasonActions => 'Acciones de la temporada';

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
  String get seriesSeasonFolder => 'Carpeta de temporada';

  @override
  String get seriesSeasonFolders => 'Carpetas de temporada';

  @override
  String get seriesSeasonFoldersSubtitle =>
      'Usar carpetas por temporada (p. ej., Season 01/...)';

  @override
  String seriesSeasonLoadFailed(String error) {
    return 'Error al cargar la temporada: $error';
  }

  @override
  String get seriesSeasonLoading => 'Cargando temporada...';

  @override
  String get seriesSeasonTitle => 'Temporada';

  @override
  String get seriesSeasons => 'Temporadas';

  @override
  String get seriesSelect => 'Seleccionar';

  @override
  String get seriesSelectPath => 'Seleccionar ruta';

  @override
  String seriesSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionadas',
      one: '1 seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get seriesSeriesType => 'Tipo de serie';

  @override
  String get seriesSortAndFilter => 'Ordenar y filtrar';

  @override
  String get seriesSwitchToGrid => 'Cambiar a cuadrícula';

  @override
  String get seriesSwitchToList => 'Cambiar a lista';

  @override
  String seriesTitleWithSeason(String title, int season) {
    return '$title - Temporada $season';
  }

  @override
  String seriesUnableToOpenLink(String error) {
    return 'No se pudo abrir el enlace: $error';
  }

  @override
  String get seriesUnmonitorEpisode => 'Dejar de monitorizar episodio';

  @override
  String seriesUnmonitoredSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temporadas sin monitorizar',
      one: '1 temporada sin monitorizar',
    );
    return '$_temp0';
  }

  @override
  String seriesUpdateEpisodeFailed(String error) {
    return 'Error al actualizar el episodio: $error';
  }

  @override
  String seriesUpdateFailed(String error) {
    return 'Error al actualizar la serie: $error';
  }

  @override
  String seriesViewPoster(String title) {
    return 'Ver póster de $title';
  }

  @override
  String get seriesWatch => 'Ver';

  @override
  String get seriesYesMoveFiles => 'Sí, mover archivos';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsAddInstance => 'Añadir instancia';

  @override
  String get settingsAppUpToDate => 'La app está actualizada';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsAssistant => 'Asistente';

  @override
  String get settingsAssistantSubtitle => 'Pregunta cómo funciona la app';

  @override
  String get settingsBackupLocalFileSubtitle =>
      'Importar o exportar un archivo local';

  @override
  String get settingsColorScheme => 'Esquema de colores';

  @override
  String get settingsCouldNotCheckUpdates =>
      'No se pudieron buscar actualizaciones';

  @override
  String get settingsGettingStarted => 'Primeros pasos';

  @override
  String get settingsGettingStartedSubtitle =>
      'Repetir el recorrido de configuración';

  @override
  String get settingsHomeTab => 'Pestaña de inicio';

  @override
  String settingsInstanceTagCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count etiquetas',
      one: '1 etiqueta',
    );
    return '$_temp0';
  }

  @override
  String get settingsInstances => 'Instancias';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsNoArrInstancesConfigured =>
      'No hay instancias Arr configuradas';

  @override
  String get settingsNoInstances => 'No hay instancias configuradas';

  @override
  String get settingsNoRadarrSonarrInstances =>
      'No hay instancias de Radarr o Sonarr configuradas';

  @override
  String get settingsNotificationCenter => 'Centro de notificaciones';

  @override
  String get settingsNotificationSettings => 'Ajustes de notificaciones';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsNotificationsEnabledSubtitle =>
      'Activado · integración con ntfy.sh';

  @override
  String get settingsNotificationsSetupSubtitle => 'Configurar notificaciones';

  @override
  String get settingsSelectColor => 'Seleccionar color';

  @override
  String get settingsSelectHomeTab => 'Seleccionar pestaña de inicio';

  @override
  String get settingsSelectLanguage => 'Seleccionar idioma';

  @override
  String get settingsSelectMode => 'Seleccionar modo';

  @override
  String get settingsSessionExpiredSignIn =>
      'Sesión caducada · toca para iniciar sesión';

  @override
  String get settingsSourceCode => 'Código fuente';

  @override
  String get settingsSystem => 'Sistema';

  @override
  String get settingsSystemManagementSubtitle =>
      'Diagnóstico, estado, registros y mantenimiento de la app';

  @override
  String get settingsThemeMode => 'Modo del tema';

  @override
  String settingsUnreadNotifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificaciones sin leer',
      one: '1 notificación sin leer',
    );
    return '$_temp0';
  }

  @override
  String get settingsVersion => 'Versión';

  @override
  String settingsVersionViaAltStore(String version) {
    return '$version • actualizaciones vía AltStore';
  }

  @override
  String get settingsViewAllNotifications => 'Ver todas las notificaciones';

  @override
  String get sharedAddImportExclusion =>
      'Añadir a la lista de exclusión de importación';

  @override
  String get sharedAddImportExclusionSubtitle =>
      'Evita que una lista de importación vuelva a añadir el elemento.';

  @override
  String get sharedAscending => 'Ascendente';

  @override
  String sharedBatchDeleteFilesFailed(String error) {
    return 'No se pudieron eliminar los archivos: $error';
  }

  @override
  String get sharedBatchDeleteMovieFilesContent =>
      'Esto elimina del disco los archivos multimedia de las películas seleccionadas. Se quedan en Radarr.';

  @override
  String sharedBatchDeleteMovieFilesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminar archivos de $count películas',
      one: 'Eliminar archivos de 1 película',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteMoviesKeepFiles =>
      'Esto quita las películas seleccionadas de Radarr. Los archivos se quedan en el disco.';

  @override
  String sharedBatchDeleteMoviesPartial(int deleted, int total, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total películas',
      one: '1 película',
    );
    return 'Se eliminaron $deleted de $_temp0 antes del error: $error';
  }

  @override
  String sharedBatchDeleteMoviesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminar $count películas',
      one: 'Eliminar 1 película',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteMoviesWithFiles =>
      'Esto quita las películas seleccionadas de Radarr y elimina sus archivos del disco.';

  @override
  String get sharedBatchDeleteSeriesFilesContent =>
      'Esto elimina del disco los archivos multimedia de las series seleccionadas. Se quedan en Sonarr.';

  @override
  String sharedBatchDeleteSeriesFilesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminar archivos de $count series',
      one: 'Eliminar archivos de 1 serie',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteSeriesKeepFiles =>
      'Esto quita las series seleccionadas de Sonarr. Los archivos se quedan en el disco.';

  @override
  String sharedBatchDeleteSeriesPartial(int deleted, int total, String error) {
    return 'Se eliminaron $deleted de $total series antes del error: $error';
  }

  @override
  String sharedBatchDeleteSeriesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminar $count series',
      one: 'Eliminar 1 serie',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteSeriesWithFiles =>
      'Esto quita las series seleccionadas de Sonarr y elimina sus archivos del disco.';

  @override
  String sharedBatchDeletedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos eliminados',
      one: '1 archivo eliminado',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count películas eliminadas',
      one: '1 película eliminada',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedMoviesAndFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count películas y sus archivos eliminados',
      one: '1 película y sus archivos eliminados',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series eliminadas',
      one: '1 serie eliminada',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedSeriesAndFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series y sus archivos eliminados',
      one: '1 serie y sus archivos eliminados',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchMonitoredMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count películas monitorizadas',
      one: '1 película monitorizada',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchMonitoredSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series monitorizadas',
      one: '1 serie monitorizada',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchPreviewCrossSeedsFailed(String error) {
    return 'No se pudo generar la vista previa de los cross-seeds: $error';
  }

  @override
  String sharedBatchPreviewFailed(String error) {
    return 'No se pudo generar la vista previa: $error';
  }

  @override
  String sharedBatchPurgeFailed(String error) {
    return 'No se pudo purgar: $error';
  }

  @override
  String get sharedBatchPurgeMoviesContent =>
      'Esto quita de forma permanente las películas seleccionadas de Radarr, elimina sus archivos y elimina todos los torrents de origen de qBittorrent.';

  @override
  String sharedBatchPurgeMoviesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Purgar $count películas',
      one: 'Purgar 1 película',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchPurgeSeriesContent =>
      'Esto quita de forma permanente las series seleccionadas de Sonarr, elimina sus archivos y elimina todos los torrents de origen de qBittorrent.';

  @override
  String sharedBatchPurgeSeriesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Purgar $count series',
      one: 'Purgar 1 serie',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchPurgedMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count películas purgadas.',
      one: '1 película purgada.',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchPurgedSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series purgadas.',
      one: '1 serie purgada.',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchUnmonitoredMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count películas dejaron de monitorizarse',
      one: '1 película dejó de monitorizarse',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchUnmonitoredSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series dejaron de monitorizarse',
      one: '1 serie dejó de monitorizarse',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchUpdateMoviesPartial(int updated, int total, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total películas',
      one: '1 película',
    );
    return 'Se actualizaron $updated de $_temp0 antes del error: $error';
  }

  @override
  String sharedBatchUpdateSeriesPartial(int updated, int total, String error) {
    return 'Se actualizaron $updated de $total series antes del error: $error';
  }

  @override
  String get sharedDescending => 'Descendente';

  @override
  String get sharedFailedToLoadTorrents => 'No se pudieron cargar los torrents';

  @override
  String get sharedNoRadarrInstance =>
      'No hay ninguna instancia de Radarr configurada';

  @override
  String get sharedNoTorrentsInClient =>
      'No hay torrents en el cliente de descargas';

  @override
  String sharedSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionados',
      one: '1 seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get sharedTorrents => 'Torrents';

  @override
  String get systemAppMaintenance => 'Mantenimiento de la app';

  @override
  String get systemClearImageCache => 'Borrar caché de imágenes';

  @override
  String get systemClearImageCacheSubtitle =>
      'Libera el espacio de pósteres e imágenes en caché';

  @override
  String get systemDaysHelper => '0 desactiva el aviso';

  @override
  String get systemDaysInvalid => 'Introduce un número válido (0 o más)';

  @override
  String get systemDaysLabel => 'Días';

  @override
  String get systemDiagnosticsSubtitle =>
      'Prueba endpoints, latencia, trazas de solicitudes y exporta un informe';

  @override
  String get systemHealth => 'Salud';

  @override
  String get systemHealthSubtitle =>
      'Alertas de Radarr y Sonarr reportadas por el servidor';

  @override
  String get systemImageCacheCleared => 'Caché de imágenes borrada';

  @override
  String get systemLogs => 'Registros';

  @override
  String get systemLogsSubtitle => 'Registros de eventos del sistema';

  @override
  String get systemManagementTitle => 'Gestión del sistema';

  @override
  String get systemMinimumSeedingDays => 'Días mínimos de siembra';

  @override
  String get systemMinimumSeedingDaysDescription =>
      'Los torrents que sembraron menos que esto piden confirmación antes de eliminarse. Usa 0 para desactivarlo.';

  @override
  String get systemOverviewDiskSpace => 'Espacio en disco';

  @override
  String get systemOverviewDiskSpaceUnavailable =>
      'La información de espacio en disco no está disponible.';

  @override
  String get systemOverviewEmptySubtitle =>
      'Añade una instancia de Radarr o Sonarr para ver los datos del sistema.';

  @override
  String systemOverviewEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Episodios',
      one: '1 Episodio',
    );
    return '$_temp0';
  }

  @override
  String systemOverviewFreeOf(String free, String total) {
    return '$free libres de $total';
  }

  @override
  String systemOverviewLibrarySize(String size) {
    return '$size Biblioteca';
  }

  @override
  String get systemOverviewLibraryUnavailable =>
      'Las estadísticas de la biblioteca no están disponibles.';

  @override
  String get systemOverviewLoadFailed =>
      'Error al cargar el resumen del sistema.';

  @override
  String get systemOverviewLoading => 'Cargando resumen del sistema...';

  @override
  String systemOverviewMovieCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Películas',
      one: '1 Película',
    );
    return '$_temp0';
  }

  @override
  String get systemOverviewNoStorage =>
      'No se reportaron ubicaciones de almacenamiento.';

  @override
  String systemOverviewSeriesCount(int count) {
    return '$count Series';
  }

  @override
  String get systemOverviewSubtitle =>
      'Almacenamiento, versiones y tamaño de las bibliotecas';

  @override
  String get systemOverviewTitle => 'Resumen del sistema';

  @override
  String systemOverviewUsed(String size, int percent) {
    return 'Usado $size ($percent%)';
  }

  @override
  String get systemOverviewVersionUnavailable =>
      'La información de versión no está disponible.';

  @override
  String get systemQualityProfilesSubtitle =>
      'Perfiles disponibles en las instancias';

  @override
  String get systemResetConfirmBody =>
      'Esto restablece la apariencia, el idioma, el modo de vista y las preferencias de notificaciones a sus valores predeterminados. Las instancias configuradas se conservan.';

  @override
  String get systemResetConfirmTitle => '¿Restablecer ajustes de la app?';

  @override
  String get systemResetSettings => 'Restablecer ajustes de la app';

  @override
  String get systemResetSettingsSubtitle =>
      'Restablece los valores de apariencia, idioma, vista y notificaciones';

  @override
  String systemSeedingDaysShort(int count) {
    return '${count}d';
  }

  @override
  String get systemSeedingWarningDisabled => 'Aviso de siembra desactivado';

  @override
  String systemSeedingWarningEnabled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return 'Avisar antes de eliminar torrents que sembraron menos de $_temp0.';
  }

  @override
  String get systemServer => 'Servidor';

  @override
  String get systemSettingsReset =>
      'Ajustes de la app restablecidos a los valores predeterminados';

  @override
  String get systemTorrentProtection => 'Protección de torrents';

  @override
  String get systemVersionHistorySubtitle =>
      'Novedades de cada versión publicada';

  @override
  String torrentAddFailed(String error) {
    return 'Error al añadir el torrent: $error';
  }

  @override
  String get torrentAddOptions => 'Opciones';

  @override
  String get torrentAddOr => 'O';

  @override
  String get torrentAddSource => 'Origen';

  @override
  String get torrentAddSourceRequired =>
      'Indica URL o selecciona un archivo .torrent';

  @override
  String get torrentAddTorrent => 'Añadir torrent';

  @override
  String get torrentAdded => 'Torrent añadido correctamente';

  @override
  String get torrentAlsoDeleteFiles =>
      'Eliminar también los archivos del disco';

  @override
  String get torrentCategoriesLoadFailed =>
      'No se pudieron cargar las categorías. Usando texto libre.';

  @override
  String get torrentCategoryOptional => 'Categoría (opcional)';

  @override
  String get torrentChangeSaveLocation => 'Cambiar ubicación de guardado';

  @override
  String get torrentChangeSaveLocationWarning =>
      'Esto moverá todos los datos descargados a la nueva ubicación.';

  @override
  String get torrentClearSearch => 'Borrar búsqueda';

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
      'Identificado como cross-seed: mismo nombre de release que el torrent que Radarr/Sonarr capturó, infohash distinto.';

  @override
  String get torrentEmptySubtitle =>
      'Añade un torrent para empezar a descargar';

  @override
  String get torrentEmptyTitle => 'Sin torrents';

  @override
  String get torrentEnterValidPath => 'Introduce una ruta válida';

  @override
  String torrentEta(String eta) {
    return 'Restante: $eta';
  }

  @override
  String get torrentFiles => 'Archivos';

  @override
  String get torrentFilterLibraryLink => 'Vínculo con la biblioteca';

  @override
  String get torrentFilterTooltip => 'Filtrar torrents';

  @override
  String get torrentFiltersSubtitle => 'Combina tantos filtros como quieras';

  @override
  String get torrentFiltersTitle => 'Filtros de torrent';

  @override
  String torrentImportFailed(String error) {
    return 'Error al importar: $error';
  }

  @override
  String torrentImportFilesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos importados correctamente',
      one: '1 archivo importado correctamente',
    );
    return '$_temp0';
  }

  @override
  String torrentImportFilesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos seleccionados para importar',
      one: '1 archivo seleccionado para importar',
    );
    return '$_temp0';
  }

  @override
  String get torrentImportLoadMoviesFailed => 'Error al cargar las películas';

  @override
  String get torrentImportLoadSeriesFailed => 'Error al cargar las series';

  @override
  String get torrentImportLoadingMovies => 'Cargando películas...';

  @override
  String get torrentImportLoadingSeries => 'Cargando series...';

  @override
  String get torrentImportNoFilesSelected => 'No hay archivos seleccionados';

  @override
  String torrentImportNoFilesSubtitle(String path) {
    return 'No se encontraron archivos importables en $path';
  }

  @override
  String get torrentImportNoFilesTitle => 'No se encontraron archivos';

  @override
  String get torrentImportNoMoviesSubtitle =>
      'Ninguna película monitorizada coincide con tu búsqueda.';

  @override
  String get torrentImportNoMoviesTitle => 'No se encontraron películas';

  @override
  String get torrentImportNoSeriesSubtitle =>
      'Ninguna serie monitorizada coincide con tu búsqueda.';

  @override
  String get torrentImportNoSeriesTitle => 'No se encontraron series';

  @override
  String get torrentImportSearchHint => 'Buscar...';

  @override
  String get torrentImportSelectFilesHint =>
      'Selecciona los archivos que quieres importar. Toca un archivo para configurar su asignación.';

  @override
  String get torrentImportSelectTarget => 'Seleccionar destino';

  @override
  String get torrentImportToLibrary => 'Importar a la biblioteca';

  @override
  String get torrentImportToMovie => 'Importar a película';

  @override
  String get torrentImportToSeries => 'Importar a serie';

  @override
  String get torrentInfoAddedOn => 'Añadido el';

  @override
  String get torrentInfoCategory => 'Categoría';

  @override
  String get torrentInfoHash => 'Hash';

  @override
  String get torrentInfoInstance => 'Instancia';

  @override
  String get torrentInfoMedia => 'Medio';

  @override
  String get torrentInfoSavePath => 'Ruta';

  @override
  String get torrentLibraryLinksLoadFailed =>
      'No se pudieron cargar los vínculos con la biblioteca.';

  @override
  String get torrentLoadFailed => 'Error al cargar los torrents';

  @override
  String torrentLoadFilesFailed(String error) {
    return 'Error al cargar los archivos: $error';
  }

  @override
  String get torrentLoadPeersFailed => 'Error al cargar los peers';

  @override
  String get torrentLoadTrackersFailed => 'Error al cargar los trackers';

  @override
  String get torrentLoading => 'Cargando torrents...';

  @override
  String get torrentLoadingFiles => 'Cargando archivos...';

  @override
  String get torrentLoadingPeers => 'Cargando peers...';

  @override
  String get torrentLoadingTrackers => 'Cargando trackers...';

  @override
  String get torrentLocationMoved =>
      'Ubicación cambiada correctamente. Los datos se están moviendo.';

  @override
  String get torrentMove => 'Mover';

  @override
  String torrentMoveFailed(String error) {
    return 'Error al mover: $error';
  }

  @override
  String get torrentNewLocation => 'Nueva ubicación';

  @override
  String get torrentNoFilesFound => 'No se encontraron archivos';

  @override
  String get torrentNoFilterMatches =>
      'Ningún torrent coincide con los filtros actuales';

  @override
  String get torrentNoPeers => 'No hay peers conectados';

  @override
  String get torrentNoPeersSubtitle =>
      'Los peers aparecerán cuando el torrent esté activo';

  @override
  String get torrentNoTrackers => 'Sin trackers';

  @override
  String get torrentNoTrackersSubtitle =>
      'Las URL de anuncio aparecen aquí cuando qBittorrent las tenga';

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
    return '$percent completado';
  }

  @override
  String torrentPercentDone(String percent) {
    return '$percent completado';
  }

  @override
  String torrentPickFileFailed(String error) {
    return 'Error al seleccionar el archivo: $error';
  }

  @override
  String get torrentRecheck => 'Verificar';

  @override
  String get torrentRememberFilters => 'Recordar filtros';

  @override
  String get torrentRememberFiltersSubtitle =>
      'Mantener esta configuración para futuras sesiones';

  @override
  String get torrentRemove => 'Quitar';

  @override
  String torrentRemoveConfirm(String name) {
    return '¿Seguro que quieres quitar \"$name\"?';
  }

  @override
  String torrentRemoveFailed(String error) {
    return 'Error al quitar el torrent: $error';
  }

  @override
  String get torrentRemoveTitle => '¿Quitar torrent?';

  @override
  String get torrentRemoveTorrent => 'Quitar torrent';

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
  String get torrentResume => 'Reanudar';

  @override
  String get torrentSavePathOptional => 'Ruta de guardado (opcional)';

  @override
  String get torrentSearchHint => 'Buscar torrents';

  @override
  String get torrentSectionActions => 'Acciones';

  @override
  String get torrentSectionInformation => 'Información';

  @override
  String get torrentSectionMediaLibrary => 'Biblioteca multimedia';

  @override
  String get torrentSectionProgress => 'Progreso';

  @override
  String get torrentSelectFile => 'Seleccionar archivo .torrent';

  @override
  String get torrentSetPriority => 'Establecer prioridad';

  @override
  String get torrentSortAscending => 'Ascendente';

  @override
  String get torrentSortDescending => 'Descendente';

  @override
  String get torrentStartPaused => 'Iniciar en pausa';

  @override
  String get torrentStatDlSpeed => 'Vel. descarga';

  @override
  String get torrentStatDownloaded => 'Descargado';

  @override
  String get torrentStatLeechers => 'Leechers';

  @override
  String get torrentStatRatio => 'Ratio';

  @override
  String get torrentStatSeedTime => 'Tiempo sembrando';

  @override
  String get torrentStatSeeds => 'Seeds';

  @override
  String get torrentStatTotalSize => 'Tamaño total';

  @override
  String get torrentStatUlSpeed => 'Vel. subida';

  @override
  String get torrentStatUploaded => 'Subido';

  @override
  String get torrentTagsCommaSeparated => 'Separadas por comas';

  @override
  String get torrentTagsLoadFailed =>
      'No se pudieron cargar las etiquetas. Usando texto libre.';

  @override
  String get torrentTagsOptional => 'Etiquetas (opcional)';

  @override
  String get torrentTagsSearchHint => 'Escribe para buscar o añadir etiquetas';

  @override
  String torrentTrackerDownloads(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count descargas',
      one: '1 descarga',
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
    return 'Nivel $tier';
  }

  @override
  String get torrentTrackers => 'Trackers';

  @override
  String get torrentUrlsHint =>
      'Pega enlaces magnet o URL HTTP aquí\nUno por línea';

  @override
  String get torrentUrlsLabel => 'Enlace magnet o URL';

  @override
  String get tourActivityBody =>
      'Supervisa aquí tu cola de descargas, el historial y los torrents de qBittorrent.';

  @override
  String get tourActivityQueueBody =>
      'Las descargas activas muestran el progreso, el tamaño restante y la finalización estimada. Toca una para ver detalles y acciones.';

  @override
  String get tourActivityQueueTitle => 'Cola de descargas';

  @override
  String get tourAddInstanceBody =>
      'Toca aquí para crear una nueva conexión con un servidor. Los siguientes pasos explican el formulario.';

  @override
  String get tourAddInstanceTitle => 'Añadir instancia';

  @override
  String get tourCalendarBody =>
      'Sigue los próximos estrenos de películas y episodios de series.';

  @override
  String get tourCalendarEventsBody =>
      'Cada tarjeta muestra lo próximo que se emite o estrena, agrupado por día y con colores según el tipo de estreno.';

  @override
  String get tourCalendarEventsTitle => 'Próximos estrenos';

  @override
  String get tourInstanceApiKeyBody =>
      'Radarr/Sonarr requieren una API Key, disponible en Settings → General. qBittorrent usa un token Bearer (v5.2.0+) o Basic Auth.';

  @override
  String get tourInstanceApiKeyTitle => 'API Key';

  @override
  String get tourInstanceNameBody =>
      'Un nombre descriptivo para distinguir tus servidores (p. ej., \"Servidor de casa\").';

  @override
  String get tourInstanceNameTitle => 'Nombre';

  @override
  String get tourInstanceTypeBody =>
      'Elige Radarr (películas), Sonarr (series) o qBittorrent (descargas). Cada uno necesita su propia conexión.';

  @override
  String get tourInstanceTypeTitle => 'Elige el tipo de servidor';

  @override
  String get tourInstanceUrlBody =>
      'La dirección de tu servidor con http(s):// y el puerto, p. ej., http://192.168.1.10:7878.';

  @override
  String get tourInstanceUrlTitle => 'URL';

  @override
  String get tourInstancesBody =>
      'Tus servidores Radarr, Sonarr y qBittorrent están aquí. Vamos a añadir el primero.';

  @override
  String get tourInstancesTitle => 'Instancias';

  @override
  String get tourMockupBanner =>
      'Contenido de ejemplo mostrado durante el recorrido. Desaparece cuando termina el recorrido.';

  @override
  String get tourMoviesLibraryBody =>
      'Todas las películas que gestiona Radarr aparecen aquí, con su estado de monitorización y de descarga.';

  @override
  String get tourMoviesLibraryTitle => 'Tu biblioteca de películas';

  @override
  String get tourMoviesSearchBody =>
      'Encuentra películas de tu biblioteca por título.';

  @override
  String get tourMoviesSortBody =>
      'Reordena y filtra tu biblioteca para navegar más rápido.';

  @override
  String get tourMoviesSortTitle => 'Ordenar y filtrar';

  @override
  String get tourNavigationBody =>
      'Cambia entre Películas, Series, Calendario, Actividad y Ajustes cuando quieras.';

  @override
  String get tourNavigationTitle => 'Navegación';

  @override
  String get tourSaveInstanceBody =>
      'Cuando todo esté correcto, guarda para terminar la configuración. Puedes añadir los demás servidores cuando quieras desde Ajustes.';

  @override
  String get tourSaveInstanceTitle => 'Guardar instancia';

  @override
  String get tourSeriesLibraryBody =>
      'Tus series de Sonarr están aquí, con el número de temporadas y cuánto de cada serie ya se ha descargado.';

  @override
  String get tourSeriesLibraryTitle => 'Tu biblioteca de series';

  @override
  String get tourSkip => 'Omitir';

  @override
  String get tourTestConnectionBody =>
      'Verifica la URL y las credenciales antes de guardar.';

  @override
  String get tourTestConnectionTitle => 'Probar conexión';

  @override
  String get tourTorrentsBody =>
      'Los torrents de qBittorrent muestran velocidad, ratio y peers en tiempo real, con acciones para pausar, reanudar e importar.';

  @override
  String get tourTorrentsTitle => 'Torrents';

  @override
  String get updateAndRestart => 'Actualizar y reiniciar';

  @override
  String get updateAvailableTitle => 'Nueva versión disponible';

  @override
  String get updateChangelog => 'Registro de cambios:';

  @override
  String get updateDownloadingTitle => 'Descargando actualización';

  @override
  String get updateInstallingTitle => 'Instalando...';

  @override
  String get updateLater => 'Más tarde';

  @override
  String get updateNow => 'Actualizar ahora';

  @override
  String get updatePreparing => 'Preparando la actualización...';

  @override
  String get updateRestartNotice =>
      'La aplicación se cerrará y se reiniciará para completar la actualización.';

  @override
  String get updateUnexpectedError => 'Se produjo un error inesperado.';

  @override
  String updateVersion(String version) {
    return 'Versión: $version';
  }

  @override
  String get versionHistoryEmptySubtitle =>
      'No se pudo cargar el historial de versiones.';

  @override
  String get versionHistoryEmptyTitle => 'No hay versiones disponibles';

  @override
  String get versionHistoryInstalled => 'Instalada';

  @override
  String versionHistoryLoadFailed(String error) {
    return 'Error al cargar el historial de versiones: $error';
  }

  @override
  String get versionHistoryLoading => 'Cargando historial de versiones...';

  @override
  String get versionHistoryTitle => 'Historial de versiones';

  @override
  String get watchingEmptySubtitle =>
      'El contenido que pauses en Jellyfin aparecerá aquí.';

  @override
  String get watchingEmptyTitle => 'Nada en curso';

  @override
  String get watchingLoading => 'Cargando seguir viendo...';

  @override
  String get whatsNewNoNotes => 'Esta versión no incluye notas de la versión.';

  @override
  String whatsNewTitle(String version) {
    return 'Novedades de la v$version';
  }

  @override
  String get whatsNewViewAllVersions => 'Ver todas las versiones';

  @override
  String get widgetsClosePoster => 'Cerrar póster';

  @override
  String widgetsCustomFormatScore(String score) {
    return 'Puntuación: $score';
  }

  @override
  String get widgetsDeleteFile => 'Eliminar archivo';

  @override
  String get widgetsEventAdditionalData => 'Datos adicionales';

  @override
  String get widgetsEventDate => 'Fecha';

  @override
  String get widgetsEventDetailsTitle => 'Detalles del evento';

  @override
  String get widgetsEventSourceTitle => 'Título de origen';

  @override
  String get widgetsEventType => 'Tipo de evento';

  @override
  String get widgetsExtraFileMetadata => 'Metadatos';

  @override
  String get widgetsExtraFileOther => 'Otro';

  @override
  String get widgetsExtraFileSubtitle => 'Subtítulo';

  @override
  String get widgetsFileAudioBitrate => 'Bitrate de audio';

  @override
  String get widgetsFileAudioChannels => 'Canales de audio';

  @override
  String get widgetsFileAudioCodec => 'Códec de audio';

  @override
  String get widgetsFileAudioLanguages => 'Idiomas del audio';

  @override
  String get widgetsFileAudioStreams => 'Pistas de audio';

  @override
  String get widgetsFileBitDepth => 'Profundidad de bits';

  @override
  String get widgetsFileCustomFormats => 'Formatos personalizados';

  @override
  String get widgetsFileDateAdded => 'Fecha de adición';

  @override
  String get widgetsFileDetailsTitle => 'Detalles del archivo';

  @override
  String get widgetsFileDuration => 'Duración';

  @override
  String get widgetsFileDynamicRange => 'Rango dinámico';

  @override
  String get widgetsFileFrameRate => 'Velocidad de fotogramas';

  @override
  String get widgetsFileGeneral => 'General';

  @override
  String get widgetsFileHdrType => 'Tipo de HDR';

  @override
  String get widgetsFileMediaInfo => 'Información multimedia';

  @override
  String get widgetsFilePath => 'Ruta';

  @override
  String get widgetsFileResolution => 'Resolución';

  @override
  String get widgetsFileRevision => 'Revisión';

  @override
  String get widgetsFileScanType => 'Tipo de escaneo';

  @override
  String get widgetsFileSource => 'Fuente';

  @override
  String get widgetsFileSubtitles => 'Subtítulos';

  @override
  String get widgetsFileVideoBitrate => 'Bitrate de vídeo';

  @override
  String get widgetsFileVideoCodec => 'Códec de vídeo';

  @override
  String get widgetsNoPreviousOnline =>
      'No hay ninguna conexión en línea anterior registrada';

  @override
  String get widgetsNoTagsAvailable => 'No hay etiquetas disponibles';

  @override
  String get widgetsNotifications => 'Notificaciones';

  @override
  String get widgetsOffline => 'Sin conexión';

  @override
  String widgetsOfflineCacheCaveat(String lastOnline, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return '$lastOnline · Las imágenes en caché pueden tener hasta $_temp0 de antigüedad';
  }

  @override
  String get widgetsPlay => 'Reproducir';

  @override
  String get widgetsQueueDownloadFailed => 'Descarga fallida';

  @override
  String get widgetsQueueDownloadPaused => 'Descarga pausada';

  @override
  String get widgetsQueueDownloadPending => 'Descarga pendiente';

  @override
  String get widgetsQueueDownloadWarning => 'Advertencia de descarga';

  @override
  String get widgetsQueueStatusUnknown => 'Estado desconocido';

  @override
  String widgetsSelectInstance(String type) {
    return 'Seleccionar instancia de $type';
  }

  @override
  String get widgetsSelectTags => 'Seleccionar etiquetas';

  @override
  String get widgetsSomeInstancesFailed =>
      'No se pudieron cargar algunas instancias';

  @override
  String get widgetsSortBy => 'Ordenar por';

  @override
  String get widgetsSortOrder => 'Orden';

  @override
  String widgetsTagButtonWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get widgetsUnknownFile => 'Archivo desconocido';
}
