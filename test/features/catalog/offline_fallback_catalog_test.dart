import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/result.dart';
import 'package:sonify/features/catalog/domain/catalog_failure.dart';
import 'package:sonify/features/catalog/domain/catalog_repository.dart';
import 'package:sonify/features/catalog/domain/genre.dart';
import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/catalog/infrastructure/offline_fallback_catalog_repository.dart';
import 'package:sonify/features/downloads/domain/download_entry.dart';

import '../../helpers/fake_download_repository.dart';

final class _Remote implements CatalogRepository {
  _Remote(this.result);

  Result<List<Song>, CatalogFailure> result;

  @override
  Future<Result<List<Genre>, CatalogFailure>> getGenres() async => const Ok([]);

  @override
  Future<Result<List<Song>, CatalogFailure>> getSongs({
    int? genreId,
    int limit = 30,
    int offset = 0,
  }) async => result;
}

Song _song(String id, int genre) => Song(
  id: id,
  title: id,
  artistName: 'A',
  duration: const Duration(minutes: 3),
  genreId: genre,
);

void main() {
  test('sin red muestra lo descargado (del género pedido)', () async {
    final downloads = FakeDownloadRepository()
      ..entries.addAll([
        DownloadEntry(song: _song('done', 3), state: DownloadState.done),
        DownloadEntry(song: _song('queued', 3), state: DownloadState.queued),
        DownloadEntry(song: _song('other', 1), state: DownloadState.done),
      ]);
    final catalog = OfflineFallbackCatalogRepository(
      _Remote(const Err(CatalogFailure.network)),
      downloads,
    );

    final result = await catalog.getSongs(genreId: 3);

    expect((result as Ok<List<Song>, CatalogFailure>).value.map((s) => s.id), [
      'done',
    ]);
    await downloads.dispose();
  });

  test('con red o con otros errores deja pasar el resultado remoto', () async {
    final downloads = FakeDownloadRepository();
    final remote = _Remote(Ok([_song('r', 1)]));
    final catalog = OfflineFallbackCatalogRepository(remote, downloads);

    expect(((await catalog.getSongs()) as Ok).value.single.id, 'r');
    remote.result = const Err(CatalogFailure.unknown);
    expect(await catalog.getSongs(), isA<Err<List<Song>, CatalogFailure>>());
    await downloads.dispose();
  });
}
