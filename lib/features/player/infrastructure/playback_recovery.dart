import 'dart:async';

/// Recupera la reproducción cuando la pista falla por la red (p. ej. al
/// pasar de datos a Wi-Fi a mitad de una canción, o si se queda cargando).
///
/// `just_audio` no reintenta: tras el error queda sin pista cargada y `play()`
/// no hace nada, así que ni la app ni el reloj ni la pantalla de bloqueo
/// responden. Aquí se marca la pista para recargarla: se reintenta sola unas
/// pocas veces (el cambio de red suele durar segundos) y, si no, al pulsar
/// play se recarga en el punto donde iba.
final class PlaybackRecovery {
  PlaybackRecovery({
    required this.reload,
    required this.retry,
    this.maxAutoRetries = 3,
    this.firstRetryDelay = const Duration(seconds: 2),
  });

  /// Vuelve a cargar la pista que falló. `true` si cargó.
  final Future<bool> Function() reload;

  /// Reintento automático: recargar y reproducir.
  final void Function() retry;

  final int maxAutoRetries;
  final Duration firstRetryDelay;

  bool _needsReload = false;
  bool _resumeWanted = false;
  int _autoRetries = 0;
  Timer? _retryTimer;
  Future<bool>? _reloading;

  /// La pista falló y todavía no se recargó.
  bool get needsReload => _needsReload;

  /// La pista falló. Si estaba sonando, se reintenta sola con espera
  /// creciente (2 s, 4 s, 8 s); después solo al pulsar play.
  void failed({required bool wasPlaying}) {
    _needsReload = true;
    _resumeWanted = _resumeWanted || wasPlaying;
    _retryTimer?.cancel();
    _retryTimer = null;
    if (!_resumeWanted || _autoRetries >= maxAutoRetries) return;
    final delay = firstRetryDelay * (1 << _autoRetries);
    _autoRetries++;
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (_needsReload) retry();
    });
  }

  /// Antes de reproducir: recarga si hace falta (una sola recarga aunque
  /// lleguen varios play seguidos). `false` si no se pudo.
  Future<bool> ensureLoaded() async {
    if (!_needsReload) return true;
    final loaded = await (_reloading ??= reload().whenComplete(
      () => _reloading = null,
    ));
    if (loaded) _needsReload = false;
    return loaded;
  }

  /// Pausa pedida por el usuario: no reanudar por su cuenta.
  void paused() {
    _resumeWanted = false;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// La pista volvió a sonar bien.
  void recovered() {
    _autoRetries = 0;
    _resumeWanted = false;
  }

  /// Nueva cola: lo anterior ya no aplica.
  void reset() {
    paused();
    _needsReload = false;
    _autoRetries = 0;
  }

  void dispose() => reset();
}
