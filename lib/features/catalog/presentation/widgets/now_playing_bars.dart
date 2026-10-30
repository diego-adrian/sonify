import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Onda animada (barras de ecualizador) de la canción que está sonando.
///
/// Batería: avanza a [fps] cuadros por segundo con un reloj propio, no con
/// un `AnimationController` (que pide un cuadro en cada vsync: 60–120 por
/// segundo). Así la app no dibuja más de lo necesario y solo repinta su
/// propio cuadro (`RepaintBoundary` + `CustomPaint` con `repaint`). Se
/// detiene en pestañas ocultas (`TickerMode`), con la app en segundo plano o
/// la pantalla apagada, y con "reducir movimiento" queda quieta.
class NowPlayingBars extends StatefulWidget {
  const NowPlayingBars({super.key, required this.color, this.size = 22});

  /// Suficiente para que se vea fluida a este tamaño.
  static const fps = 12;

  /// Una vuelta completa de la onda.
  static const period = Duration(milliseconds: 1200);

  final Color color;
  final double size;

  @override
  State<NowPlayingBars> createState() => _NowPlayingBarsState();
}

class _NowPlayingBarsState extends State<NowPlayingBars>
    with WidgetsBindingObserver {
  static const _frame = Duration(microseconds: 1000000 ~/ NowPlayingBars.fps);

  final _phase = ValueNotifier<double>(0.3);
  final _clock = Stopwatch();
  Timer? _timer;
  bool _visible = true;
  bool _still = false;
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _resumed = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    _still = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    final run = _visible && _resumed && !_still;
    if (run == (_timer != null)) return;
    if (!run) {
      _timer?.cancel();
      _timer = null;
      _clock.stop();
      return;
    }
    _clock.start();
    _timer = Timer.periodic(_frame, (_) {
      final period = NowPlayingBars.period.inMicroseconds;
      _phase.value = (_clock.elapsedMicroseconds % period) / period;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.square(widget.size),
      painter: _BarsPainter(_phase, widget.color),
    ),
  );
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this._progress, this._color) : super(repaint: _progress);

  final ValueNotifier<double> _progress;
  final Color _color;

  /// Desfase de cada barra para que no suban todas a la vez.
  static const _phases = [0.0, 0.55, 0.25, 0.8];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _color;
    final gap = size.width * 0.12;
    final barWidth = (size.width - gap * (_phases.length - 1)) / _phases.length;
    for (var i = 0; i < _phases.length; i++) {
      final wave = math.sin((_progress.value + _phases[i]) * 2 * math.pi);
      // Entre el 25 % y el 100 % del alto.
      final height = size.height * (0.625 + 0.375 * wave);
      final left = i * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - height, barWidth, height),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old._color != _color;
}
