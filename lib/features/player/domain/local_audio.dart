import '../../catalog/domain/song.dart';

/// Audio guardado en el dispositivo (p. ej. una descarga cifrada). El
/// reproductor lo lee por rangos, sin que el archivo en claro toque el disco.
abstract interface class LocalAudio {
  /// Tamaño del audio en claro, en bytes.
  int get length;

  String get contentType;

  /// Bytes en claro de [start] (incluido) a [end] (excluido), por bloques.
  Stream<List<int>> read(int start, int end);
}

/// Puerto para saber si una canción se puede reproducir sin red.
abstract interface class LocalAudioLibrary {
  Future<LocalAudio?> find(String songId);
}

/// Sin descargas (tests, plataformas sin almacenamiento local).
final class EmptyLocalAudioLibrary implements LocalAudioLibrary {
  const EmptyLocalAudioLibrary();

  @override
  Future<LocalAudio?> find(String songId) async => null;
}

/// Caché de lo escuchado por streaming: la canción se baja una vez mientras
/// suena y, si se escuchó lo suficiente, queda guardada (cifrada) para que
/// las siguientes veces no use la red. Tiene tope de espacio: al llenarse se
/// borra lo que hace más tiempo que no suena.
abstract interface class ListeningCache implements LocalAudioLibrary {
  /// Ruta temporal donde el reproductor deja el audio mientras lo baja.
  /// `null` si no se puede cachear (sin sesión, sin almacenamiento).
  Future<String?> tempPathFor(String songId);

  /// Canciones en caché, para mostrarlas y reproducirlas sin red.
  Stream<List<Song>> watchSongs();

  /// Estas no se borran al liberar espacio (la cola actual).
  void protect(Set<String> songIds);

  /// La canción dejó de sonar (o terminó una vuelta con repetir una).
  /// Si estaba en caché, cuenta como escuchada ahora. Si se bajó entera y
  /// [listenedEnough], se guarda. Si ya no es la actual ([stillCurrent]
  /// falso), se borra el temporal en claro.
  Future<void> finished(
    Song song, {
    required bool listenedEnough,
    required bool stillCurrent,
  });

  /// Borra los temporales en claro (nueva cola, stop).
  Future<void> clearTemporary();
}

/// Sin caché (sin sesión, tests).
final class NoListeningCache implements ListeningCache {
  const NoListeningCache();

  @override
  Future<LocalAudio?> find(String songId) async => null;

  @override
  Future<String?> tempPathFor(String songId) async => null;

  @override
  Stream<List<Song>> watchSongs() => Stream.value(const []);

  @override
  void protect(Set<String> songIds) {}

  @override
  Future<void> finished(
    Song song, {
    required bool listenedEnough,
    required bool stillCurrent,
  }) async {}

  @override
  Future<void> clearTemporary() async {}
}
