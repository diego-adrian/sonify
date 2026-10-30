import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'playback_recovery.dart';

/// Puente entre `just_audio` (reproductor nativo) y `audio_service`
/// (segundo plano, pantalla de bloqueo, Centro de Control, auriculares,
/// notificación de Android y, más adelante, CarPlay / Android Auto).
class SonifyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  SonifyAudioHandler({
    this.stallTimeout = defaultStallTimeout,
    this.reloadTimeout = defaultReloadTimeout,
    this.firstRetryDelay = const Duration(seconds: 2),
  }) {
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
  static const defaultStallTimeout = Duration(seconds: 20);

  /// Lo máximo que espera una recarga: si la red no responde, el reproductor
  /// de iOS tarda 2 minutos en rendirse y mientras tanto play no haría nada.
  static const defaultReloadTimeout = Duration(seconds: 30);

  /// Lo máximo que un comando espera al anterior (ver [_serially]).
  static const commandTimeout = Duration(seconds: 5);

  /// Canal propio de iOS (AppDelegate.swift). Android no lo necesita.
  static const _nowPlaying = MethodChannel('app.sonify.sonify/now_playing');

  final Duration stallTimeout;
  final Duration reloadTimeout;
  final Duration firstRetryDelay;

  /// Justo antes de que el usuario salte a otra canción, todavía en la que
  /// suena. `just_audio` avisa de esos saltos antes de cambiar de pista y con
  /// el índice viejo, así que no se distinguen de un seek dentro de la canción.
  void Function()? onLeavingTrack;

  Future<void> _transport = Future.value();

  late final _recovery = PlaybackRecovery(
    reload: _reload,
    retry: () => unawaited(play()),
    firstRetryDelay: firstRetryDelay,
  );

  /// Vuelve a crear las fuentes (cada canción se resuelve otra vez: si ya
  /// está descargada, la recarga ni siquiera usa la red).
  Future<List<AudioSource>> Function()? _buildSources;

  /// `true` si alguna fuente cargada usa una URL vencida y ya hay una nueva:
  /// conviene recargar antes de reproducir o saltar.
  bool Function() _sourcesExpired = _never;
  static bool _never() => false;

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
    int initialIndex, {
    bool Function() sourcesExpired = _never,
  }) async {
    _recovery.reset();
    _buildSources = buildSources;
    _sourcesExpired = sourcesExpired;
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
  Future<void> play() => _serially(_play);

  @override
  Future<void> pause() => _serially(_pause);

  /// Play/pausa de la app, auriculares, Apple Watch (doble toque) y Centro de
  /// Control. Decide al ejecutarse con el estado real del reproductor, no con
  /// el último emitido: dos toques seguidos pausan y vuelven a sonar.
  @override
  Future<void> click([MediaButton button = MediaButton.media]) {
    if (button != MediaButton.media) return super.click(button);
    return _serially(
      () => player.playing && !_recovery.needsReload ? _pause() : _play(),
    );
  }

  Future<void> _play() async {
    final resuming = !player.playing;
    if (resuming) await _reloadIfExpired();
    if (!await _recovery.ensureLoaded()) return;
    unawaited(player.play());
    if (resuming) unawaited(_renewNowPlaying());
  }

  /// Lo que se ve en la pantalla de bloqueo: el usuario pudo haberlo limpiado
  /// mientras estaba en pausa.
  static Future<void> _renewNowPlaying() async {
    try {
      await _nowPlaying.invokeMethod<void>('renew');
    } on MissingPluginException {
      // Android y tests: no hay canal.
    }
  }

  /// Las URLs firmadas vencen en 24–48 h: una cola armada ayer daría 403 al
  /// llegar a una canción no descargada. Se recarga en el mismo punto con
  /// las URLs nuevas que trajo el catálogo.
  Future<void> _reloadIfExpired() async {
    if (!_sourcesExpired()) return;
    _resumeIndex = player.currentIndex ?? 0;
    _resumePosition = player.position;
    await _reload();
  }

  Future<void> _pause() {
    _recovery.paused();
    return player.pause();
  }

  @override
  Future<void> seek(Duration position) =>
      _serially(() => player.seek(position));

  @override
  Future<void> skipToNext() => _serially(() async {
    await _reloadIfExpired();
    _leavingFor(player.nextIndex);
    await player.seekToNext();
  });

  /// Como en cualquier reproductor: si ya avanzó unos segundos, vuelve al
  /// inicio de la canción; si no, va a la anterior. Se decide al ejecutarse,
  /// así el doble toque reinicia y luego va a la anterior.
  @override
  Future<void> skipToPrevious() => _serially(() async {
    if (player.position > const Duration(seconds: 3) || !player.hasPrevious) {
      return player.seek(Duration.zero);
    }
    await _reloadIfExpired();
    _leavingFor(player.previousIndex);
    await player.seekToPrevious();
  });

  @override
  Future<void> skipToQueueItem(int index) => _serially(() async {
    await _reloadIfExpired();
    _leavingFor(index);
    await player.seek(Duration.zero, index: index);
  });

  /// Sin siguiente o con una sola en la cola, el salto no cambia de canción.
  void _leavingFor(int? target) {
    if (target != null && target != player.currentIndex) {
      onLeavingTrack?.call();
    }
  }

  /// Play, pausa, seeks y saltos de a uno, en el orden en que se tocaron: el
  /// reproductor de iOS se queda cargando si le llega un seek con otro a
  /// medias (p. ej. doble toque en "anterior"), `just_audio` calcula la
  /// siguiente/anterior con el índice que aún no cambió y un play que espera
  /// la recarga se comería la pausa que llegó después. Si uno no termina en
  /// [commandTimeout], los demás no lo esperan.
  Future<void> _serially(Future<void> Function() command) {
    final next = _transport
        .timeout(commandTimeout, onTimeout: () {})
        .then((_) => command());
    _transport = next.catchError((Object _) {});
    return next;
  }

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
      await _loadResumePoint(build).timeout(reloadTimeout);
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

  Future<void> _loadResumePoint(
    Future<List<AudioSource>> Function() build,
  ) async {
    await player.setAudioSources(
      await build(),
      initialIndex: _resumeIndex,
      initialPosition: _resumePosition,
    );
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
