// StreamAudioSource es la única vía de just_audio para audio que no es un
// archivo/URL legible por el sistema (aquí, descifrado al vuelo).
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../catalog/domain/song.dart';
import '../domain/audio_player_port.dart';
import '../domain/local_audio.dart';
import '../domain/playback_snapshot.dart';
import 'sonify_audio_handler.dart';

/// Adaptador del puerto de reproducción sobre [SonifyAudioHandler].
final class AudioServicePlayer implements AudioPlayerPort {
  AudioServicePlayer(this._handler, this._library, this._cache) {
    _subscriptions = [
      _player.sequenceStateStream.listen((_) => _emit()),
      _player.playerStateStream.listen(_onPlayerState),
      _player.durationStream.listen((_) => _emit()),
      _player.loopModeStream.listen((_) => _emit()),
      _player.positionDiscontinuityStream.listen(_onDiscontinuity),
    ];
  }

  /// Escuchada al menos esto (o hasta el final) se guarda en la caché.
  static const minListenToCache = Duration(seconds: 30);

  final SonifyAudioHandler _handler;

  /// Descargas del usuario actual: si una canción está en el dispositivo,
  /// suena sin red.
  final LocalAudioLibrary Function() _library;

  /// Lo escuchado por streaming: la 2.ª vez suena sin red.
  final ListeningCache Function() _cache;

  /// Mientras se carga una cola nueva, los cambios de pista no son
  /// "terminó de sonar".
  bool _loading = false;
  final _songsById = <String, Song>{};
  final _changes = StreamController<PlaybackSnapshot>.broadcast();
  late final List<StreamSubscription<Object?>> _subscriptions;
  PlaybackSnapshot _last = PlaybackSnapshot.idle;

  AudioPlayer get _player => _handler.player;

  @override
  Stream<PlaybackSnapshot> snapshots() async* {
    yield _last;
    yield* _changes.stream;
  }

  /// Baja frecuencia a propósito (~1 por segundo, más en seeks/cambios):
  /// la barra interpola entre muestras, así que no hace falta más y se
  /// ahorra CPU/batería frente al stream por defecto (hasta 60 por segundo).
  @override
  Stream<Duration> positions() => _player.createPositionStream(
    steps: 1,
    minPeriod: const Duration(milliseconds: 500),
    maxPeriod: const Duration(seconds: 1),
  );

  @override
  Future<void> playQueue(List<Song> songs, {required int startIndex}) async {
    _loading = true;
    try {
      await _leaveCurrent();
      final cache = _cache();
      await cache.clearTemporary();
      cache.protect({for (final song in songs) song.id});
      _songsById
        ..clear()
        ..addEntries(songs.map((song) => MapEntry(song.id, song)));
      await _load(songs, startIndex);
    } finally {
      _loading = false;
    }
    // `play()` de just_audio no termina hasta pausar: no se espera.
    unawaited(_handler.play());
  }

  Future<void> _load(List<Song> songs, int startIndex) => _handler.load(
    songs.map(_mediaItem).toList(),
    () => Future.wait(songs.map(_source)),
    startIndex,
  );

  @override
  Future<void> play() async => unawaited(_handler.play());

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> seek(Duration position) => _handler.seek(position);

  @override
  Future<void> skipToNext() => _handler.skipToNext();

  @override
  Future<void> skipToPrevious() => _handler.skipToPrevious();

  @override
  Future<void> skipToSong(String songId) async {
    final index = _player.sequence.indexWhere((s) => s.tag == songId);
    if (index >= 0) await _handler.skipToQueueItem(index);
  }

  @override
  Future<void> setShuffle(bool enabled) => _handler.setShuffleMode(
    enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
  );

  @override
  Future<void> setRepeat(PlaybackRepeat mode) =>
      _handler.setRepeatMode(switch (mode) {
        PlaybackRepeat.off => AudioServiceRepeatMode.none,
        PlaybackRepeat.all => AudioServiceRepeatMode.all,
        PlaybackRepeat.one => AudioServiceRepeatMode.one,
      });

  @override
  Future<void> stop() async {
    await _leaveCurrent();
    await _handler.stop();
    await _cache().clearTemporary();
  }

