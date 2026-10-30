import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nav_bar_colors.dart';

/// Una pestaña del menú.
final class SonifyNavItem {
  const SonifyNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Menú inferior: barra plana casi opaca (fondo al 96 %, sin desenfoque),
/// pestañas iguales con ícono de línea y nombre pequeño
/// debajo; la activa en `tertiary` (el naranja de lo que suena). Fondo e
/// inactivos en `NavBarColors`.
///
/// Va en `Scaffold.bottomNavigationBar` con `extendBody: true`: las listas
/// reciben el alto del menú como padding inferior
/// (`MediaQuery.paddingOf(context).bottom`).
///
/// Sin `BackdropFilter`: con el fondo casi opaco el desenfoque no se notaba y
/// la GPU lo recalculaba en cada cuadro (scroll, onda de lo que suena).
class SonifyNavBar extends StatelessWidget {
  const SonifyNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// Alto de la barra sin el margen inferior del sistema.
  /// Holgado: unos 12 px arriba y abajo del ícono con su nombre.
  static const barHeight = 68.0;

  /// Opacidad del fondo: deja intuir el contenido sin desenfocarlo.
  static const _opacity = 0.96;

  /// Del margen del sistema (la barrita de inicio del iPhone, ~34 px) se usa
  /// solo lo necesario para no tocarla.
  static double bottomPadding(BuildContext context) =>
      math.max(MediaQuery.paddingOf(context).bottom - 16, 8);

  final List<SonifyNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = NavBarColors.of(context);

    return ColoredBox(
      color: colors.background.withValues(alpha: _opacity),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding(context)),
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SonifyNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected
        ? scheme.tertiary
        : NavBarColors.of(context).inactive;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 26, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.navLabel.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
