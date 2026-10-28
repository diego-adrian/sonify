import '../../../core/result.dart';
import '../../downloads/domain/download_entry.dart';
import '../../downloads/domain/download_ports.dart';
import '../domain/catalog_failure.dart';
import '../domain/catalog_repository.dart';
import '../domain/genre.dart';
import '../domain/song.dart';

/// Sin red (sótanos, locales), el catálogo muestra lo descargado en lugar de
/// un error. La UI no sabe de dónde vienen las canciones.
final class OfflineFallbackCatalogRepository implements CatalogRepository {
  const OfflineFallbackCatalogRepository(this._remote, this._downloads);

  final CatalogRepository _remote;
  final DownloadRepository _downloads;

  @override
  Future<Result<List<Genre>, CatalogFailure>> getGenres() =>
      _remote.getGenres();

  @override
  Future<Result<List<Song>, CatalogFailure>> getSongs({
    int? genreId,
    int limit = 30,
    int offset = 0,
  }) async {
    final remote = await _remote.getSongs(
      genreId: genreId,
      limit: limit,
      offset: offset,
    );
    if (remote case Err(error: CatalogFailure.network)) {
      final entries = await _downloads.watchAll().first;
      return Ok(
        [
          for (final entry in entries)
            if (entry.state == DownloadState.done &&
                (genreId == null || entry.song.genreId == genreId))
              entry.song,
        ].skip(offset).take(limit).toList(growable: false),
      );
    }
    return remote;
  }
}
