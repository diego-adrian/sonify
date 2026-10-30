import '../../../core/result.dart';
import 'catalog_failure.dart';
import 'catalog_page.dart';
import 'genre.dart';
import 'song.dart';

/// Puerto del catálogo público.
abstract interface class CatalogRepository {
  Future<Result<List<Genre>, CatalogFailure>> getGenres();

  /// Canciones publicadas, las más recientes primero, de a [limit].
  /// [after] nulo = primera página; [genreId] nulo = todas.
  Future<Result<CatalogPage, CatalogFailure>> getSongs({
    int? genreId,
    int limit = catalogPageSize,
    SongCursor? after,
  });

  /// Busca en todo el catálogo por título o artista. Así se encuentra una
  /// canción antes de subirla otra vez, y se guarda en la biblioteca.
  Future<Result<List<Song>, CatalogFailure>> searchSongs(String query);
}
