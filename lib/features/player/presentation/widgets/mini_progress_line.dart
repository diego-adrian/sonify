import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/lifecycle/app_lifecycle_provider.dart';
import '../player_providers.dart';

/// Línea de progreso fina del mini reproductor (solo muestra, no se arrastra).
///
/// Igual que `PlaybackProgressBar`: el reproductor da la posición ~1 vez por
/// segundo y entre muestras se extrapola con un reloj local que solo publica
/// cuando la línea avanza un píxel físico (en una canción de 3 min, ~5 veces
/// por segundo). Se detiene en pausa, en segundo plano y si la pestaña está
/// oculta (`TickerMode`).
class MiniProgressLine extends ConsumerStatefulWidget {
  const MiniProgressLine({
    super.key,
    required this.duration,
    required this.enabled,
    required this.playing,
  });

  static const thickness = 2.5;

  final Duration duration;

  /// `false` si la canción mostrada no es la que está cargada: línea vacía.
  final bool enabled;

  /// Sonando de verdad (no en pausa ni cargando).
  final bool playing;

  @override
  ConsumerState<MiniProgressLine> createState() => _MiniProgressLineState();
}

class _MiniProgressLineState extends ConsumerState<MiniProgressLine> {
  static const _minTick = Duration(milliseconds: 16);
  static const _maxTick = Duration(milliseconds: 500);

  Duration _anchor = Duration.zero;
  final Stopwatch _clock = Stopwatch();
  Timer? _timer;
  double _physicalWidth = 1000;
  bool _resumed = true;
  bool _visible = true;
  final _fraction = ValueNotifier<double>(0);

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
    // La posición actual, si ya llegó (al aparecer a mitad de canción).
    if (widget.enabled) {
      _anchor = ref.read(positionProvider).value ?? Duration.zero;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    _sync();
  }

  @override
  void didUpdateWidget(MiniProgressLine oldWidget) {
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
    _fraction.dispose();
    super.dispose();
  }

  void _anchorAt(Duration position) {
    _anchor = position;
    _clock.reset();
    if (_running) _clock.start();
    _publish();
  }

  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (!_running) {
      _anchor = _estimate;
      _clock
        ..stop()
        ..reset();
      _publish();
      return;
    }
    _clock.start();
    final perPixel = Duration(
      microseconds: (widget.duration.inMicroseconds / _physicalWidth).round(),
    );
    final tick = perPixel < _minTick
        ? _minTick
        : (perPixel > _maxTick ? _maxTick : perPixel);
    _timer = Timer.periodic(tick, (_) => _publish());
  }

  void _publish() {
    final total = widget.duration.inMicroseconds;
    _fraction.value = !widget.enabled || total <= 0
        ? 0
        : (_estimate.inMicroseconds / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (widget.enabled) {
      ref.listen(positionProvider, (_, next) {
        if (next.value case final position?) _anchorAt(position);
      });
    }
    ref.listen(appResumedProvider, (_, resumed) {
      _resumed = resumed;
      _sync();
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final physical =
            constraints.maxWidth * MediaQuery.devicePixelRatioOf(context);
        if ((physical - _physicalWidth).abs() > 1) {
          _physicalWidth = physical;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _sync();
          });
        }
        return RepaintBoundary(
          child: SizedBox(
            height: MiniProgressLine.thickness,
            width: double.infinity,
            child: CustomPaint(
              painter: _LinePainter(
                _fraction,
                fill: scheme.primary,
                track: scheme.primaryContainer,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this._fraction, {required this.fill, required this.track})
    : super(repaint: _fraction);

  final ValueNotifier<double> _fraction;
  final Color fill;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = track);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * _fraction.value, size.height),
      Paint()..color = fill,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.fill != fill || old.track != track;
}
