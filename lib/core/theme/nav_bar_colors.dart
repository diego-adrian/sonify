import 'package:flutter/material.dart';

/// Colores del menú inferior (fondo e íconos inactivos), por modo. La pestaña
/// activa usa `tertiary`. Se leen con `NavBarColors.of(context)`.
@immutable
final class NavBarColors extends ThemeExtension<NavBarColors> {
  const NavBarColors({required this.background, required this.inactive});

  final Color background;
  final Color inactive;

  static NavBarColors of(BuildContext context) =>
      Theme.of(context).extension<NavBarColors>()!;

  @override
  NavBarColors copyWith({Color? background, Color? inactive}) => NavBarColors(
    background: background ?? this.background,
    inactive: inactive ?? this.inactive,
  );

  @override
  NavBarColors lerp(NavBarColors? other, double t) => other == null
      ? this
      : NavBarColors(
          background: Color.lerp(background, other.background, t)!,
          inactive: Color.lerp(inactive, other.inactive, t)!,
        );
}
