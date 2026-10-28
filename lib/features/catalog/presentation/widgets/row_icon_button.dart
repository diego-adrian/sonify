import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';

/// Botón redondo con borde de las filas de canciones (reproducir, descargar,
/// borrar…): mismo tamaño y estilo en la Home y en Descargas.
class RowIconButton extends StatelessWidget {
  const RowIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final Widget icon;
  final String tooltip;

  /// `null` = deshabilitado (se ve atenuado).
  final VoidCallback? onPressed;

  /// Color del ícono; por defecto el del texto.
  final Color? color;

  static const disabledOpacity = 0.38;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = color ?? scheme.onSurface;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(AppSizes.rowButton),
        backgroundColor: scheme.surface,
        foregroundColor: foreground,
        side: BorderSide(color: scheme.outline),
        disabledBackgroundColor: scheme.surface,
        disabledForegroundColor: foreground.withValues(alpha: disabledOpacity),
      ),
      icon: icon,
    );
  }
}
