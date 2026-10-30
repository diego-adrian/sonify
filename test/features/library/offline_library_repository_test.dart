import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/result.dart';
import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/library/domain/library.dart';
import 'package:sonify/features/library/domain/library_repository.dart';
import 'package:sonify/features/library/infrastructure/offline_library_repository.dart';

import '../../helpers/fake_library_repository.dart';

void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('library'));
  tearDown(() => dir.delete(recursive: true));

  test(
    'sin red devuelve la última biblioteca guardada en el dispositivo',
    () async {
      final song = Song(
        id: 's1',
        title: 'Cochabambina',
        artistName: 'Kalamarca',
        duration: const Duration(minutes: 3, seconds: 56),
        genreId: 2,
        cover: Uri.parse('https://cdn/covers/s1/200.webp?exp=1&sig=a'),
        audio: Uri.parse('https://cdn/audio/s1/128.m4a?exp=1&sig=b'),
        audioSizeBytes: 3600000,
      );
      final remote = FakeLibraryRepository(isPremium: false, catalog: [song])
        ..saved.add('s1');
      await remote.createPlaylist('Adrian auto');
      await remote.addToPlaylist('p1', 's1');
      final repository = OfflineLibraryRepository(
        remote,
        snapshot: () async => File('${dir.path}/users/u1/library.json'),
      );

      expect(await repository.load(), isA<Ok<Library, LibraryFailure>>());

      remote.failWith = LibraryFailure.network;
      final offline =
          (await repository.load() as Ok<Library, LibraryFailure>).value;
      expect(offline.account.isPremium, isFalse);
      expect(offline.account.libraryLimit, 5);
      expect(offline.songs.single.title, 'Cochabambina');
      expect(offline.songs.single.audio, song.audio);
      expect(offline.songs.single.duration, song.duration);
      expect(offline.playlists.single.name, 'Adrian auto');
      expect(offline.songsOf(offline.playlists.single).single.id, 's1');
    },
  );

  test(
    'sin red y sin copia propaga el error; otros errores no usan la copia',
    () async {
      final remote = FakeLibraryRepository()..failWith = LibraryFailure.network;
      final repository = OfflineLibraryRepository(
        remote,
        snapshot: () async => File('${dir.path}/library.json'),
      );

      expect(
        (await repository.load() as Err<Library, LibraryFailure>).error,
        LibraryFailure.network,
      );
      remote.failWith = LibraryFailure.unknown;
      expect(
        (await repository.load() as Err<Library, LibraryFailure>).error,
        LibraryFailure.unknown,
      );
    },
  );
}
