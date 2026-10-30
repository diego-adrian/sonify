import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/player/application/playback_use_cases.dart';
import 'package:sonify/features/player/domain/playback_snapshot.dart';

import '../../helpers/fake_audio_player.dart';

Song _song(String id, {bool withAudio = true}) => Song(
  id: id,
  title: 'Canción $id',
  artistName: 'Artista',
  duration: const Duration(minutes: 3),
  audio: withAudio ? Uri.parse('https://cdn.example/$id.m4a') : null,
);

void main() {
  late FakeAudioPlayer player;

  setUp(() => player = FakeAudioPlayer());
  tearDown(() => player.dispose());

  test('PlaySongs arma la cola desde la canción elegida y omite las que '
      'no tienen audio', () async {
    final songs = [_song('1'), _song('2', withAudio: false), _song('3')];

    await PlaySongs(player)(songs, songs[2]);

    expect(player.state.queue.map((s) => s.id), ['1', '3']);
    expect(player.state.current?.id, '3');
    expect(player.state.playing, isTrue);
  });

  test('PlaySongs no hace nada si la canción no tiene audio', () async {
    final songs = [_song('1'), _song('2', withAudio: false)];

    await PlaySongs(player)(songs, songs[1]);

    expect(player.state.hasQueue, isFalse);
  });

  test('TogglePlayback alterna entre pausa y reproducción', () async {
    await PlaySongs(player)([_song('1')], _song('1'));

    await TogglePlayback(player)();
    expect(player.state.playing, isFalse);

    await TogglePlayback(player)();
    expect(player.state.playing, isTrue);
  });

  test('upNext son las canciones después de la actual', () {
    final snapshot = PlaybackSnapshot(
      queue: [_song('1'), _song('2'), _song('3')],
      currentIndex: 1,
    );

    expect(snapshot.current?.id, '2');
    expect(snapshot.upNext.map((s) => s.id), ['3']);
  });

  test('CycleRepeat: desactivado → todo → una → desactivado', () async {
    await PlaySongs(player)([_song('1')], _song('1'));
    final seen = <PlaybackRepeat>[];
    for (var i = 0; i < 3; i++) {
      await CycleRepeat(player)(player.state);
      seen.add(player.state.repeat);
    }

    expect(seen, [PlaybackRepeat.all, PlaybackRepeat.one, PlaybackRepeat.off]);
  });
}
