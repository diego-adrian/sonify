import '../../catalog/domain/song.dart';
import 'playback_snapshot.dart';

/// Puerto del reproductor. El adaptador usa el reproductor nativo del sistema
/// (AVPlayer / ExoPlayer) con sonido en segundo plano y controles de bloqueo.
abstract interface class AudioPlayerPort {
  /// Emite el estado actual al suscribirse y luego cada cambio.
  Stream<PlaybackSnapshot> snapshots();

  /// Posición de la canción actual, a baja frecuencia.
  Stream<Duration> positions();

  Future<void> playQueue(List<Song> songs, {required int startIndex});

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> skipToNext();

  Future<void> skipToPrevious();

  Future<void> skipToSong(String songId);

  Future<void> setShuffle(bool enabled);

  Future<void> setRepeat(PlaybackRepeat mode);

  Future<void> stop();
}
