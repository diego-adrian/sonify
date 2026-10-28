import '../../../core/result.dart';
import 'catalog_failure.dart';
import 'genre.dart';
import 'song.dart';

/// Puerto del catálogo público.
abstract interface class CatalogRepository {
  Future<Result<List<Genre>, CatalogFailure>> getGenres();

  /// Canciones publicadas, las más recientes primero. [genreId] nulo = todas.
  Future<Result<List<Song>, CatalogFailure>> getSongs({
    int? genreId,
    int limit = 30,
    int offset = 0,
  });
}
