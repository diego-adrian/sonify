import '../../../core/result.dart';
import 'library.dart';

enum LibraryFailure {
  /// Cuenta gratis con la biblioteca llena.
  limitReached,
  invalidName,
  network,
  unknown,
}

/// Puerto de la biblioteca del usuario con sesión.
abstract interface class LibraryRepository {
  /// Cuenta, canciones guardadas y playlists en una sola carga.
  Future<Result<Library, LibraryFailure>> load();

  Future<Result<void, LibraryFailure>> saveSong(String songId);

  /// También la quita de las playlists del usuario.
  Future<Result<void, LibraryFailure>> removeSong(String songId);

  Future<Result<void, LibraryFailure>> createPlaylist(String name);

  Future<Result<void, LibraryFailure>> renamePlaylist(String id, String name);

  Future<Result<void, LibraryFailure>> deletePlaylist(String id);

  /// La guarda en la biblioteca si no estaba (cuenta para el límite).
  Future<Result<void, LibraryFailure>> addToPlaylist(
    String playlistId,
    String songId,
  );

  Future<Result<void, LibraryFailure>> removeFromPlaylist(
    String playlistId,
    String songId,
  );
}
