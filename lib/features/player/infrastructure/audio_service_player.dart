// StreamAudioSource es la única vía de just_audio para audio que no es un
// archivo/URL legible por el sistema (aquí, descifrado al vuelo).
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/network/media_url.dart';
import '../../catalog/domain/song.dart';
import '../domain/audio_player_port.dart';
import '../domain/local_audio.dart';
import '../domain/playback_snapshot.dart';
import 'caching_stream_source.dart';
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
      _player.currentIndexStream.listen((_) => _trimStreams()),
    ];
    _handler.onLeavingTrack = () => unawaited(_leaveCurrent());
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

  /// URL remota con que se cargó cada canción de la cola (sin las locales).
  final _loadedUrls = <String, Uri>{};

  /// Streaming de la cola que se va guardando, por id de canción.
  final _streams = <String, CachingStreamSource>{};

  /// La que suena. Al dejarla, de su temporal se ocupa `finished`.
  String? _currentId;
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
      await _cancelStreams();
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

  Future<void> _load(List<Song> songs, int startIndex) {
    _loadedUrls.clear();
    return _handler.load(
      songs.map(_mediaItem).toList(),
      // Con los datos más nuevos de cada una (ver updateSongs).
      () => Future.wait(songs.map((song) => _source(_songsById[song.id]!))),
      startIndex,
      sourcesExpired: _hasExpiredSources,
    );
  }

  @override
  void updateSongs(Iterable<Song> songs) {
    for (final song in songs) {
      final current = _songsById[song.id];
      if (current == null) continue;
      if (fresherMediaUrl(current.audio, song.audio) != current.audio) {
        _songsById[song.id] = song;
      }
    }
  }

  /// Alguna cargada con una URL vencida para la que ya hay una nueva.
  bool _hasExpiredSources() => _loadedUrls.entries.any(
    (loaded) =>
        isMediaUrlExpired(loaded.value) &&
        !isMediaUrlExpired(_songsById[loaded.key]?.audio),
  );

  @override
  Future<void> play() async => unawaited(_handler.play());

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> togglePlayback() => _handler.click();

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
    await _cancelStreams();
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
    if (local != null) {
      _loadedUrls.remove(song.id);
      return _LocalAudioSource(local, tag: song.id);
    }
    _loadedUrls[song.id] = song.audio!;
    final temp = await _cache().tempPathFor(song.id);
    if (temp == null) return AudioSource.uri(song.audio!, tag: song.id);
    // Baja la canción entera de una vez (la radio luego descansa) y la sirve
    // al reproductor mientras llega; se corta si se salta (_trimStreams).
    unawaited(_streams.remove(song.id)?.cancel());
    return _streams[song.id] = CachingStreamSource(
      song.audio!,
      file: File(temp),
      tag: song.id,
    );
  }

  /// Al cambiar de canción, solo siguen bajando la actual y la siguiente
  /// (el reproductor la precarga): saltar no gasta datos en lo que se dejó, y
  /// lo que ya se bajó de una saltada no queda en claro en el disco.
  void _trimStreams() {
    final current = _songAt(_player.currentIndex)?.id;
    // El índice puede avisar dos veces por salto: la segunda ya no sabría cuál
    // era la anterior y podría borrarla antes de que se guarde en la caché.
    if (current == _currentId) return;
    final previous = _currentId;
    _currentId = current;
    if (_streams.isEmpty) return;
    final keep = {current, _songAt(_player.nextIndex)?.id};
    for (final entry in _streams.entries) {
      if (keep.contains(entry.key)) continue;
      if (entry.value.downloading) {
        unawaited(entry.value.cancel());
      } else if (entry.key != previous && entry.value.downloaded) {
        unawaited(_cache().discardTemporary(entry.key));
      }
    }
  }

  Future<void> _cancelStreams() async {
    final streams = _streams.values.toList();
    _streams.clear();
    for (final stream in streams) {
      await stream.cancel();
    }
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

  /// Fin de una pista (o una vuelta completa con repetir una). Los saltos del
  /// usuario llegan por `onLeavingTrack`.
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
    _handler.onLeavingTrack = null;
    await _cancelStreams();
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
