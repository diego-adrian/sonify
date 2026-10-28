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

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

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

  /// No description provided for @tabSimilar.
  ///
  /// In es, this message translates to:
  /// **'Similares'**
  String get tabSimilar;

  /// No description provided for @tabUpNext.
  ///
  /// In es, this message translates to:
  /// **'A continuación'**
  String get tabUpNext;

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

  /// No description provided for @reorder.
  ///
  /// In es, this message translates to:
  /// **'Reordenar'**
  String get reorder;

  /// No description provided for @similarEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay canciones similares todavía.'**
  String get similarEmpty;

  /// No description provided for @upNextEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay más canciones en la cola.'**
  String get upNextEmpty;

  /// No description provided for @pause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get pause;

  /// No description provided for @showQueue.
  ///
  /// In es, this message translates to:
  /// **'Ver cola'**
  String get showQueue;

  /// No description provided for @uploadTitle.
  ///
  /// In es, this message translates to:
  /// **'Subir canción'**
  String get uploadTitle;

  /// No description provided for @uploadPickFile.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivo de audio'**
  String get uploadPickFile;

  /// No description provided for @uploadFileHint.
  ///
  /// In es, this message translates to:
  /// **'WAV, FLAC, MP3 o M4A · hasta 200 MB'**
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

  /// No description provided for @uploadLicense.
  ///
  /// In es, this message translates to:
  /// **'Licencia'**
  String get uploadLicense;

  /// No description provided for @licenseCc0.
  ///
  /// In es, this message translates to:
  /// **'CC0 · Dominio público'**
  String get licenseCc0;

  /// No description provided for @licenseCcBy.
  ///
  /// In es, this message translates to:
  /// **'CC BY · Atribución'**
  String get licenseCcBy;

  /// No description provided for @licenseCcBySa.
  ///
  /// In es, this message translates to:
  /// **'CC BY-SA · Atribución, compartir igual'**
  String get licenseCcBySa;

  /// No description provided for @licenseCcByNc.
  ///
  /// In es, this message translates to:
  /// **'CC BY-NC · Atribución, no comercial'**
  String get licenseCcByNc;

  /// No description provided for @licenseCcByNcSa.
  ///
  /// In es, this message translates to:
  /// **'CC BY-NC-SA · Atribución, no comercial, compartir igual'**
  String get licenseCcByNcSa;

  /// No description provided for @uploadRights.
  ///
  /// In es, this message translates to:
  /// **'Declaro que soy el autor de esta canción o tengo los derechos para publicarla con la licencia elegida.'**
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
  /// **'El archivo supera los 200 MB.'**
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
  /// **'Cuadrada, mín. 640 px\nJPG, PNG o WebP'**
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
  /// **'La portada supera los 10 MB.'**
  String get uploadErrorCoverTooLarge;

  /// No description provided for @uploadErrorCoverTooSmall.
  ///
  /// In es, this message translates to:
  /// **'La portada debe medir al menos 640 × 640 px.'**
  String get uploadErrorCoverTooSmall;

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
