import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/result.dart';
import 'package:sonify/features/catalog/application/get_songs.dart';
import 'package:sonify/features/catalog/domain/catalog_failure.dart';
import 'package:sonify/features/catalog/domain/song.dart';

import '../../helpers/fake_catalog_repository.dart';

void main() {
  const getSongs = GetSongs(FakeCatalogRepository());

  List<Song> songsOf(Result<List<Song>, CatalogFailure> result) =>
      (result as Ok<List<Song>, CatalogFailure>).value;

  test('sin género devuelve todo el catálogo', () async {
    expect(songsOf(await getSongs()), hasLength(8));
  });

  test('filtra por género', () async {
    final cumbia = songsOf(await getSongs(genreId: 3));

    expect(cumbia, isNotEmpty);
    expect(cumbia.every((song) => song.genreId == 3), isTrue);
  });

  test('pagina con limit y offset', () async {
    final page = songsOf(await getSongs(limit: 3, offset: 2));

    expect(page.map((song) => song.id), ['3', '4', '5']);
  });
}
