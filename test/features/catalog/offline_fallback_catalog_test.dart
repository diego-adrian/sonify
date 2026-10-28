import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/result.dart';
import 'package:sonify/features/catalog/domain/catalog_failure.dart';
import 'package:sonify/features/catalog/domain/catalog_page.dart';
import 'package:sonify/features/catalog/domain/catalog_repository.dart';
import 'package:sonify/features/catalog/domain/genre.dart';
import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/catalog/infrastructure/offline_fallback_catalog_repository.dart';
import 'package:sonify/features/downloads/domain/download_entry.dart';
import 'package:sonify/features/player/domain/local_audio.dart';

import '../../helpers/fake_download_repository.dart';

/// Señal débil: la petición nunca responde.
final class _HangingRemote implements CatalogRepository {
  @override
  Future<Result<List<Genre>, CatalogFailure>> getGenres() =>
      Completer<Result<List<Genre>, CatalogFailure>>().future;

  @override
  Future<Result<CatalogPage, CatalogFailure>> getSongs({
    int? genreId,
    int limit = catalogPageSize,
    SongCursor? after,
  }) => Completer<Result<CatalogPage, CatalogFailure>>().future;
}

final class _Remote implements CatalogRepository {
  _Remote(this.result);

  Result<CatalogPage, CatalogFailure> result;

  @override
  Future<Result<List<Genre>, CatalogFailure>> getGenres() async => const Ok([]);

  @override
  Future<Result<CatalogPage, CatalogFailure>> getSongs({
    int? genreId,
    int limit = catalogPageSize,
    SongCursor? after,
  }) async => result;
}

Song _song(String id, int genre) => Song(
  id: id,
  title: id,
  artistName: 'A',
  duration: const Duration(minutes: 3),
  genreId: genre,
);

final class _Cache implements ListeningCache {
  const _Cache(this.songs);

  final List<Song> songs;

  @override
  Stream<List<Song>> watchSongs() => Stream.value(songs);

  @override
  Future<LocalAudio?> find(String songId) async => null;

  @override
  Future<String?> tempPathFor(String songId) async => null;

  @override
  void protect(Set<String> songIds) {}

  @override
  Future<void> finished(
    Song song, {
    required bool listenedEnough,
    required bool stillCurrent,
  }) async {}

  @override
  Future<void> clearTemporary() async {}
}

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

    expect(
      (result as Ok<CatalogPage, CatalogFailure>).value.songs.map((s) => s.id),
      ['done'],
    );
    await downloads.dispose();
  });

  test('con red o con otros errores deja pasar el resultado remoto', () async {
    final downloads = FakeDownloadRepository();
    final remote = _Remote(Ok(CatalogPage([_song('r', 1)])));
    final catalog = OfflineFallbackCatalogRepository(remote, downloads);

    expect(
      ((await catalog.getSongs()) as Ok<CatalogPage, CatalogFailure>)
          .value
          .songs
          .single
          .id,
      'r',
    );
    remote.result = const Err(CatalogFailure.unknown);
    expect(await catalog.getSongs(), isA<Err<CatalogPage, CatalogFailure>>());
    await downloads.dispose();
  });

  test(
    'si la red no responde, pasado el timeout muestra lo descargado',
    () async {
      final downloads = FakeDownloadRepository()
        ..entries.add(
          DownloadEntry(song: _song('done', 1), state: DownloadState.done),
        );
      final catalog = OfflineFallbackCatalogRepository(
        _HangingRemote(),
        downloads,
        timeout: const Duration(milliseconds: 10),
      );

      final result = await catalog.getSongs();

      expect(
        (result as Ok<CatalogPage, CatalogFailure>).value.songs.single.id,
        'done',
      );
      expect(
        (await catalog.getGenres() as Err<List<Genre>, CatalogFailure>).error,
        CatalogFailure.network,
      );
      await downloads.dispose();
    },
  );

  test('sin red en una página siguiente propaga el error', () async {
    final downloads = FakeDownloadRepository()
      ..entries.add(
        DownloadEntry(song: _song('done', 1), state: DownloadState.done),
      );
    final catalog = OfflineFallbackCatalogRepository(
      _Remote(const Err(CatalogFailure.network)),
      downloads,
    );

    final result = await catalog.getSongs(
      after: const SongCursor(createdAt: '2026-10-28', id: 'x'),
    );

    // No se vuelve a agregar lo descargado al final de la lista.
    expect(
      (result as Err<CatalogPage, CatalogFailure>).error,
      CatalogFailure.network,
    );
    await downloads.dispose();
  });

  test('sin red también muestra lo escuchado en caché, sin repetir', () async {
    final downloads = FakeDownloadRepository()
      ..entries.add(
        DownloadEntry(song: _song('done', 1), state: DownloadState.done),
      );
    final catalog = OfflineFallbackCatalogRepository(
      _Remote(const Err(CatalogFailure.network)),
      downloads,
      cache: _Cache([_song('heard', 1), _song('done', 1)]),
    );

    final result = await catalog.getSongs();

    expect(
      (result as Ok<CatalogPage, CatalogFailure>).value.songs.map((s) => s.id),
      ['done', 'heard'],
    );
    await downloads.dispose();
  });
}
