import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/downloads/domain/download_ports.dart';
import 'package:sonify/features/downloads/domain/fresh_urls.dart';

final class _Refresher implements SongRefresher {
  _Refresher(this.songs);

  final List<Song> songs;
  final asked = <List<String>>[];

  @override
  Future<List<Song>> fresh(List<String> songIds) async {
    asked.add(songIds);
    return [
      for (final song in songs)
        if (songIds.contains(song.id)) song,
    ];
  }
}

void main() {
  final now = DateTime.utc(2026, 10, 29, 12);
  final yesterday = now.subtract(const Duration(days: 1));
  final tomorrow = now.add(const Duration(days: 1));

  Song song(String id, DateTime exp) => Song(
    id: id,
    title: id,
    artistName: 'Artista',
    duration: const Duration(minutes: 3),
    audio: Uri.parse(
      'https://cdn.test/audio/$id/128.m4a'
      '?exp=${exp.millisecondsSinceEpoch ~/ 1000}&sig=s',
    ),
  );

  test('pide de nuevo solo las vencidas y las reemplaza', () async {
    final refresher = _Refresher([song('a', tomorrow)]);

    final result = await withFreshUrls(
      [song('a', yesterday), song('b', tomorrow)],
      refresher,
      now: now,
    );

    expect(refresher.asked, [
      ['a'],
    ]);
    expect(result.map((s) => s.audio), [
      song('a', tomorrow).audio,
      song('b', tomorrow).audio,
    ]);
  });

  test('sin vencidas no pide nada', () async {
    final refresher = _Refresher(const []);

    await withFreshUrls([song('a', tomorrow)], refresher, now: now);

    expect(refresher.asked, isEmpty);
  });

  test('sin red (no llega nada) quedan como estaban', () async {
    final old = song('a', yesterday);

    final result = await withFreshUrls([old], _Refresher(const []), now: now);

    expect(result.single.audio, old.audio);
  });
}
