import 'package:flutter/widgets.dart';

/// Ícono "G" de línea del diseño de Login (viewBox 24×24), dibujado sin
/// depender de un paquete SVG.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GoogleLogoPainter(color),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(const Offset(12, 12), 10, paint);

    final g = Path()
      ..moveTo(12, 12)
      ..lineTo(17, 12)
      ..cubicTo(17, 14.7614, 14.7614, 17, 12, 17)
      ..cubicTo(9.23858, 17, 7, 14.7614, 7, 12)
      ..cubicTo(7, 9.23858, 9.23858, 7, 12, 7)
      ..cubicTo(13.3807, 7, 14.6307, 7.55964, 15.5355, 8.46447);
    canvas.drawPath(g, paint);
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
