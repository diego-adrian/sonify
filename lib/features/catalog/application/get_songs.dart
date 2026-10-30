import '../../../core/result.dart';
import '../domain/catalog_failure.dart';
import '../domain/catalog_page.dart';
import '../domain/catalog_repository.dart';
import '../domain/song.dart';

final class GetSongs {
  const GetSongs(this._repository);

  final CatalogRepository _repository;

  Future<Result<CatalogPage, CatalogFailure>> call({
    int? genreId,
    int limit = catalogPageSize,
    SongCursor? after,
  }) => _repository.getSongs(genreId: genreId, limit: limit, after: after);
}

final class SearchSongs {
  const SearchSongs(this._repository);

  /// Menos letras devuelve medio catálogo: no vale la petición.
  static const minQueryLength = 2;

  final CatalogRepository _repository;

  Future<Result<List<Song>, CatalogFailure>> call(String query) {
    final trimmed = query.trim();
    if (trimmed.length < minQueryLength) return Future.value(const Ok([]));
    return _repository.searchSongs(trimmed);
  }
}
