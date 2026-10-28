import '../../../core/result.dart';
import '../domain/catalog_failure.dart';
import '../domain/catalog_repository.dart';
import '../domain/genre.dart';

final class GetGenres {
  const GetGenres(this._repository);

  final CatalogRepository _repository;

  Future<Result<List<Genre>, CatalogFailure>> call() => _repository.getGenres();
}
