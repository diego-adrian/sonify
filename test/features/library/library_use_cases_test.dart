import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/result.dart';
import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/downloads/domain/download_entry.dart';
import 'package:sonify/features/library/application/library_use_cases.dart';
import 'package:sonify/features/library/domain/library.dart';
import 'package:sonify/features/library/domain/library_repository.dart';

import '../../helpers/fake_download_repository.dart';
import '../../helpers/fake_library_repository.dart';

Song _song(String id) => Song(
  id: id,
  title: id,
  artistName: 'A',
  duration: const Duration(minutes: 3),
  audio: Uri.parse('https://cdn/$id.m4a'),
);

final _catalog = [for (var i = 1; i <= 7; i++) _song('$i')];

Future<Library> _load(FakeLibraryRepository repository) async =>
    (await repository.load() as Ok<Library, LibraryFailure>).value;

LibraryFailure? _failure(Result<void, LibraryFailure> result) =>
    switch (result) {
      Ok() => null,
      Err(:final error) => error,
    };

void main() {
  test('gratis guarda hasta el límite; la sexta ni llega al backend', () async {
    final repository = FakeLibraryRepository(
      isPremium: false,
      catalog: _catalog,
    );
    final save = SaveSong(repository);

    for (var i = 1; i <= 5; i++) {
      expect(_failure(await save(await _load(repository), '$i')), isNull);
    }
    final full = await _load(repository);
    expect(full.isFull, isTrue);
    expect(full.canPlay('1'), isTrue);
    expect(full.canPlay('6'), isFalse);

    expect(_failure(await save(full, '6')), LibraryFailure.limitReached);
    expect(repository.saved, hasLength(5));
    // Volver a guardar una ya guardada no cuenta.
    expect(_failure(await save(full, '1')), isNull);
  });

  test('premium no tiene límite y escucha todo el catálogo', () async {
    final repository = FakeLibraryRepository(catalog: _catalog);
    final save = SaveSong(repository);

    for (final song in _catalog) {
      expect(_failure(await save(await _load(repository), song.id)), isNull);
    }
    final library = await _load(repository);
    expect(library.remaining, isNull);
    expect(library.canPlay('no-guardada'), isTrue);
  });

  test(
    'quitar de la biblioteca borra la descarga solo en la cuenta gratis',
    () async {
      Future<int> downloadsLeft({required bool premium}) async {
        final repository = FakeLibraryRepository(
          isPremium: premium,
          catalog: _catalog,
        )..saved.add('1');
        final downloads = FakeDownloadRepository()
          ..entries.add(
            DownloadEntry(song: _song('1'), state: DownloadState.done),
          );
        await RemoveFromLibrary(repository, downloads)(
          await _load(repository),
          '1',
        );
        expect(repository.saved, isEmpty);
        final left = downloads.entries.length;
        await downloads.dispose();
        return left;
      }

      expect(await downloadsLeft(premium: false), 0);
      expect(await downloadsLeft(premium: true), 1);
    },
  );

  test('agregar a una playlist la guarda y respeta el límite', () async {
    final repository = FakeLibraryRepository(
      isPremium: false,
      limit: 1,
      catalog: _catalog,
    );
    await CreatePlaylist(repository)('Adrian auto');
    final add = AddToPlaylist(repository);

    expect(_failure(await add(await _load(repository), 'p1', '1')), isNull);
    final library = await _load(repository);
    expect(library.contains('1'), isTrue);
    expect(library.songsOf(library.playlists.single).single.id, '1');

    expect(
      _failure(await add(library, 'p1', '2')),
      LibraryFailure.limitReached,
    );
  });

  test('el nombre de la playlist se recorta y no puede quedar vacío', () async {
    final repository = FakeLibraryRepository();
    final create = CreatePlaylist(repository);

    expect(_failure(await create('   ')), LibraryFailure.invalidName);
    expect(_failure(await create('x' * 61)), LibraryFailure.invalidName);
    expect(_failure(await create('  Adrian auto  ')), isNull);
    expect(repository.playlists.values.single.name, 'Adrian auto');
  });
}
