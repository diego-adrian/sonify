import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/application/sign_in.dart';
import '../../features/auth/application/sign_out.dart';
import '../../features/auth/application/watch_auth_state.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/infrastructure/fake_auth_repository.dart';
import '../../features/auth/infrastructure/supabase_auth_repository.dart';
import '../../features/catalog/application/get_genres.dart';
import '../../features/catalog/application/get_songs.dart';
import '../../features/catalog/domain/catalog_repository.dart';
import '../../features/catalog/infrastructure/offline_fallback_catalog_repository.dart';
import '../../features/catalog/infrastructure/supabase_catalog_repository.dart';
import '../../features/downloads/application/download_use_cases.dart';
import '../../features/downloads/application/listening_cache_use_cases.dart';
import '../../features/downloads/domain/download_ports.dart';
import '../../features/downloads/infrastructure/background_download_repository.dart';
import '../../features/downloads/infrastructure/device_storage.dart';
import '../../features/downloads/infrastructure/download_key_store.dart';
import '../../features/downloads/infrastructure/encrypted_listening_cache.dart';
import '../../features/downloads/infrastructure/listening_cache_database.dart';
import '../../features/library/application/library_use_cases.dart';
import '../../features/library/domain/library_repository.dart';
import '../../features/library/infrastructure/offline_library_repository.dart';
import '../../features/library/infrastructure/supabase_library_repository.dart';
import '../../features/player/application/playback_use_cases.dart';
import '../../features/player/domain/audio_player_port.dart';
import '../../features/player/domain/local_audio.dart';
import '../../features/player/infrastructure/audio_service_player.dart';
import '../../features/player/infrastructure/sonify_audio_handler.dart';
import '../../features/upload/application/upload_song.dart';
import '../../features/upload/domain/upload_ports.dart';
import '../../features/upload/infrastructure/file_picker_audio_picker.dart';
import '../../features/upload/infrastructure/file_picker_cover_picker.dart';
import '../../features/upload/infrastructure/file_picker_temp_files.dart';
import '../../features/upload/infrastructure/supabase_upload_repository.dart';
import '../config/app_config.dart';
import '../network/connectivity_network_status.dart';
import '../network/network_status.dart';
import '../theme/theme_preference.dart';

// Composition root: el único lugar que conecta puertos con adaptadores.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.hasSupabase && AppConfig.hasGoogle) {
    return SupabaseAuthRepository(
      auth: Supabase.instance.client.auth,
      googleSignIn: GoogleSignIn.instance,
      googleIosClientId: AppConfig.googleIosClientId,
      googleWebClientId: AppConfig.googleWebClientId,
    );
  }

  // Solo en desarrollo, mientras falte configurar Supabase o Google.
  if (kReleaseMode) {
    throw StateError('Falta la configuración de Supabase/Google.');
  }
  debugPrint('AuthRepository: usando FakeAuthRepository (falta config).');
  final repository = FakeAuthRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

/// Modo claro/oscuro elegido a mano.
final themePreferenceProvider = Provider<ThemePreference>(
  (ref) => SharedPreferencesThemePreference(),
);

final networkStatusProvider = Provider<NetworkStatus>(
  (ref) => ConnectivityNetworkStatus(Connectivity()),
);

final signInProvider = Provider(
  (ref) => SignIn(ref.watch(authRepositoryProvider)),
);

