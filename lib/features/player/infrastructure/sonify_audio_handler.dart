import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Puente entre `just_audio` (reproductor nativo) y `audio_service`
/// (segundo plano, pantalla de bloqueo, Centro de Control, auriculares,
/// notificación de Android y, más adelante, CarPlay / Android Auto).
class SonifyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  SonifyAudioHandler() {
    player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object error, StackTrace _) =>
          debugPrint('Reproductor: $error'),
    );
    player.currentIndexStream.listen((index) {
      final items = queue.value;
      if (index != null && index < items.length) mediaItem.add(items[index]);
    });
    player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item != null && duration != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });
  }

  final AudioPlayer player = AudioPlayer();

  /// Sesión de audio de música: pausa en llamadas y al desconectar
  /// auriculares, y respeta a otras apps.
  static Future<void> configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> load(
    List<MediaItem> items,
    List<AudioSource> sources,
    int initialIndex,
  ) async {
    queue.add(items);
    mediaItem.add(items[initialIndex]);
    await player.setAudioSources(sources, initialIndex: initialIndex);
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() => player.seekToNext();

  /// Como en cualquier reproductor: si ya avanzó unos segundos, vuelve al
  /// inicio de la canción; si no, va a la anterior.
  @override
  Future<void> skipToPrevious() {
    if (player.position > const Duration(seconds: 3) || !player.hasPrevious) {
      return player.seek(Duration.zero);
    }
    return player.seekToPrevious();
  }

  @override
  Future<void> skipToQueueItem(int index) =>
      player.seek(Duration.zero, index: index);

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    if (enabled) await player.shuffle();
    await player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: switch (player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
        queueIndex: event.currentIndex,
        shuffleMode: player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
  }
}