  void _emit() {
    final sequence = _player.sequenceState;
    final queue = [
      for (final source in sequence.effectiveSequence) ?_songsById[source.tag],
    ];
    final index = sequence.currentIndex;
    final effectiveIndex = index == null
        ? null
        : sequence.shuffleModeEnabled
        ? sequence.shuffleIndices.indexOf(index)
        : index;
    final state = _player.playerState;

    _last = PlaybackSnapshot(
      queue: queue,
      currentIndex: effectiveIndex == null || effectiveIndex < 0
          ? null
          : effectiveIndex,
      playing:
          state.playing && state.processingState != ProcessingState.completed,
      buffering:
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering,
      shuffle: sequence.shuffleModeEnabled,
      repeat: switch (_player.loopMode) {
        LoopMode.off => PlaybackRepeat.off,
        LoopMode.all => PlaybackRepeat.all,
        LoopMode.one => PlaybackRepeat.one,
      },
      duration: _player.duration,
    );
    _changes.add(_last);
  }

  /// Descargada → caché de lo escuchado → streaming (que se va guardando
  /// en un temporal para poder pasar a la caché).
  Future<AudioSource> _source(Song song) async {
    final local =
        await _library().find(song.id) ?? await _cache().find(song.id);
    if (local != null) return _LocalAudioSource(local, tag: song.id);
    final temp = await _cache().tempPathFor(song.id);
    if (temp == null) return AudioSource.uri(song.audio!, tag: song.id);
    // Baja la canción entera de una vez (la radio luego descansa) y la sirve
    // al reproductor mientras llega.
    return LockCachingAudioSource(
      song.audio!,
      cacheFile: File(temp),
      tag: song.id,
    );
  }

  void _onPlayerState(PlayerState state) {
    _emit();
    // Terminó la última de la cola: sigue siendo la actual.
    if (state.processingState == ProcessingState.completed) {
      final song = _songAt(_player.currentIndex);
      if (song != null) {
        unawaited(
          _cache().finished(song, listenedEnough: true, stillCurrent: true),
        );
      }
    }
  }

  /// Cambio de pista (o una vuelta completa con repetir una).
  void _onDiscontinuity(PositionDiscontinuity discontinuity) {
    if (_loading) return;
    final previous = discontinuity.previousEvent;
    final sameItem = previous.currentIndex == discontinuity.event.currentIndex;
    final completed =
        discontinuity.reason == PositionDiscontinuityReason.autoAdvance;
    if (!completed && sameItem) return; // seek dentro de la misma canción
    final song = _songAt(previous.currentIndex);
    if (song == null) return;
    unawaited(
      _cache().finished(
        song,
        listenedEnough:
            completed || previous.updatePosition >= minListenToCache,
        stillCurrent: sameItem,
      ),
    );
  }

  Future<void> _leaveCurrent() async {
    final song = _songAt(_player.currentIndex);
    if (song == null) return;
    await _cache().finished(
      song,
      listenedEnough:
          _player.position >= minListenToCache ||
          _player.processingState == ProcessingState.completed,
      stillCurrent: false,
    );
  }

  Song? _songAt(int? index) {
    final sequence = _player.sequence;
    if (index == null || index < 0 || index >= sequence.length) return null;
    return _songsById[sequence[index].tag];
  }

  static MediaItem _mediaItem(Song song) {
    final cover = song.coverLarge ?? song.cover;
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artistName,
      duration: song.duration,
      // La pantalla de bloqueo solo carga portadas por red o archivo.
      artUri:
          cover != null &&
              (cover.scheme.startsWith('http') || cover.scheme == 'file')
          ? cover
          : null,
    );
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _changes.close();
  }
}

/// Sirve al reproductor nativo el audio descargado, descifrado al vuelo por
/// rangos (seek sin leer el archivo entero y sin escribirlo en claro).
final class _LocalAudioSource extends StreamAudioSource {
  _LocalAudioSource(this._audio, {required super.tag});

  final LocalAudio _audio;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final from = start ?? 0;
    final to = end ?? _audio.length;
    return StreamAudioResponse(
      sourceLength: _audio.length,
      contentLength: to - from,
      offset: from,
      stream: _audio.read(from, to),
      contentType: _audio.contentType,
    );
  }
}
