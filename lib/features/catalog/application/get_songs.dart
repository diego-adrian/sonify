import '../../../core/result.dart';
import '../domain/catalog_failure.dart';
import '../domain/catalog_page.dart';
import '../domain/catalog_repository.dart';

final class GetSongs {
  const GetSongs(this._repository);

  final CatalogRepository _repository;

  Future<Result<CatalogPage, CatalogFailure>> call({
    int? genreId,
    int limit = catalogPageSize,
    SongCursor? after,
  }) => _repository.getSongs(genreId: genreId, limit: limit, after: after);
}
