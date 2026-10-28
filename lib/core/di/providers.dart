import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
import '../../features/catalog/infrastructure/in_memory_catalog_repository.dart';
import '../../features/downloads/application/download_use_cases.dart';
import '../../features/downloads/domain/download_ports.dart';
import '../../features/downloads/infrastructure/background_download_repository.dart';
import '../../features/downloads/infrastructure/device_storage.dart';
import '../../features/player/application/playback_use_cases.dart';
import '../../features/player/domain/audio_player_port.dart';
import '../../features/player/domain/local_audio.dart';
import '../../features/player/infrastructure/audio_service_player.dart';
import '../../features/player/infrastructure/sonify_audio_handler.dart';
import '../../features/upload/application/upload_song.dart';
import '../../features/upload/domain/upload_ports.dart';
import '../../features/upload/infrastructure/file_picker_audio_picker.dart';
import '../../features/upload/infrastructure/file_picker_cover_picker.dart';
import '../../features/upload/infrastructure/supabase_upload_repository.dart';
import '../config/app_config.dart';

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

final signInProvider = Provider(
  (ref) => SignIn(ref.watch(authRepositoryProvider)),
);

final signOutProvider = Provider(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

final authStateProvider = StreamProvider<AppUser?>(
  (ref) => WatchAuthState(ref.watch(authRepositoryProvider))(),
);

// TODO: reemplazar por el adaptador de Supabase cuando haya canciones reales.
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => const InMemoryCatalogRepository(),
);

final getGenresProvider = Provider(
  (ref) => GetGenres(ref.watch(catalogRepositoryProvider)),
);

final getSongsProvider = Provider(
  (ref) => GetSongs(ref.watch(catalogRepositoryProvider)),
);

/// Se crea en `main` con `AudioService.init` y se inyecta con un override.
final audioHandlerProvider = Provider<SonifyAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider se inyecta en main'),
);

final audioPlayerProvider = Provider<AudioPlayerPort>((ref) {
  final player = AudioServicePlayer(
    ref.watch(audioHandlerProvider),
    // Se lee al reproducir: cambia con la sesión sin recrear el reproductor.
    () => ref.read(localAudioLibraryProvider),
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

final uploadSongProvider = Provider(
  (ref) => UploadSong(ref.watch(uploadRepositoryProvider)),
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
  final repository = BackgroundDownloadRepository(userId: userId);
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
