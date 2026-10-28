import '../../../core/result.dart';
import '../../catalog/domain/song.dart';
import '../domain/download_entry.dart';
import '../domain/download_failure.dart';
import '../domain/download_ports.dart';

/// Encola [songs] para escuchar sin red. Omite las que no tienen audio o ya
/// están descargadas/en cola, y comprueba antes que haya espacio para todo el
/// lote. Devuelve cuántas se encolaron.
final class DownloadSongs {
  const DownloadSongs(this._downloads, this._space);

  /// Margen que se deja libre para el sistema.
  static const reserveBytes = 200 * 1024 * 1024;

  /// Para estimar el tamaño cuando el catálogo no lo trae (AAC 128 kbps).
  static const estimatedBitsPerSecond = 128000;

  final DownloadRepository _downloads;
  final StorageSpace _space;

  Future<Result<int, DownloadFailure>> call(List<Song> songs) async {
    final active = await _downloads.activeSongIds();
    final seen = <String>{};
    final pending = [
      for (final song in songs)
        if (song.audio != null &&
            !active.contains(song.id) &&
            seen.add(song.id))
          song,
    ];
    if (pending.isEmpty) return const Ok(0);

    final required = pending.fold<int>(0, (sum, song) => sum + estimate(song));
    final free = await _space.freeBytes();
    if (free != null && free - reserveBytes < required) {
      return Err(
        NotEnoughSpace(
          requiredBytes: required,
          availableBytes: free < reserveBytes ? 0 : free - reserveBytes,
        ),
      );
    }

    await _downloads.enqueue(pending);
    return Ok(pending.length);
  }

  static int estimate(Song song) =>
      song.audioSizeBytes ??
      song.duration.inSeconds * estimatedBitsPerSecond ~/ 8;
}

final class RemoveDownload {
  const RemoveDownload(this._downloads);

  final DownloadRepository _downloads;

  Future<void> call(String songId) => _downloads.remove(songId);
}

/// Al cerrar sesión: lo descargado se conserva para cuando vuelva a entrar.
final class SuspendDownloads {
  const SuspendDownloads(this._downloads);

  final DownloadRepository _downloads;

  Future<void> call() => _downloads.suspend();
}

/// "Borrar todo" en la pantalla de Descargas.
final class ClearDownloads {
  const ClearDownloads(this._downloads);

  final DownloadRepository _downloads;

  Future<void> call() => _downloads.removeAll();
}

final class WatchDownloads {
  const WatchDownloads(this._downloads);

  final DownloadRepository _downloads;

  Stream<List<DownloadEntry>> call() => _downloads.watchAll();
}

final class WatchDownloadProgress {
  const WatchDownloadProgress(this._downloads);

  final DownloadRepository _downloads;

  Stream<Map<String, double>> call() => _downloads.watchProgress();
}
