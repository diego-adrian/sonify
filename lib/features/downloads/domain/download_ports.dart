import '../../catalog/domain/song.dart';
import 'download_entry.dart';

/// Descargas offline del usuario con sesión: archivos cifrados y solo
/// locales (sin respaldo en la nube), que siguen bajando con la app cerrada.
/// Se conservan al cerrar sesión y vuelven al entrar con la misma cuenta.
abstract interface class DownloadRepository {
  /// Todas las descargas, las más recientes primero.
  Stream<List<DownloadEntry>> watchAll();

  /// Avance (0–1) de las que están bajando, por id de canción.
  Stream<Map<String, double>> watchProgress();

  /// Canciones en cola o listas (las fallidas no cuentan).
  Future<Set<String>> activeSongIds();

  Future<void> enqueue(List<Song> songs);

  Future<void> remove(String songId);

  /// Borra todas las descargas del usuario y su clave de cifrado.
  Future<void> removeAll();

  /// Al cerrar sesión: detiene lo que está bajando (se retoma al volver a
  /// entrar) y conserva lo descargado.
  Future<void> suspend();
}

/// Sin sesión no hay descargas.
final class SignedOutDownloads implements DownloadRepository {
  const SignedOutDownloads();

  @override
  Stream<List<DownloadEntry>> watchAll() => Stream.value(const []);

  @override
  Stream<Map<String, double>> watchProgress() => Stream.value(const {});

  @override
  Future<Set<String>> activeSongIds() async => const {};

  @override
  Future<void> enqueue(List<Song> songs) async {}

  @override
  Future<void> remove(String songId) async {}

  @override
  Future<void> removeAll() async {}

  @override
  Future<void> suspend() async {}
}

abstract interface class StorageSpace {
  /// Bytes libres para la app, o `null` si no se puede saber.
  Future<int?> freeBytes();
}
