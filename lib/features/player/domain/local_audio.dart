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
