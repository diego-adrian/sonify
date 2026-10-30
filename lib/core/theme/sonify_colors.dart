import 'package:flutter/material.dart';

/// Tokens de color de Sonify (ver CLAUDE.md → Sistema visual).
/// Es el único lugar de la app con colores escritos a mano.
abstract final class SonifyColors {
  static const primary = Color(0xFFDB4437);
  static const onPrimary = Color(0xFFFFFFFF);

  /// Única excepción al rojo: la onda de la canción que está sonando en la
  /// lista y la pestaña activa del menú (pedido del usuario). En el tema es
  /// `tertiary`.
  static const nowPlaying = Color(0xFFFF9D2E);

  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF2F2F2);
  static const lightOnSurface = Color(0xFF000000);
  static const lightOnSurfaceVariant = Color(0xFF8A8A8A);
  static const lightOutline = Color(0xFFE6E6E6);
  static const lightNavBar = lightSurface;
  static const lightNavInactive = lightOnSurface;

  /// Fondo oscuro elegido por el usuario (casi negro con un toque violeta);
  /// el menú (`darkNavBar`) viene de su referencia.
  static const darkSurface = Color(0xFF100F18);
  static const darkSurfaceVariant = Color(0xFF2A2A2A);
  static const darkOnSurface = Color(0xFFFFFFFF);
  static const darkOnSurfaceVariant = Color(0xFFA0A0A0);
  static const darkOutline = Color(0xFF333333);
  static const darkNavBar = Color(0xFF1F222F);
  static const darkNavInactive = Color(0xFF7F8191);

  /// El Login es igual en claro y oscuro: foto + degradado a negro, texto blanco.
  static const loginForeground = Color(0xFFFFFFFF);
  static const loginScrim = Color(0xFF000000);
  static const loginScrimClear = Color(0x00000000);
}
