import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/lifecycle/app_lifecycle_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../player_providers.dart';

/// Barra de progreso arrastrable (Figma node 106:97).
///
/// El reproductor informa la posición con poca frecuencia (ahorro de
/// batería). Entre muestras, la barra extrapola con un reloj local y solo se
/// repinta cuando avanza un píxel físico: movimiento continuo con muy pocas
/// actualizaciones por segundo. Con la app en segundo plano no corre nada.
class PlaybackProgressBar extends ConsumerStatefulWidget {
  const PlaybackProgressBar({
    super.key,
    required this.duration,
    required this.enabled,
    required this.playing,
    required this.onSeek,
  });

  final Duration duration;

  /// `false` si la canción mostrada no es la que está cargada.
  final bool enabled;

  /// Sonando de verdad (no en pausa ni cargando).
  final bool playing;
  final ValueChanged<Duration> onSeek;

  @override
  ConsumerState<PlaybackProgressBar> createState() =>
      _PlaybackProgressBarState();
}

class _PlaybackProgressBarState extends ConsumerState<PlaybackProgressBar> {
  static const _minTick = Duration(milliseconds: 16);
  static const _maxTick = Duration(milliseconds: 250);

  /// Última posición conocida y el reloj desde que se recibió.
  Duration _anchor = Duration.zero;
  final Stopwatch _clock = Stopwatch();
  Timer? _timer;
  double _trackPhysicalPx = 900;
  bool _resumed = true;

  /// `false` con la pestaña oculta (`TickerMode`): no publica en vano.
  bool _visible = true;

  final _shown = ValueNotifier<Duration>(Duration.zero);
  final _shownSecond = ValueNotifier<int>(0);

  /// Posición mientras el usuario arrastra (no se pide seek hasta soltar).
  double? _dragMs;

  bool get _running =>
      widget.enabled &&
      widget.playing &&
      _resumed &&
      _visible &&
      widget.duration > Duration.zero;

  Duration get _estimate {
    final value = _clock.isRunning ? _anchor + _clock.elapsed : _anchor;
    if (value < Duration.zero) return Duration.zero;
    return value > widget.duration ? widget.duration : value;
  }

  @override
  void initState() {
    super.initState();
    _resumed = ref.read(appResumedProvider);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible != _visible) {
      _visible = visible;
      _sync();
    }
  }

  @override
  void didUpdateWidget(PlaybackProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) _anchorAt(Duration.zero);
    if (oldWidget.playing != widget.playing ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.duration != widget.duration) {
      _sync();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shown.dispose();
    _shownSecond.dispose();
    super.dispose();
  }

  void _anchorAt(Duration position) {
    _anchor = position;
    _clock.reset();
    if (_running) _clock.start();
    _publish();
  }

  /// Arranca o para el reloj y el timer según el estado.
  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (!_running) {
      // Congela donde va.
      _anchor = _estimate;
      _clock
        ..stop()
        ..reset();
      _publish();
      return;
    }
    _clock.start();
    // Cada cuánto avanza un píxel físico de la barra.
    final perPixel = Duration(
      microseconds: (widget.duration.inMicroseconds / _trackPhysicalPx).round(),
    );
    final tick = perPixel < _minTick
        ? _minTick
        : (perPixel > _maxTick ? _maxTick : perPixel);
    _timer = Timer.periodic(tick, (_) => _publish());
  }

  void _publish() {
    if (_dragMs != null) return;
    final position = _estimate;
    _shown.value = position;
    _shownSecond.value = position.inSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeStyle = AppTypography.caption.copyWith(color: scheme.onSurface);
    final totalMs = widget.duration.inMilliseconds.toDouble();

    if (widget.enabled) {
      ref.listen(positionProvider, (_, next) {
        if (next.value case final position?) _anchorAt(position);
      });
    }
    ref.listen(appResumedProvider, (_, resumed) {
      _resumed = resumed;
      _sync();
    });

    return Row(
      children: [
        ValueListenableBuilder<int>(
          valueListenable: _shownSecond,
          builder: (_, seconds, _) => _TimeLabel(
            text: _format(Duration(seconds: seconds)),
            style: timeStyle,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final physical =
                    constraints.maxWidth *
                    MediaQuery.devicePixelRatioOf(context);
                if ((physical - _trackPhysicalPx).abs() > 1) {
                  _trackPhysicalPx = physical;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _sync();
                  });
                }
                return RepaintBoundary(
                  child: ValueListenableBuilder<Duration>(
                    valueListenable: _shown,
                    builder: (_, position, _) =>
                        _slider(scheme, totalMs, position),
                  ),
                );
              },
            ),
          ),
        ),
        _TimeLabel(text: _format(widget.duration), style: timeStyle),
      ],
    );
  }

  Widget _slider(ColorScheme scheme, double totalMs, Duration position) {
    final max = totalMs <= 0 ? 1.0 : totalMs;
    final value = (_dragMs ?? position.inMilliseconds.toDouble()).clamp(
      0.0,
      max,
    );

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 10,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primaryContainer,
        disabledActiveTrackColor: scheme.primary,
        disabledInactiveTrackColor: scheme.primaryContainer,
        thumbColor: scheme.primary,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: widget.enabled ? 7 : 0,
          disabledThumbRadius: 0,
        ),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        max: max,
        value: value,
        onChanged: widget.enabled && totalMs > 0
            ? (v) {
                _dragMs = v;
                _shown.value = Duration(milliseconds: v.round());
                _shownSecond.value = _shown.value.inSeconds;
              }
            : null,
        onChangeEnd: widget.enabled
            ? (v) {
                final target = Duration(milliseconds: v.round());
                _dragMs = null;
                // Ancla ya en el destino para no saltar atrás mientras el
                // reproductor confirma el seek.
                _anchorAt(target);
                widget.onSeek(target);
              }
            : null,
      ),
    );
  }

  static String _format(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Tiempo con ancho fijo: cada dígito ocupa una celda del ancho del dígito
/// más ancho de la fuente. Así ni la etiqueta ni la barra se mueven cuando
/// cambian los números (Poppins no tiene cifras tabulares).
class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.text, required this.style});

  final String text;
  final TextStyle style;

  static final _digitWidthCache = <TextStyle, double>{};

  static double _digitWidth(TextStyle style, TextScaler scaler) {
    return _digitWidthCache.putIfAbsent(style, () {
      var widest = 0.0;
      for (var digit = 0; digit <= 9; digit++) {
        final painter = TextPainter(
          text: TextSpan(text: '$digit', style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        if (painter.width > widest) widest = painter.width;
        painter.dispose();
      }
      return widest.ceilToDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final cell = _digitWidth(
      style.copyWith(fontSize: scaler.scale(style.fontSize ?? 13)),
      TextScaler.noScaling,
    );

    // Para lectores de pantalla se lee el tiempo completo, no dígito a dígito.
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final char in text.split(''))
            char == ':'
                ? Text(char, style: style)
                : SizedBox(
                    width: cell,
                    child: Text(
                      char,
                      style: style,
                      textAlign: TextAlign.center,
                    ),
                  ),
        ],
      ),
    );
  }
}