final signOutProvider = Provider(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

final authStateProvider = StreamProvider<AppUser?>(
  (ref) => WatchAuthState(ref.watch(authRepositoryProvider))(),
);

/// El catálogo en Supabase, sin el respaldo offline (también renueva las
/// URLs firmadas de las descargas que esperaron demasiado).
final remoteCatalogProvider = Provider(
  (ref) => SupabaseCatalogRepository(
    Supabase.instance.client,
    cdnBaseUrl: AppConfig.cdnBaseUrl,
  ),
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => OfflineFallbackCatalogRepository(
    ref.watch(remoteCatalogProvider),
    ref.watch(downloadRepositoryProvider),
    cache: ref.watch(listeningCacheProvider),
  ),
);

final getGenresProvider = Provider(
  (ref) => GetGenres(ref.watch(catalogRepositoryProvider)),
);

final getSongsProvider = Provider(
  (ref) => GetSongs(ref.watch(catalogRepositoryProvider)),
);

final searchSongsProvider = Provider(
  (ref) => SearchSongs(ref.watch(catalogRepositoryProvider)),
);

/// Se crea en `main` con `AudioService.init` y se inyecta con un override.
final audioHandlerProvider = Provider<SonifyAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider se inyecta en main'),
);

final audioPlayerProvider = Provider<AudioPlayerPort>((ref) {
  final player = AudioServicePlayer(
    ref.watch(audioHandlerProvider),
    // Se leen al reproducir: cambian con la sesión sin recrear el reproductor.
    () => ref.read(localAudioLibraryProvider),
    () => ref.read(listeningCacheProvider),
  );
  ref.onDispose(player.dispose);
  return player;
});

final watchPlaybackProvider = Provider(
  (ref) => WatchPlayback(ref.watch(audioPlayerProvider)),
);
final watchPositionProvider = Provider(
  (ref) => WatchPosition(ref.watch(audioPlayerProvider)),
);
final playSongsProvider = Provider(
  (ref) => PlaySongs(ref.watch(audioPlayerProvider)),
);
final updateQueueSongsProvider = Provider(
  (ref) => UpdateQueueSongs(ref.watch(audioPlayerProvider)),
);
final togglePlaybackProvider = Provider(
  (ref) => TogglePlayback(ref.watch(audioPlayerProvider)),
);
final seekToProvider = Provider(
  (ref) => SeekTo(ref.watch(audioPlayerProvider)),
);
final skipToNextProvider = Provider(
  (ref) => SkipToNext(ref.watch(audioPlayerProvider)),
);
final skipToPreviousProvider = Provider(
  (ref) => SkipToPrevious(ref.watch(audioPlayerProvider)),
);
final skipToSongProvider = Provider(
  (ref) => SkipToSong(ref.watch(audioPlayerProvider)),
);
final cycleRepeatProvider = Provider(
  (ref) => CycleRepeat(ref.watch(audioPlayerProvider)),
);
final setShuffleProvider = Provider(
  (ref) => SetShuffle(ref.watch(audioPlayerProvider)),
);
final stopPlaybackProvider = Provider(
  (ref) => StopPlayback(ref.watch(audioPlayerProvider)),
);

final audioFilePickerProvider = Provider<AudioFilePicker>(
  (ref) => const FilePickerAudioPicker(),
);

final coverImagePickerProvider = Provider<CoverImagePicker>(
  (ref) => const FilePickerCoverPicker(),
);

final uploadRepositoryProvider = Provider<UploadRepository>(
  (ref) => SupabaseUploadRepository(Supabase.instance.client.functions),
);

final uploadTempFilesProvider = Provider<UploadTempFiles>(
  (ref) => const FilePickerTempFiles(),
);

final uploadSongProvider = Provider(
  (ref) => UploadSong(
    ref.watch(uploadRepositoryProvider),
    ref.watch(uploadTempFilesProvider),
  ),
);

final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider.select((state) => state.value?.id)),
);

