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
  String get uploadPickFile => 'Elegir archivo de audio';

  @override
  String get uploadFileHint => 'WAV, FLAC, MP3 o M4A · hasta 200 MB';

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
  String get uploadErrorTooLarge => 'El archivo supera los 200 MB.';

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
  String get uploadCoverHint => 'Cuadrada, mín. 640 px\nJPG, PNG o WebP';

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
  String get uploadErrorCoverTooLarge => 'La portada supera los 10 MB.';

  @override
  String get uploadErrorCoverTooSmall =>
      'La portada debe medir al menos 640 × 640 px.';

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
}
