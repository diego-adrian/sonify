import '../../../core/result.dart';
import '../../downloads/domain/download_ports.dart';
import '../domain/library.dart';
import '../domain/library_repository.dart';

/// Largo máximo del nombre de una playlist (igual que el check de la base).
const maxPlaylistNameLength = 60;

final class LoadLibrary {
  const LoadLibrary(this._repository);

  final LibraryRepository _repository;

  Future<Result<Library, LibraryFailure>> call() => _repository.load();
}

/// Guarda una canción del catálogo. Con la biblioteca llena (gratis) ni
/// siquiera pregunta al backend, que igual lo rechazaría.
final class SaveSong {
  const SaveSong(this._repository);

  final LibraryRepository _repository;

  Future<Result<void, LibraryFailure>> call(Library library, String songId) {
    if (library.contains(songId)) return Future.value(const Ok(null));
    if (library.isFull) {
      return Future.value(const Err(LibraryFailure.limitReached));
    }
    return _repository.saveSong(songId);
  }
}

/// Quita una canción de la biblioteca (y de sus playlists). En una cuenta
/// gratis también borra la descarga: sin guardarla ya no la puede escuchar.
final class RemoveFromLibrary {
  const RemoveFromLibrary(this._repository, this._downloads);

  final LibraryRepository _repository;
  final DownloadRepository _downloads;

  Future<Result<void, LibraryFailure>> call(
    Library library,
    String songId,
  ) async {
    final result = await _repository.removeSong(songId);
    if (result is Ok && !library.account.unlimited) {
      await _downloads.remove(songId);
    }
    return result;
  }
}

final class CreatePlaylist {
  const CreatePlaylist(this._repository);

  final LibraryRepository _repository;

  Future<Result<void, LibraryFailure>> call(String name) {
    final trimmed = name.trim();
    if (!_validName(trimmed)) {
      return Future.value(const Err(LibraryFailure.invalidName));
    }
    return _repository.createPlaylist(trimmed);
  }
}

final class RenamePlaylist {
  const RenamePlaylist(this._repository);

  final LibraryRepository _repository;

  Future<Result<void, LibraryFailure>> call(String id, String name) {
    final trimmed = name.trim();
    if (!_validName(trimmed)) {
      return Future.value(const Err(LibraryFailure.invalidName));
    }
    return _repository.renamePlaylist(id, trimmed);
  }
}

final class DeletePlaylist {
  const DeletePlaylist(this._repository);

  final LibraryRepository _repository;

  Future<Result<void, LibraryFailure>> call(String id) =>
      _repository.deletePlaylist(id);
}

/// Agregar a una playlist guarda la canción: con la biblioteca llena solo se
/// pueden agregar las ya guardadas.
final class AddToPlaylist {
  const AddToPlaylist(this._repository);

  final LibraryRepository _repository;

  Future<Result<void, LibraryFailure>> call(
    Library library,
    String playlistId,
    String songId,
  ) {
    if (!library.contains(songId) && library.isFull) {
      return Future.value(const Err(LibraryFailure.limitReached));
    }
    return _repository.addToPlaylist(playlistId, songId);
  }
}

final class RemoveFromPlaylist {
  const RemoveFromPlaylist(this._repository);

  final LibraryRepository _repository;

  Future<Result<void, LibraryFailure>> call(String playlistId, String songId) =>
      _repository.removeFromPlaylist(playlistId, songId);
}

bool _validName(String name) =>
    name.isNotEmpty && name.length <= maxPlaylistNameLength;