/// Descargas del usuario con sesión (carpeta, base y clave propias). Un solo
/// adaptador hace de repositorio de descargas y de biblioteca local para el
/// reproductor. Cambia de usuario al cambiar la sesión.
final backgroundDownloadsProvider = Provider<BackgroundDownloadRepository?>((
  ref,
) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  final repository = BackgroundDownloadRepository(
    userId: userId,
    refresher: ref.watch(remoteCatalogProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final downloadRepositoryProvider = Provider<DownloadRepository>(
  (ref) => ref.watch(backgroundDownloadsProvider) ?? const SignedOutDownloads(),
);

final localAudioLibraryProvider = Provider<LocalAudioLibrary>(
  (ref) =>
      ref.watch(backgroundDownloadsProvider) ?? const EmptyLocalAudioLibrary(),
);

/// Caché de lo escuchado del usuario con sesión (cifrada, 300 MB).
final listeningCacheProvider = Provider<ListeningCache>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const NoListeningCache();
  final keys = DownloadKeyStore(userId, purpose: 'cache');
  final cache = EncryptedListeningCache(
    root: () async => p.join(
      (await getApplicationSupportDirectory()).path,
      'downloads',
      'users',
      userId,
      'cache',
    ),
    key: keys.key,
    // La caché nunca deja al teléfono sin espacio.
    freeBytes: ref.watch(storageSpaceProvider).freeBytes,
    openDatabase: (root) => ListeningCacheDatabase(
      driftDatabase(
        name: 'cache',
        native: DriftNativeOptions(databaseDirectory: () async => root),
      ),
    ),
  );
  ref.onDispose(cache.dispose);
  return cache;
});

final listeningCacheUsageProvider = Provider(
  (ref) => ListeningCacheUsage(ref.watch(listeningCacheProvider)),
);
final clearListeningCacheProvider = Provider(
  (ref) => ClearListeningCache(ref.watch(listeningCacheProvider)),
);

final storageSpaceProvider = Provider<StorageSpace>(
  (ref) =>
      DeviceStorage(() async => (await getApplicationSupportDirectory()).path),
);

final downloadSongsProvider = Provider(
  (ref) => DownloadSongs(
    ref.watch(downloadRepositoryProvider),
    ref.watch(storageSpaceProvider),
  ),
);
final removeDownloadProvider = Provider(
  (ref) => RemoveDownload(ref.watch(downloadRepositoryProvider)),
);
final suspendDownloadsProvider = Provider(
  (ref) => SuspendDownloads(ref.watch(downloadRepositoryProvider)),
);
final clearDownloadsProvider = Provider(
  (ref) => ClearDownloads(ref.watch(downloadRepositoryProvider)),
);
final watchDownloadsProvider = Provider(
  (ref) => WatchDownloads(ref.watch(downloadRepositoryProvider)),
);
final watchDownloadProgressProvider = Provider(
  (ref) => WatchDownloadProgress(ref.watch(downloadRepositoryProvider)),
);

/// Biblioteca del usuario con sesión, con copia local para usarla sin red.
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const SignedOutLibraryRepository();
  return OfflineLibraryRepository(
    SupabaseLibraryRepository(
      Supabase.instance.client,
      cdnBaseUrl: AppConfig.cdnBaseUrl,
    ),
    snapshot: () async => File(
      p.join(
        (await getApplicationSupportDirectory()).path,
        'downloads',
        'users',
        userId,
        'library.json',
      ),
    ),
  );
});

final loadLibraryProvider = Provider(
  (ref) => LoadLibrary(ref.watch(libraryRepositoryProvider)),
);
final saveSongProvider = Provider(
  (ref) => SaveSong(ref.watch(libraryRepositoryProvider)),
);
final removeFromLibraryProvider = Provider(
  (ref) => RemoveFromLibrary(
    ref.watch(libraryRepositoryProvider),
    ref.watch(downloadRepositoryProvider),
  ),
);
final createPlaylistProvider = Provider(
  (ref) => CreatePlaylist(ref.watch(libraryRepositoryProvider)),
);
final renamePlaylistProvider = Provider(
  (ref) => RenamePlaylist(ref.watch(libraryRepositoryProvider)),
);
final deletePlaylistProvider = Provider(
  (ref) => DeletePlaylist(ref.watch(libraryRepositoryProvider)),
);
final addToPlaylistProvider = Provider(
  (ref) => AddToPlaylist(ref.watch(libraryRepositoryProvider)),
);
final removeFromPlaylistProvider = Provider(
  (ref) => RemoveFromPlaylist(ref.watch(libraryRepositoryProvider)),
);
