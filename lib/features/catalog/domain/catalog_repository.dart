import '../../../core/result.dart';
import 'catalog_failure.dart';
import 'catalog_page.dart';
import 'genre.dart';

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
}
