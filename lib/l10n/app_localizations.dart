import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Sonify'**
  String get appTitle;

  /// No description provided for @loginTagline.
  ///
  /// In es, this message translates to:
  /// **'tu ritmo son latino'**
  String get loginTagline;

  /// No description provided for @loginWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Ingresar con Google'**
  String get loginWithGoogle;

  /// No description provided for @authErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu internet e inténtalo de nuevo.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorUnknown.
  ///
  /// In es, this message translates to:
  /// **'No pudimos iniciar sesión. Inténtalo de nuevo.'**
  String get authErrorUnknown;

  /// No description provided for @homeGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String homeGreeting(String name);

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOut;

  /// No description provided for @account.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get account;

  /// No description provided for @playSong.
  ///
  /// In es, this message translates to:
  /// **'Reproducir {title}'**
  String playSong(String title);

  /// No description provided for @catalogEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay canciones.'**
  String get catalogEmpty;

  /// No description provided for @catalogError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar las canciones.'**
  String get catalogError;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @catalogLoadMoreError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar más canciones'**
  String get catalogLoadMoreError;

  /// No description provided for @showPlayer.
  ///
  /// In es, this message translates to:
  /// **'Ver reproductor'**
  String get showPlayer;

  /// No description provided for @songNeedsConnection.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: descárgala para escucharla sin red'**
  String get songNeedsConnection;

  /// No description provided for @refresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get refresh;

  /// No description provided for @shuffle.
  ///
  /// In es, this message translates to:
  /// **'Aleatorio'**
  String get shuffle;

  /// No description provided for @previous.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @play.
  ///
  /// In es, this message translates to:
  /// **'Reproducir'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get pause;

  /// No description provided for @repeatOff.
  ///
  /// In es, this message translates to:
  /// **'Repetir: desactivado'**
  String get repeatOff;

  /// No description provided for @repeatAll.
  ///
  /// In es, this message translates to:
  /// **'Repetir todo'**
  String get repeatAll;

  /// No description provided for @repeatOne.
  ///
  /// In es, this message translates to:
  /// **'Repetir esta canción'**
  String get repeatOne;

  /// No description provided for @uploadTitle.
  ///
  /// In es, this message translates to:
  /// **'Subir canción'**
  String get uploadTitle;

  /// No description provided for @themeToDark.
  ///
  /// In es, this message translates to:
  /// **'Cambiar a modo oscuro'**
  String get themeToDark;

  /// No description provided for @themeToLight.
  ///
  /// In es, this message translates to:
  /// **'Cambiar a modo claro'**
  String get themeToLight;

  /// No description provided for @uploadPickFile.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivo de audio'**
  String get uploadPickFile;

  /// No description provided for @uploadFileHint.
  ///
  /// In es, this message translates to:
  /// **'MP3, M4A, WAV o FLAC · hasta 10 MB'**
  String get uploadFileHint;

  /// No description provided for @uploadSongTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get uploadSongTitle;

  /// No description provided for @uploadGenre.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get uploadGenre;

  /// No description provided for @uploadGenreNone.
  ///
  /// In es, this message translates to:
  /// **'Sin género'**
  String get uploadGenreNone;

  /// No description provided for @uploadGenreSearch.
  ///
  /// In es, this message translates to:
  /// **'Escribe para buscar'**
  String get uploadGenreSearch;

  /// No description provided for @uploadGenreNoResults.
  ///
  /// In es, this message translates to:
  /// **'No hay géneros con ese nombre'**
  String get uploadGenreNoResults;

  /// No description provided for @uploadRights.
  ///
  /// In es, this message translates to:
  /// **'Declaro que soy el autor de esta canción o tengo los derechos para publicarla en dominio público (CC0): cualquiera podrá escucharla, compartirla y usarla libremente.'**
  String get uploadRights;

  /// No description provided for @uploadSubmit.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get uploadSubmit;

  /// No description provided for @uploadProgress.
  ///
  /// In es, this message translates to:
  /// **'Subiendo… {percent}%'**
  String uploadProgress(int percent);

  /// No description provided for @uploadDone.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! Tu canción se está procesando y aparecerá cuando esté lista.'**
  String get uploadDone;

  /// No description provided for @uploadErrorNoFile.
  ///
  /// In es, this message translates to:
  /// **'Elige un archivo de audio.'**
  String get uploadErrorNoFile;

  /// No description provided for @uploadErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe un título (máximo 120 caracteres).'**
  String get uploadErrorTitle;

  /// No description provided for @uploadErrorRights.
  ///
  /// In es, this message translates to:
  /// **'Debes declarar que tienes los derechos de la canción.'**
  String get uploadErrorRights;

  /// No description provided for @uploadErrorType.
  ///
  /// In es, this message translates to:
  /// **'Formato no soportado. Usa WAV, FLAC, MP3 o M4A.'**
  String get uploadErrorType;

  /// No description provided for @uploadErrorTooLarge.
  ///
  /// In es, this message translates to:
  /// **'El archivo supera los 10 MB. Prueba con MP3 o M4A.'**
  String get uploadErrorTooLarge;

  /// No description provided for @uploadErrorDailyLimit.
  ///
  /// In es, this message translates to:
  /// **'Llegaste al límite de subidas de hoy. Inténtalo mañana.'**
  String get uploadErrorDailyLimit;

  /// No description provided for @uploadErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Se perdió la conexión durante la subida. Inténtalo de nuevo.'**
  String get uploadErrorNetwork;

  /// No description provided for @uploadErrorUnknown.
  ///
  /// In es, this message translates to:
  /// **'No pudimos subir la canción. Inténtalo de nuevo.'**
  String get uploadErrorUnknown;

  /// No description provided for @uploadPickCover.
  ///
  /// In es, this message translates to:
  /// **'Elegir portada'**
  String get uploadPickCover;

  /// No description provided for @uploadCoverHint.
  ///
  /// In es, this message translates to:
  /// **'Cuadrada\nJPG, PNG o WebP · hasta 3 MB'**
  String get uploadCoverHint;

  /// No description provided for @uploadDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get uploadDescription;

  /// No description provided for @uploadDescriptionHint.
  ///
  /// In es, this message translates to:
  /// **'De qué trata, créditos, letra corta…'**
  String get uploadDescriptionHint;

  /// No description provided for @uploadErrorDescription.
  ///
  /// In es, this message translates to:
  /// **'La descripción supera los 500 caracteres.'**
  String get uploadErrorDescription;

  /// No description provided for @uploadErrorCoverType.
  ///
  /// In es, this message translates to:
  /// **'La portada debe ser JPG, PNG o WebP.'**
  String get uploadErrorCoverType;

  /// No description provided for @uploadErrorCoverTooLarge.
  ///
  /// In es, this message translates to:
  /// **'La portada supera los 3 MB.'**
  String get uploadErrorCoverTooLarge;

  /// No description provided for @downloads.
  ///
  /// In es, this message translates to:
  /// **'Descargas'**
  String get downloads;

  /// No description provided for @downloadsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes descargas.\nMantén presionada una canción para descargarla y escucharla sin señal.'**
  String get downloadsEmpty;

  /// No description provided for @downloadsSummary.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 canción} other{{count} canciones}} · {size}'**
  String downloadsSummary(int count, String size);

  /// No description provided for @downloadsDeleteAll.
  ///
  /// In es, this message translates to:
  /// **'Borrar todo'**
  String get downloadsDeleteAll;

  /// No description provided for @listeningCacheInfo.
  ///
  /// In es, this message translates to:
  /// **'Sonify guarda automáticamente en caché las canciones que escuchaste recientemente. Es similar al modo offline, con la única diferencia de que cuando se apague o se reinicie tu dispositivo se borrarán sin previo aviso. Si también quieres liberar espacio de las canciones en caché, puedes borrarlas con el botón Vaciar caché de Sonify.'**
  String get listeningCacheInfo;

  /// No description provided for @listeningCacheClear.
  ///
  /// In es, this message translates to:
  /// **'Vaciar caché de Sonify'**
  String get listeningCacheClear;

  /// No description provided for @listeningCacheClearConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Vaciar las canciones escuchadas que se guardaron solas? Tus descargas no se borran; lo demás volverá a usar la red.'**
  String get listeningCacheClearConfirm;

  /// No description provided for @downloadsDeleteAllConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar todas las descargas? Tendrás que volver a bajarlas para escucharlas sin señal.'**
  String get downloadsDeleteAllConfirm;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get delete;

  /// No description provided for @downloadSong.
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get downloadSong;

  /// No description provided for @downloadList.
  ///
  /// In es, this message translates to:
  /// **'Descargar toda la lista ({count})'**
  String downloadList(int count);

  /// No description provided for @downloadRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar descarga'**
  String get downloadRemove;

  /// No description provided for @downloadRemoveConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar «{title}» de tus descargas? Ya no podrás escucharla sin señal.'**
  String downloadRemoveConfirm(String title);

  /// No description provided for @downloadRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar descarga'**
  String get downloadRetry;

  /// No description provided for @downloadQueued.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Ya estaba descargado} =1{Descargando 1 canción (solo con Wi-Fi)} other{Descargando {count} canciones (solo con Wi-Fi)}}'**
  String downloadQueued(int count);

  /// No description provided for @downloadNoSpace.
  ///
  /// In es, this message translates to:
  /// **'No hay espacio: necesitas {required} y tienes {available} libres.'**
  String downloadNoSpace(String required, String available);

  /// No description provided for @downloadStateDone.
  ///
  /// In es, this message translates to:
  /// **'Descargada'**
  String get downloadStateDone;

  /// No description provided for @downloadStateQueued.
  ///
  /// In es, this message translates to:
  /// **'En cola'**
  String get downloadStateQueued;

  /// No description provided for @downloadStateFailed.
  ///
  /// In es, this message translates to:
  /// **'Falló la descarga'**
  String get downloadStateFailed;

  /// No description provided for @downloadProgress.
  ///
  /// In es, this message translates to:
  /// **'Descargando {percent}%'**
  String downloadProgress(int percent);

  /// No description provided for @uploadErrorNotAdmin.
  ///
  /// In es, this message translates to:
  /// **'Solo los administradores pueden subir canciones.'**
  String get uploadErrorNotAdmin;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get navSearch;

  /// No description provided for @navLibrary.
  ///
  /// In es, this message translates to:
  /// **'Tu biblioteca'**
  String get navLibrary;

  /// No description provided for @navLibraryShort.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get navLibraryShort;

  /// No description provided for @navPremium.
  ///
  /// In es, this message translates to:
  /// **'Premium'**
  String get navPremium;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Canción o artista'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In es, this message translates to:
  /// **'Busca en todo el catálogo por canción o artista y guarda las que quieras escuchar.'**
  String get searchPrompt;

  /// No description provided for @searchNoResults.
  ///
  /// In es, this message translates to:
  /// **'No encontramos «{query}».'**
  String searchNoResults(String query);

  /// No description provided for @searchError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos buscar. Inténtalo de nuevo.'**
  String get searchError;

  /// No description provided for @searchOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: buscando en lo que tienes en el teléfono.'**
  String get searchOffline;

  /// No description provided for @clearSearch.
  ///
  /// In es, this message translates to:
  /// **'Borrar búsqueda'**
  String get clearSearch;

  /// No description provided for @librarySavedSongs.
  ///
  /// In es, this message translates to:
  /// **'Tus canciones'**
  String get librarySavedSongs;

  /// No description provided for @librarySongCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin canciones} =1{1 canción} other{{count} canciones}}'**
  String librarySongCount(int count);

  /// No description provided for @librarySongCountLimit.
  ///
  /// In es, this message translates to:
  /// **'{count} de {limit} canciones'**
  String librarySongCountLimit(int count, int limit);

  /// No description provided for @libraryPlaylists.
  ///
  /// In es, this message translates to:
  /// **'Playlists'**
  String get libraryPlaylists;

  /// No description provided for @libraryNewPlaylist.
  ///
  /// In es, this message translates to:
  /// **'Nueva playlist'**
  String get libraryNewPlaylist;

  /// No description provided for @libraryPlaylistsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Crea una playlist para separar tus canciones, por ejemplo «Para el auto».'**
  String get libraryPlaylistsEmpty;

  /// No description provided for @librarySongsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no guardaste canciones.\nBúscalas en Buscar y guárdalas para escucharlas.'**
  String get librarySongsEmpty;

  /// No description provided for @libraryPlaylistEmpty.
  ///
  /// In es, this message translates to:
  /// **'Mantén presionada una canción y elige «Agregar a una playlist».'**
  String get libraryPlaylistEmpty;

  /// No description provided for @libraryError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu biblioteca.'**
  String get libraryError;

  /// No description provided for @playlistName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la playlist'**
  String get playlistName;

  /// No description provided for @playlistCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get playlistCreate;

  /// No description provided for @playlistRename.
  ///
  /// In es, this message translates to:
  /// **'Cambiar nombre'**
  String get playlistRename;

  /// No description provided for @playlistSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get playlistSave;

  /// No description provided for @playlistDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar playlist'**
  String get playlistDelete;

  /// No description provided for @playlistDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar «{name}»? Las canciones siguen en tu biblioteca.'**
  String playlistDeleteConfirm(String name);

  /// No description provided for @playlistMore.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get playlistMore;

  /// No description provided for @songSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar en tu biblioteca'**
  String get songSave;

  /// No description provided for @songUnsave.
  ///
  /// In es, this message translates to:
  /// **'Quitar de tu biblioteca'**
  String get songUnsave;

  /// No description provided for @songSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardada en tu biblioteca'**
  String get songSaved;

  /// No description provided for @songUnsaved.
  ///
  /// In es, this message translates to:
  /// **'Quitada de tu biblioteca'**
  String get songUnsaved;

  /// No description provided for @songSavedTooltip.
  ///
  /// In es, this message translates to:
  /// **'Guardada'**
  String get songSavedTooltip;

  /// No description provided for @songAddToPlaylist.
  ///
  /// In es, this message translates to:
  /// **'Agregar a una playlist'**
  String get songAddToPlaylist;

  /// No description provided for @songAddedToPlaylist.
  ///
  /// In es, this message translates to:
  /// **'Agregada a «{name}»'**
  String songAddedToPlaylist(String name);

  /// No description provided for @songRemoveFromPlaylist.
  ///
  /// In es, this message translates to:
  /// **'Quitar de esta playlist'**
  String get songRemoveFromPlaylist;

  /// No description provided for @libraryRemaining.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{No te quedan lugares} =1{Te queda 1 de {limit}} other{Te quedan {count} de {limit}}}'**
  String libraryRemaining(int count, int limit);

  /// No description provided for @libraryErrorLimit.
  ///
  /// In es, this message translates to:
  /// **'Llegaste a {limit} canciones. Quita alguna de tu biblioteca o hazte Premium.'**
  String libraryErrorLimit(int limit);

  /// No description provided for @libraryErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Necesitas conexión para cambiar tu biblioteca.'**
  String get libraryErrorNetwork;

  /// No description provided for @libraryErrorName.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre de hasta 60 caracteres.'**
  String get libraryErrorName;

  /// No description provided for @libraryErrorUnknown.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el cambio. Inténtalo de nuevo.'**
  String get libraryErrorUnknown;

  /// No description provided for @seePremium.
  ///
  /// In es, this message translates to:
  /// **'Ver Premium'**
  String get seePremium;

  /// No description provided for @lockedTitle.
  ///
  /// In es, this message translates to:
  /// **'Guárdala para escucharla'**
  String get lockedTitle;

  /// No description provided for @lockedBody.
  ///
  /// In es, this message translates to:
  /// **'Con la cuenta gratis escuchas hasta {limit} canciones guardadas, con todo: streaming, sin señal y en segundo plano.'**
  String lockedBody(int limit);

  /// No description provided for @lockedFull.
  ///
  /// In es, this message translates to:
  /// **'Ya guardaste {limit} canciones. Quita alguna de tu biblioteca o hazte Premium para escuchar sin límite.'**
  String lockedFull(int limit);

  /// No description provided for @lockedTooltip.
  ///
  /// In es, this message translates to:
  /// **'Guardar para escuchar'**
  String get lockedTooltip;

  /// No description provided for @premiumTitle.
  ///
  /// In es, this message translates to:
  /// **'Sonify Premium'**
  String get premiumTitle;

  /// No description provided for @premiumActive.
  ///
  /// In es, this message translates to:
  /// **'Eres Premium'**
  String get premiumActive;

  /// No description provided for @premiumActiveBody.
  ///
  /// In es, this message translates to:
  /// **'Guarda y escucha todas las canciones que quieras, también sin señal y en segundo plano.'**
  String get premiumActiveBody;

  /// No description provided for @premiumFreeIntro.
  ///
  /// In es, this message translates to:
  /// **'Sin Premium puedes guardar hasta {limit} canciones, y con ellas tienes todos los beneficios:'**
  String premiumFreeIntro(int limit);

  /// No description provided for @premiumBenefitStreaming.
  ///
  /// In es, this message translates to:
  /// **'Streaming en alta calidad'**
  String get premiumBenefitStreaming;

  /// No description provided for @premiumBenefitOffline.
  ///
  /// In es, this message translates to:
  /// **'Escuchar sin señal (descargas)'**
  String get premiumBenefitOffline;

  /// No description provided for @premiumBenefitBackground.
  ///
  /// In es, this message translates to:
  /// **'Escuchar en segundo plano y con la pantalla bloqueada'**
  String get premiumBenefitBackground;

  /// No description provided for @premiumBenefitPlaylists.
  ///
  /// In es, this message translates to:
  /// **'Tus propias playlists'**
  String get premiumBenefitPlaylists;

  /// No description provided for @premiumWithPremium.
  ///
  /// In es, this message translates to:
  /// **'Con Premium'**
  String get premiumWithPremium;

  /// No description provided for @premiumUnlimited.
  ///
  /// In es, this message translates to:
  /// **'Canciones sin límite en tu biblioteca'**
  String get premiumUnlimited;

  /// No description provided for @premiumUsage.
  ///
  /// In es, this message translates to:
  /// **'Usas {count} de {limit}'**
  String premiumUsage(int count, int limit);

  /// No description provided for @premiumCta.
  ///
  /// In es, this message translates to:
  /// **'Hazte Premium · {price} al mes'**
  String premiumCta(String price);

  /// No description provided for @premiumSoon.
  ///
  /// In es, this message translates to:
  /// **'Muy pronto podrás suscribirte desde la app.'**
  String get premiumSoon;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
