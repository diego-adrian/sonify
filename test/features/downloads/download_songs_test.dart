import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/result.dart';
import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/downloads/application/download_use_cases.dart';
import 'package:sonify/features/downloads/domain/download_entry.dart';
import 'package:sonify/features/downloads/domain/download_failure.dart';

import '../../helpers/fake_download_repository.dart';

Song _song(String id, {bool audio = true, int? size}) => Song(
  id: id,
  title: id,
  artistName: 'Artista',
  duration: const Duration(minutes: 5),
  audio: audio ? Uri.parse('https://cdn/$id.m4a') : null,
  audioSizeBytes: size,
);

void main() {
  const mb = 1024 * 1024;
  late FakeDownloadRepository downloads;

  setUp(() => downloads = FakeDownloadRepository());
  tearDown(() => downloads.dispose());

  test('encola solo las que tienen audio y no están ya', () async {
    downloads.entries.add(
      DownloadEntry(song: _song('a'), state: DownloadState.done),
    );
    downloads.entries.add(
      DownloadEntry(song: _song('f'), state: DownloadState.failed),
    );
    final use = DownloadSongs(downloads, FakeStorageSpace(10000 * mb));

    final result = await use([
      _song('a'),
      _song('b'),
      _song('b'),
      _song('c', audio: false),
      _song('f'),
    ]);

    expect(result, isA<Ok<int, Object>>());
    expect((result as Ok).value, 2, reason: 'b y el reintento de f');
  });

  test('100 canciones de 5 min: comprueba el espacio antes del lote', () async {
    final songs = [for (var i = 0; i < 100; i++) _song('$i')];
    // ~4,6 MB cada una a 128 kbps → ~458 MB; con 500 MB libres y 200 de
    // reserva no alcanza.
    final use = DownloadSongs(downloads, FakeStorageSpace(500 * mb));

    final result = await use(songs);

    final failure = (result as Err).error as NotEnoughSpace;
    expect(failure.requiredBytes, 100 * 300 * 16000);
    expect(failure.availableBytes, 300 * mb);
    expect(downloads.entries, isEmpty, reason: 'no empieza a medias');
  });

  test('usa el tamaño del catálogo si lo trae', () {
    expect(DownloadSongs.estimate(_song('x', size: 1234)), 1234);
  });

  test('sin poder medir el espacio, descarga igual', () async {
    final use = DownloadSongs(downloads, FakeStorageSpace(null));
    expect(((await use([_song('a')])) as Ok).value, 1);
  });
}
