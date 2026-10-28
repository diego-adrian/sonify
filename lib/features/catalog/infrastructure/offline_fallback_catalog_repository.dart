import 'dart:async';

import '../../../core/result.dart';
import '../../downloads/domain/download_entry.dart';
import '../../downloads/domain/download_ports.dart';
import '../../player/domain/local_audio.dart';
import '../domain/catalog_failure.dart';
import '../domain/catalog_page.dart';
import '../domain/catalog_repository.dart';
import '../domain/genre.dart';

/// Sin red (sótanos, locales), el catálogo muestra lo descargado en lugar de
/// un error. La UI no sabe de dónde vienen las canciones.
///
/// Con señal débil la petición no falla: se queda colgada (el cliente HTTP no
/// trae timeout). Pasado [timeout] se trata como sin red. Cubre también la
/// renovación del token vencido, que Supabase reintenta hasta ~10 s antes de
/// hacer la consulta.
final class OfflineFallbackCatalogRepository implements CatalogRepository {
  const OfflineFallbackCatalogRepository(
    this._remote,
    this._downloads, {
    this.timeout = const Duration(seconds: 12),
    this._cache = const NoListeningCache(),
  });

  final CatalogRepository _remote;
  final DownloadRepository _downloads;

  /// Lo escuchado hace poco también suena sin red.
  final ListeningCache _cache;
  final Duration timeout;

  @override
  Future<Result<List<Genre>, CatalogFailure>> getGenres() =>
      _withTimeout(_remote.getGenres());

  /// Sin red, la primera página es todo lo descargado y luego lo que está en
  /// la caché de lo escuchado (ya está en el dispositivo: no se pagina). En las siguientes páginas el
  /// error se propaga: la lista ya visible se conserva y se puede reintentar.
  @override
  Future<Result<CatalogPage, CatalogFailure>> getSongs({
    int? genreId,
    int limit = catalogPageSize,
    SongCursor? after,
  }) async {
    final remote = await _withTimeout(
      _remote.getSongs(genreId: genreId, limit: limit, after: after),
    );
    if (remote case Err(error: CatalogFailure.network) when after == null) {
      final entries = await _downloads.watchAll().first;
      final downloaded = [
        for (final entry in entries)
          if (entry.state == DownloadState.done) entry.song,
      ];
      final ids = {for (final song in downloaded) song.id};
      final cached = await _cache.watchSongs().first;
      return Ok(
        CatalogPage([
          for (final song in [
            ...downloaded,
            ...cached.where((song) => !ids.contains(song.id)),
          ])
            if (genreId == null || song.genreId == genreId) song,
        ]),
      );
    }
    return remote;
  }

  Future<Result<T, CatalogFailure>> _withTimeout<T>(
    Future<Result<T, CatalogFailure>> request,
  ) => request.timeout(
    timeout,
    onTimeout: () => const Err(CatalogFailure.network),
  );
}
