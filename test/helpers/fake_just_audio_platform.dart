import 'dart:async';

import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

/// Reproductor nativo falso para probar `just_audio` sin dispositivo.
///
/// Cada seek tarda [seekLatency], como el de iOS (pausa, busca en el
/// `AVPlayerItem` y retoma al terminar), y anota cuántos se pisan.
final class FakeJustAudioPlatform extends JustAudioPlatform {
  FakeJustAudioPlatform({this.seekLatency = const Duration(milliseconds: 300)});

  final Duration seekLatency;
  FakeNativePlayer? player;

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async =>
      player = FakeNativePlayer(request.id, seekLatency);

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async {
    await player?.dispose(DisposeRequest());
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async => DisposeAllPlayersResponse();
}

final class FakeNativePlayer extends AudioPlayerPlatform {
  FakeNativePlayer(super.id, this._seekLatency);

  static const trackDuration = Duration(minutes: 3);

  final Duration _seekLatency;
  final _events = StreamController<PlaybackEventMessage>.broadcast();
  final _data = StreamController<PlayerDataMessage>.broadcast();

  var _state = ProcessingStateMessage.idle;
  var _position = Duration.zero;
  int? _index;
  var _playing = false;
  Completer<void>? _playing$;

  int _seeksInFlight = 0;

  /// Máximo de seeks atendiéndose a la vez (más de 1 = se pisaron).
  int maxConcurrentSeeks = 0;

  /// Índices pedidos en cada seek, en orden.
  final seekedIndices = <int?>[];

  /// URLs de cada carga de la cola (`setAudioSources`), en orden.
  final loadedUrls = <List<String>>[];

  /// Las cargas no terminan nunca: la red no responde y el `AVPlayerItem` se
  /// queda sin estado (en iOS, hasta 2 minutos).
  bool hangLoads = false;

  int? get index => _index;

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _events.stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream => _data.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    final playlist = request.audioSourceMessage;
    loadedUrls.add([
      if (playlist is ConcatenatingAudioSourceMessage)
        for (final child in playlist.children)
          if (child is UriAudioSourceMessage) child.uri,
    ]);
    _index = request.initialIndex ?? 0;
    _position = request.initialPosition ?? Duration.zero;
    if (hangLoads) {
      _state = ProcessingStateMessage.loading;
      _broadcast();
      await Completer<void>().future;
    }
    _state = ProcessingStateMessage.ready;
    _broadcast();
    return LoadResponse(duration: trackDuration);
  }

  /// La siguiente pista no llega: sigue "sonando", esperando datos.
  void stall() {
    _state = ProcessingStateMessage.buffering;
    _broadcast();
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    if (_playing) return PlayResponse();
    _playing = true;
    _broadcast();
    await (_playing$ = Completer<void>()).future;
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    _playing = false;
    _playing$?.complete();
    _playing$ = null;
    _broadcast();
    return PauseResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    seekedIndices.add(request.index);
    _seeksInFlight++;
    if (_seeksInFlight > maxConcurrentSeeks) {
      maxConcurrentSeeks = _seeksInFlight;
    }
    // Como iOS: avisa enseguida el destino (índice y posición) en buffering,
    // y "listo" cuando el AVPlayerItem termina de buscar.
    _position = request.position ?? Duration.zero;
    _index = request.index ?? _index;
    _state = ProcessingStateMessage.buffering;
    _broadcast();
    await Future<void>.delayed(_seekLatency);
    _seeksInFlight--;
    _state = ProcessingStateMessage.ready;
    _broadcast();
    return SeekResponse();
  }

  void _broadcast() => _events.add(
    PlaybackEventMessage(
      processingState: _state,
      updateTime: DateTime.now(),
      updatePosition: _position,
      bufferedPosition: _position,
      duration: trackDuration,
      icyMetadata: null,
      currentIndex: _index,
      androidAudioSessionId: null,
    ),
  );

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async =>
      SetPitchResponse();

  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
    SetSkipSilenceRequest request,
  ) async => SetSkipSilenceResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async => SetShuffleModeResponse();

  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
    SetShuffleOrderRequest request,
  ) async => SetShuffleOrderResponse();

  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
  setAutomaticallyWaitsToMinimizeStalling(
    SetAutomaticallyWaitsToMinimizeStallingRequest request,
  ) async => SetAutomaticallyWaitsToMinimizeStallingResponse();

  @override
  Future<SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse>
  setCanUseNetworkResourcesForLiveStreamingWhilePaused(
    SetCanUseNetworkResourcesForLiveStreamingWhilePausedRequest request,
  ) async => SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse();

  @override
  Future<SetPreferredPeakBitRateResponse> setPreferredPeakBitRate(
    SetPreferredPeakBitRateRequest request,
  ) async => SetPreferredPeakBitRateResponse();

  @override
  Future<SetAllowsExternalPlaybackResponse> setAllowsExternalPlayback(
    SetAllowsExternalPlaybackRequest request,
  ) async => SetAllowsExternalPlaybackResponse();

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
    SetAndroidAudioAttributesRequest request,
  ) async => SetAndroidAudioAttributesResponse();

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    _playing$?.complete();
    _playing$ = null;
    await _events.close();
    await _data.close();
    return DisposeResponse();
  }
}
