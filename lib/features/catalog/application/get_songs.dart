import '../../../core/result.dart';
import '../domain/catalog_failure.dart';
import '../domain/catalog_repository.dart';
import '../domain/song.dart';

final class GetSongs {
  const GetSongs(this._repository);

  final CatalogRepository _repository;

  Future<Result<List<Song>, CatalogFailure>> call({
    int? genreId,
    int limit = 30,
    int offset = 0,
  }) => _repository.getSongs(genreId: genreId, limit: limit, offset: offset);
}
