// StreamAudioSource es la única vía de just_audio para audio que no es un
// archivo/URL legible por el sistema (aquí, descifrado al vuelo).
// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../catalog/domain/song.dart';
import '../domain/audio_player_port.dart';
import '../domain/local_audio.dart';
import '../domain/playback_snapshot.dart';
import 'sonify_audio_handler.dart';

/// Adaptador del puerto de reproducción sobre [SonifyAudioHandler].
final class AudioServicePlayer implements AudioPlayerPort {
  AudioServicePlayer(this._handler, this._library) {
    _subscriptions = [
      _player.sequenceStateStream.listen((_) => _emit()),
      _player.playerStateStream.listen((_) => _emit()),
      _player.durationStream.listen((_) => _emit()),
    ];
  }

  final SonifyAudioHandler _handler;

  /// Descargas del usuario actual: si una canción está en el dispositivo,
  /// suena sin red.
  final LocalAudioLibrary Function() _library;
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
    _songsById
      ..clear()
      ..addEntries(songs.map((song) => MapEntry(song.id, song)));
    final sources = await Future.wait(songs.map(_source));
    await _handler.load(songs.map(_mediaItem).toList(), sources, startIndex);
    // `play()` de just_audio no termina hasta pausar: no se espera.
    unawaited(_handler.play());
  }

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
  Future<void> stop() => _handler.stop();

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
      duration: _player.duration,
    );
    _changes.add(_last);
  }

  Future<AudioSource> _source(Song song) async {
    final local = await _library().find(song.id);
    if (local != null) return _LocalAudioSource(local, tag: song.id);
    return AudioSource.uri(song.audio!, tag: song.id);
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
