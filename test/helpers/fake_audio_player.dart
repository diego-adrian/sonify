import 'dart:async';

import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/player/domain/audio_player_port.dart';
import 'package:sonify/features/player/domain/playback_snapshot.dart';

/// Reproductor en memoria para tests: no hace sonido.
class FakeAudioPlayer implements AudioPlayerPort {
  final _changes = StreamController<PlaybackSnapshot>.broadcast();
  PlaybackSnapshot state = PlaybackSnapshot.idle;

  void _set(PlaybackSnapshot next) {
    state = next;
    _changes.add(next);
  }

  PlaybackSnapshot _copy({int? index, bool? playing, bool? shuffle}) =>
      PlaybackSnapshot(
        queue: state.queue,
        currentIndex: index ?? state.currentIndex,
        playing: playing ?? state.playing,
        shuffle: shuffle ?? state.shuffle,
      );

  @override
  Stream<PlaybackSnapshot> snapshots() async* {
    yield state;
    yield* _changes.stream;
  }

  @override
  Stream<Duration> positions() => const Stream.empty();

  @override
  Future<void> playQueue(List<Song> songs, {required int startIndex}) async =>
      _set(
        PlaybackSnapshot(queue: songs, currentIndex: startIndex, playing: true),
      );

  @override
  Future<void> play() async => _set(_copy(playing: true));

  @override
  Future<void> pause() async => _set(_copy(playing: false));

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> skipToNext() async {
    final i = state.currentIndex;
    if (i != null && i + 1 < state.queue.length) _set(_copy(index: i + 1));
  }

  @override
  Future<void> skipToPrevious() async {
    final i = state.currentIndex;
    if (i != null && i > 0) _set(_copy(index: i - 1));
  }

  @override
  Future<void> skipToSong(String songId) async {
    final i = state.queue.indexWhere((s) => s.id == songId);
    if (i >= 0) _set(_copy(index: i));
  }

  @override
  Future<void> setShuffle(bool enabled) async => _set(_copy(shuffle: enabled));

  @override
  Future<void> stop() async => _set(PlaybackSnapshot.idle);

  Future<void> dispose() => _changes.close();
}
