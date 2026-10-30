// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Sonify';

  @override
  String get loginTagline => 'tu ritmo son latino';

  @override
  String get loginWithGoogle => 'Ingresar con Google';

  @override
  String get authErrorNetwork =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.';

  @override
  String get authErrorUnknown =>
      'No pudimos iniciar sesión. Inténtalo de nuevo.';

  @override
  String homeGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get account => 'Cuenta';

  @override
  String playSong(String title) {
    return 'Reproducir $title';
  }

  @override
  String get catalogEmpty => 'Aún no hay canciones.';

  @override
  String get catalogError => 'No pudimos cargar las canciones.';

  @override
  String get retry => 'Reintentar';

  @override
  String get catalogLoadMoreError => 'No se pudieron cargar más canciones';

  @override
  String get showPlayer => 'Ver reproductor';

  @override
  String get songNeedsConnection =>
      'Sin conexión: descárgala para escucharla sin red';

  @override
  String get refresh => 'Actualizar';

  @override
  String get shuffle => 'Aleatorio';

  @override
  String get previous => 'Anterior';

  @override
  String get next => 'Siguiente';

  @override
  String get play => 'Reproducir';

  @override
  String get pause => 'Pausar';

  @override
  String get repeatOff => 'Repetir: desactivado';

  @override
  String get repeatAll => 'Repetir todo';

  @override
  String get repeatOne => 'Repetir esta canción';

  @override
  String get uploadTitle => 'Subir canción';

  @override
  String get themeToDark => 'Cambiar a modo oscuro';

  @override
  String get themeToLight => 'Cambiar a modo claro';

  @override
  String get uploadPickFile => 'Elegir archivo de audio';

  @override
  String get uploadFileHint => 'MP3, M4A, WAV o FLAC · hasta 10 MB';

  @override
  String get uploadSongTitle => 'Título';

  @override
  String get uploadGenre => 'Género';

  @override
  String get uploadGenreNone => 'Sin género';

  @override
  String get uploadGenreSearch => 'Escribe para buscar';

  @override
  String get uploadGenreNoResults => 'No hay géneros con ese nombre';

  @override
  String get uploadRights =>
      'Declaro que soy el autor de esta canción o tengo los derechos para publicarla en dominio público (CC0): cualquiera podrá escucharla, compartirla y usarla libremente.';

  @override
  String get uploadSubmit => 'Subir';

  @override
  String uploadProgress(int percent) {
    return 'Subiendo… $percent%';
  }

  @override
  String get uploadDone =>
      '¡Listo! Tu canción se está procesando y aparecerá cuando esté lista.';

  @override
  String get uploadErrorNoFile => 'Elige un archivo de audio.';

  @override
  String get uploadErrorTitle => 'Escribe un título (máximo 120 caracteres).';

  @override
  String get uploadErrorRights =>
      'Debes declarar que tienes los derechos de la canción.';

  @override
  String get uploadErrorType =>
      'Formato no soportado. Usa WAV, FLAC, MP3 o M4A.';

  @override
  String get uploadErrorTooLarge =>
      'El archivo supera los 10 MB. Prueba con MP3 o M4A.';

  @override
  String get uploadErrorDailyLimit =>
      'Llegaste al límite de subidas de hoy. Inténtalo mañana.';

  @override
  String get uploadErrorNetwork =>
      'Se perdió la conexión durante la subida. Inténtalo de nuevo.';

  @override
  String get uploadErrorUnknown =>
      'No pudimos subir la canción. Inténtalo de nuevo.';

  @override
  String get uploadPickCover => 'Elegir portada';

  @override
  String get uploadCoverHint => 'Cuadrada\nJPG, PNG o WebP · hasta 3 MB';

  @override
  String get uploadDescription => 'Descripción (opcional)';

  @override
  String get uploadDescriptionHint => 'De qué trata, créditos, letra corta…';

  @override
  String get uploadErrorDescription =>
      'La descripción supera los 500 caracteres.';

  @override
  String get uploadErrorCoverType => 'La portada debe ser JPG, PNG o WebP.';

  @override
  String get uploadErrorCoverTooLarge => 'La portada supera los 3 MB.';

  @override
  String get downloads => 'Descargas';

  @override
  String get downloadsEmpty =>
      'Aún no tienes descargas.\nMantén presionada una canción para descargarla y escucharla sin señal.';

  @override
  String downloadsSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
    );
    return '$_temp0 · $size';
  }

  @override
  String get downloadsDeleteAll => 'Borrar todo';

  @override
  String get listeningCacheInfo =>
      'Sonify guarda automáticamente en caché las canciones que escuchaste recientemente. Es similar al modo offline, con la única diferencia de que cuando se apague o se reinicie tu dispositivo se borrarán sin previo aviso. Si también quieres liberar espacio de las canciones en caché, puedes borrarlas con el botón Vaciar caché de Sonify.';

  @override
  String get listeningCacheClear => 'Vaciar caché de Sonify';

  @override
  String get listeningCacheClearConfirm =>
      '¿Vaciar las canciones escuchadas que se guardaron solas? Tus descargas no se borran; lo demás volverá a usar la red.';

  @override
  String get downloadsDeleteAllConfirm =>
      '¿Borrar todas las descargas? Tendrás que volver a bajarlas para escucharlas sin señal.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Borrar';

  @override
  String get downloadSong => 'Descargar';

  @override
  String downloadList(int count) {
    return 'Descargar toda la lista ($count)';
  }

  @override
  String get downloadRemove => 'Quitar descarga';

  @override
  String downloadRemoveConfirm(String title) {
    return '¿Borrar «$title» de tus descargas? Ya no podrás escucharla sin señal.';
  }

  @override
  String get downloadRetry => 'Reintentar descarga';

  @override
  String downloadQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Descargando $count canciones (solo con Wi-Fi)',
      one: 'Descargando 1 canción (solo con Wi-Fi)',
      zero: 'Ya estaba descargado',
    );
    return '$_temp0';
  }

  @override
  String downloadNoSpace(String required, String available) {
    return 'No hay espacio: necesitas $required y tienes $available libres.';
  }

  @override
  String get downloadStateDone => 'Descargada';

  @override
  String get downloadStateQueued => 'En cola';

  @override
  String get downloadStateFailed => 'Falló la descarga';

  @override
  String downloadProgress(int percent) {
    return 'Descargando $percent%';
  }

  @override
  String get uploadErrorNotAdmin =>
      'Solo los administradores pueden subir canciones.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navLibrary => 'Tu biblioteca';

  @override
  String get navLibraryShort => 'Biblioteca';

  @override
  String get navPremium => 'Premium';

  @override
  String get searchHint => 'Canción o artista';

  @override
  String get searchPrompt =>
      'Busca en todo el catálogo por canción o artista y guarda las que quieras escuchar.';

  @override
  String searchNoResults(String query) {
    return 'No encontramos «$query».';
  }

  @override
  String get searchError => 'No pudimos buscar. Inténtalo de nuevo.';

  @override
  String get searchOffline =>
      'Sin conexión: buscando en lo que tienes en el teléfono.';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get librarySavedSongs => 'Tus canciones';

  @override
  String librarySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
      zero: 'Sin canciones',
    );
    return '$_temp0';
  }

  @override
  String librarySongCountLimit(int count, int limit) {
    return '$count de $limit canciones';
  }

  @override
  String get libraryPlaylists => 'Playlists';

  @override
  String get libraryNewPlaylist => 'Nueva playlist';

  @override
  String get libraryPlaylistsEmpty =>
      'Crea una playlist para separar tus canciones, por ejemplo «Para el auto».';

  @override
  String get librarySongsEmpty =>
      'Aún no guardaste canciones.\nBúscalas en Buscar y guárdalas para escucharlas.';

  @override
  String get libraryPlaylistEmpty =>
      'Mantén presionada una canción y elige «Agregar a una playlist».';

  @override
  String get libraryError => 'No pudimos cargar tu biblioteca.';

  @override
  String get playlistName => 'Nombre de la playlist';

  @override
  String get playlistCreate => 'Crear';

  @override
  String get playlistRename => 'Cambiar nombre';

  @override
  String get playlistSave => 'Guardar';

  @override
  String get playlistDelete => 'Borrar playlist';

  @override
  String playlistDeleteConfirm(String name) {
    return '¿Borrar «$name»? Las canciones siguen en tu biblioteca.';
  }

  @override
  String get playlistMore => 'Más opciones';

  @override
  String get songSave => 'Guardar en tu biblioteca';

  @override
  String get songUnsave => 'Quitar de tu biblioteca';

  @override
  String get songSaved => 'Guardada en tu biblioteca';

  @override
  String get songUnsaved => 'Quitada de tu biblioteca';

  @override
  String get songSavedTooltip => 'Guardada';

  @override
  String get songAddToPlaylist => 'Agregar a una playlist';

  @override
  String songAddedToPlaylist(String name) {
    return 'Agregada a «$name»';
  }

  @override
  String get songRemoveFromPlaylist => 'Quitar de esta playlist';

  @override
  String libraryRemaining(int count, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te quedan $count de $limit',
      one: 'Te queda 1 de $limit',
      zero: 'No te quedan lugares',
    );
    return '$_temp0';
  }

  @override
  String libraryErrorLimit(int limit) {
    return 'Llegaste a $limit canciones. Quita alguna de tu biblioteca o hazte Premium.';
  }

  @override
  String get libraryErrorNetwork =>
      'Necesitas conexión para cambiar tu biblioteca.';

  @override
  String get libraryErrorName => 'Escribe un nombre de hasta 60 caracteres.';

  @override
  String get libraryErrorUnknown =>
      'No pudimos guardar el cambio. Inténtalo de nuevo.';

  @override
  String get seePremium => 'Ver Premium';

  @override
  String get lockedTitle => 'Guárdala para escucharla';

  @override
  String lockedBody(int limit) {
    return 'Con la cuenta gratis escuchas hasta $limit canciones guardadas, con todo: streaming, sin señal y en segundo plano.';
  }

  @override
  String lockedFull(int limit) {
    return 'Ya guardaste $limit canciones. Quita alguna de tu biblioteca o hazte Premium para escuchar sin límite.';
  }

  @override
  String get lockedTooltip => 'Guardar para escuchar';

  @override
  String get premiumTitle => 'Sonify Premium';

  @override
  String get premiumActive => 'Eres Premium';

  @override
  String get premiumActiveBody =>
      'Guarda y escucha todas las canciones que quieras, también sin señal y en segundo plano.';

  @override
  String premiumFreeIntro(int limit) {
    return 'Sin Premium puedes guardar hasta $limit canciones, y con ellas tienes todos los beneficios:';
  }

  @override
  String get premiumBenefitStreaming => 'Streaming en alta calidad';

  @override
  String get premiumBenefitOffline => 'Escuchar sin señal (descargas)';

  @override
  String get premiumBenefitBackground =>
      'Escuchar en segundo plano y con la pantalla bloqueada';

  @override
  String get premiumBenefitPlaylists => 'Tus propias playlists';

  @override
  String get premiumWithPremium => 'Con Premium';

  @override
  String get premiumUnlimited => 'Canciones sin límite en tu biblioteca';

  @override
  String premiumUsage(int count, int limit) {
    return 'Usas $count de $limit';
  }

  @override
  String premiumCta(String price) {
    return 'Hazte Premium · $price al mes';
  }

  @override
  String get premiumSoon => 'Muy pronto podrás suscribirte desde la app.';
}
