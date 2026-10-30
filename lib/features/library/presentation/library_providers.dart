import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/lifecycle/app_lifecycle_provider.dart';
import '../../../core/network/online_provider.dart';
import '../../../core/result.dart';
import '../../catalog/domain/song.dart';
import '../../downloads/presentation/downloads_providers.dart';
import '../domain/library.dart';
import '../domain/library_repository.dart';

/// Pasado este tiempo, volver a la app recarga la biblioteca (URLs firmadas
/// frescas y cambios hechos en otro dispositivo).
const libraryMaxAge = Duration(minutes: 10);

/// Biblioteca del usuario con sesión. Se recarga al recuperar la red, al
/// volver a la app tras [libraryMaxAge] y después de cada cambio (así trae
/// el audio firmado de lo recién guardado). Nada de consultas periódicas.
final libraryProvider = AsyncNotifierProvider<LibraryNotifier, Library>(
  LibraryNotifier.new,
);

class LibraryNotifier extends AsyncNotifier<Library> {
  @override
  Future<Library> build() async {
    final loadedAt = DateTime.now();
    ref.listen(appResumedProvider, (_, resumed) {
      if (resumed && DateTime.now().difference(loadedAt) > libraryMaxAge) {
        ref.invalidateSelf();
      }
    });
    ref.listen(isOnlineProvider, (wasOnline, online) {
      if (wasOnline == false && online) ref.invalidateSelf();
    });
    return switch (await ref.watch(loadLibraryProvider)()) {
      Ok(:final value) => value,
      Err(:final error) => throw error,
    };
  }

  Library get _current => state.value ?? Library.empty;

  /// Cada acción devuelve `null` si salió bien o el motivo del fallo.
  Future<LibraryFailure?> save(String songId) =>
      _mutate(ref.read(saveSongProvider)(_current, songId));

  Future<LibraryFailure?> remove(String songId) =>
      _mutate(ref.read(removeFromLibraryProvider)(_current, songId));

  Future<LibraryFailure?> createPlaylist(String name) =>
      _mutate(ref.read(createPlaylistProvider)(name));

  Future<LibraryFailure?> renamePlaylist(String id, String name) =>
      _mutate(ref.read(renamePlaylistProvider)(id, name));

  Future<LibraryFailure?> deletePlaylist(String id) =>
      _mutate(ref.read(deletePlaylistProvider)(id));

  Future<LibraryFailure?> addToPlaylist(String playlistId, String songId) =>
      _mutate(ref.read(addToPlaylistProvider)(_current, playlistId, songId));

  Future<LibraryFailure?> removeFromPlaylist(
    String playlistId,
    String songId,
  ) => _mutate(ref.read(removeFromPlaylistProvider)(playlistId, songId));

  Future<LibraryFailure?> _mutate(
    Future<Result<void, LibraryFailure>> action,
  ) async {
    final result = await action;
    if (result case Err(:final error)) return error;
    final reloaded = await ref.read(loadLibraryProvider)();
    if (!ref.mounted) return null;
    if (reloaded case Ok(:final value)) state = AsyncData(value);
    return null;
  }
}

/// La biblioteca o, mientras carga por primera vez, una vacía que no limita
/// nada (el backend igual no firma el audio de lo que no se puede escuchar).
final currentLibraryProvider = Provider<Library>(
  (ref) => ref.watch(libraryProvider).value ?? Library.empty,
);

final accountProvider = Provider<Account>(
  (ref) =>
      ref.watch(currentLibraryProvider.select((library) => library.account)),
);

/// Qué canciones puede reproducir el usuario.
final songAccessProvider = Provider<SongAccess>((ref) {
  final known = ref.watch(libraryProvider).hasValue;
  return SongAccess(
    ref.watch(currentLibraryProvider),
    known: known,
    local: {
      for (final song in ref.watch(downloadedSongsProvider)) song.id,
      for (final song in ref.watch(cachedSongsProvider).value ?? const <Song>[])
        song.id,
    },
  );
});

final class SongAccess {
  const SongAccess(this._library, {required this.known, required this.local});

  final Library _library;

  /// `false` mientras la biblioteca no llegó nunca (ni la copia local).
  final bool known;

  /// Descargadas o en la caché de lo escuchado.
  final Set<String> local;

  /// Gratis solo escucha lo que guardó; premium, todo. Además tiene que haber
  /// de dónde sacar el audio: la URL firmada (que el backend solo emite si
  /// puede escucharla) o una copia en el dispositivo.
  bool canPlay(Song song) =>
      (!known || _library.canPlay(song.id)) &&
      (song.audio != null || local.contains(song.id));

  /// La versión guardada (con el audio firmado) si está en la biblioteca.
  Song resolve(Song song) => _library.song(song.id) ?? song;
}
