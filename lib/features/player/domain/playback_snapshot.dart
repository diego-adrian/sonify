import '../../catalog/domain/song.dart';

/// Estado del reproductor, sin la posición (que va en su propio stream para
/// no reconstruir toda la UI varias veces por segundo).
final class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.queue = const [],
    this.currentIndex,
    this.playing = false,
    this.buffering = false,
    this.shuffle = false,
    this.duration,
  });

  static const idle = PlaybackSnapshot();

  /// Cola en orden de reproducción (ya mezclada si [shuffle]).
  final List<Song> queue;
  final int? currentIndex;
  final bool playing;
  final bool buffering;
  final bool shuffle;

  /// Duración real del audio cargado (puede llegar después de empezar).
  final Duration? duration;

  bool get hasQueue => queue.isNotEmpty && currentIndex != null;

  Song? get current => hasQueue ? queue[currentIndex!] : null;

  List<Song> get upNext =>
      hasQueue ? queue.sublist(currentIndex! + 1) : const [];
}
