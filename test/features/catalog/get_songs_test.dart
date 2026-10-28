import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/result.dart';
import 'package:sonify/features/catalog/application/get_songs.dart';
import 'package:sonify/features/catalog/domain/catalog_failure.dart';
import 'package:sonify/features/catalog/domain/catalog_page.dart';
import 'package:sonify/features/catalog/domain/song.dart';

import '../../helpers/fake_catalog_repository.dart';

void main() {
  const getSongs = GetSongs(FakeCatalogRepository());

  CatalogPage pageOf(Result<CatalogPage, CatalogFailure> result) =>
      (result as Ok<CatalogPage, CatalogFailure>).value;
  List<Song> songsOf(Result<CatalogPage, CatalogFailure> result) =>
      pageOf(result).songs;

  test('sin género devuelve todo el catálogo', () async {
    expect(songsOf(await getSongs()), hasLength(8));
  });

  test('filtra por género', () async {
    final cumbia = songsOf(await getSongs(genreId: 3));

    expect(cumbia, isNotEmpty);
    expect(cumbia.every((song) => song.genreId == 3), isTrue);
  });

  test('pagina con cursor hasta el final', () async {
    final first = pageOf(await getSongs(limit: 3));
    final second = pageOf(await getSongs(limit: 3, after: first.next));
    final last = pageOf(await getSongs(limit: 3, after: second.next));

    expect(first.songs.map((song) => song.id), ['1', '2', '3']);
    expect(second.songs.map((song) => song.id), ['4', '5', '6']);
    expect(last.songs.map((song) => song.id), ['7', '8']);
    expect(last.hasMore, isFalse);
  });
}
