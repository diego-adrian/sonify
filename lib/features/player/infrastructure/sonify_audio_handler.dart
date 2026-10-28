import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'playback_recovery.dart';

/// Puente entre `just_audio` (reproductor nativo) y `audio_service`
/// (segundo plano, pantalla de bloqueo, Centro de Control, auriculares,
/// notificación de Android y, más adelante, CarPlay / Android Auto).
class SonifyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  SonifyAudioHandler() {
    player.playbackEventStream.listen(
      _broadcastState,
      // Lo atiende errorStream (abajo).
      onError: (Object _, StackTrace _) {},
    );
    player.errorStream.listen((error) {
      debugPrint('Reproductor: $error');
      // Si falla una recarga, la atiende _reload (y errorStream no repite un
      // error idéntico, así que no se puede depender de él para reintentar).
      if (!_reloading) _failed(error.index);
    });
    player.playerStateStream.listen(_watchStall);
    player.currentIndexStream.listen((index) {
      final items = queue.value;
      if (index != null && index < items.length) mediaItem.add(items[index]);
    });
    // Cambiar el modo de repetición no emite un evento de reproducción.
    player.loopModeStream.listen((_) => _broadcastState(player.playbackEvent));
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) unawaited(_rewindQueue());
    });
    player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item != null && duration != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });
  }

  final AudioPlayer player = AudioPlayer();

  /// Más que esto cargando mientras debería sonar = conexión colgada (p. ej.
  /// la red cambió y la petición quedó huérfana): se recarga la pista.
  static const stallTimeout = Duration(seconds: 20);

  late final _recovery = PlaybackRecovery(
    reload: _reload,
    retry: () => unawaited(play()),
  );

  /// Vuelve a crear las fuentes (cada canción se resuelve otra vez: si ya
  /// está descargada, la recarga ni siquiera usa la red).
  Future<List<AudioSource>> Function()? _buildSources;

  /// Dónde retomar tras un fallo.
  int _resumeIndex = 0;
  Duration _resumePosition = Duration.zero;
  Timer? _stallTimer;
  bool _reloading = false;

  /// Sesión de audio de música: pausa en llamadas y al desconectar
  /// auriculares, y respeta a otras apps.
  static Future<void> configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> load(
    List<MediaItem> items,
    Future<List<AudioSource>> Function() buildSources,
    int initialIndex,
  ) async {
    _recovery.reset();
    _buildSources = buildSources;
    queue.add(items);
    mediaItem.add(items[initialIndex]);
    await player.setAudioSources(
      await buildSources(),
      initialIndex: initialIndex,
    );
  }

  /// No espera a que termine la canción (el `play()` de just_audio no
  /// termina hasta pausar): así los comandos del reloj, la pantalla de
  /// bloqueo y la app nunca quedan colgados detrás de él.
  @override
  Future<void> play() async {
    if (!await _recovery.ensureLoaded()) return;
    unawaited(player.play());
  }

  @override
  Future<void> pause() {
    _recovery.paused();
    return player.pause();
  }

  /// Play/pausa de auriculares, Apple Watch (doble toque), Centro de Control.
  /// Decide con el estado real del reproductor, no con el último emitido.
  @override
  Future<void> click([MediaButton button = MediaButton.media]) {
    if (button != MediaButton.media) return super.click(button);
    return player.playing && !_recovery.needsReload ? pause() : play();
  }

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
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) =>
      player.setLoopMode(switch (repeatMode) {
        AudioServiceRepeatMode.none => LoopMode.off,
        AudioServiceRepeatMode.one => LoopMode.one,
        AudioServiceRepeatMode.all ||
        AudioServiceRepeatMode.group => LoopMode.all,
      });

  @override
  Future<void> stop() async {
    _recovery.reset();
    _stallTimer?.cancel();
    await player.stop();
    await super.stop();
  }

  /// Al terminar la última de la cola (sin repetir) vuelve a la primera, en
  /// pausa, como Spotify: si no, el reproductor queda "terminado" y play no
  /// hace nada. Con aleatorio, la primera del orden aleatorio.
  Future<void> _rewindQueue() async {
    final order = player.effectiveIndices;
    if (order.isEmpty) return;
    await player.pause();
    await player.seek(Duration.zero, index: order.first);
  }

  void _failed(int? failedIndex) {
    final current = player.currentIndex ?? 0;
    final index = failedIndex ?? current;
    _resumeIndex = index;
    _resumePosition = index == current ? player.position : Duration.zero;
    _stallTimer?.cancel();
    _stallTimer = null;
    _recovery.failed(wasPlaying: player.playing);
    // Sin esto queda "sonando" sin pista y play() no hace nada.
    unawaited(player.pause());
  }

  Future<bool> _reload() async {
    final build = _buildSources;
    if (build == null) return false;
    _reloading = true;
    try {
      await player.setAudioSources(
        await build(),
        initialIndex: _resumeIndex,
        initialPosition: _resumePosition,
      );
      return true;
    } on Exception catch (error) {
      debugPrint('Reproductor: no se pudo recargar ($error)');
      // Programa el siguiente intento automático, si quedan.
      _recovery.failed(wasPlaying: false);
      return false;
    } finally {
      _reloading = false;
    }
  }

  void _watchStall(PlayerState state) {
    if (state.processingState == ProcessingState.ready) _recovery.recovered();
    final stalled =
        state.playing &&
        (state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering);
    if (!stalled) {
      _stallTimer?.cancel();
      _stallTimer = null;
      return;
    }
    _stallTimer ??= Timer(stallTimeout, () {
      _stallTimer = null;
      debugPrint('Reproductor: sin avanzar en $stallTimeout, se recarga');
      _failed(player.currentIndex);
    });
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
        repeatMode: switch (player.loopMode) {
          LoopMode.off => AudioServiceRepeatMode.none,
          LoopMode.one => AudioServiceRepeatMode.one,
          LoopMode.all => AudioServiceRepeatMode.all,
        },
        shuffleMode: player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
  }
}
