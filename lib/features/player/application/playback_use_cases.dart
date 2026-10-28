import '../../catalog/domain/song.dart';
import '../domain/audio_player_port.dart';
import '../domain/playback_snapshot.dart';

final class WatchPlayback {
  const WatchPlayback(this._player);

  final AudioPlayerPort _player;

  Stream<PlaybackSnapshot> call() => _player.snapshots();
}

final class WatchPosition {
  const WatchPosition(this._player);

  final AudioPlayerPort _player;

  Stream<Duration> call() => _player.positions();
}

/// Reproduce [songs] empezando por [song]. Ignora canciones sin audio.
final class PlaySongs {
  const PlaySongs(this._player);

  final AudioPlayerPort _player;

  Future<void> call(List<Song> songs, Song song) {
    final playable = songs.where((s) => s.audio != null).toList();
    final index = playable.indexWhere((s) => s.id == song.id);
    if (index < 0) return Future.value();
    return _player.playQueue(playable, startIndex: index);
  }
}

final class TogglePlayback {
  const TogglePlayback(this._player);

  final AudioPlayerPort _player;

  Future<void> call(PlaybackSnapshot state) =>
      state.playing ? _player.pause() : _player.play();
}

final class SeekTo {
  const SeekTo(this._player);

  final AudioPlayerPort _player;

  Future<void> call(Duration position) => _player.seek(position);
}

final class SkipToNext {
  const SkipToNext(this._player);

  final AudioPlayerPort _player;

  Future<void> call() => _player.skipToNext();
}

final class SkipToPrevious {
  const SkipToPrevious(this._player);

  final AudioPlayerPort _player;

  Future<void> call() => _player.skipToPrevious();
}

final class SkipToSong {
  const SkipToSong(this._player);

  final AudioPlayerPort _player;

  Future<void> call(String songId) => _player.skipToSong(songId);
}

/// Pasa al siguiente modo de repetición (desactivado → todo → una).
final class CycleRepeat {
  const CycleRepeat(this._player);

  final AudioPlayerPort _player;

  Future<void> call(PlaybackSnapshot state) =>
      _player.setRepeat(state.repeat.next);
}

final class SetShuffle {
  const SetShuffle(this._player);

  final AudioPlayerPort _player;

  Future<void> call(bool enabled) => _player.setShuffle(enabled);
}

final class StopPlayback {
  const StopPlayback(this._player);

  final AudioPlayerPort _player;

  Future<void> call() => _player.stop();
}
