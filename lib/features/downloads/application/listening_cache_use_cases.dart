import '../../player/domain/local_audio.dart';

/// Cuánto ocupa la caché de lo escuchado, en bytes.
final class ListeningCacheUsage {
  const ListeningCacheUsage(this._cache);

  final ListeningCache _cache;

  Future<int> call() => _cache.usedBytes();
}

/// "Vaciar" en Descargas: borra lo escuchado guardado (no las descargas).
final class ClearListeningCache {
  const ClearListeningCache(this._cache);

  final ListeningCache _cache;

  Future<void> call() => _cache.clear();
}
