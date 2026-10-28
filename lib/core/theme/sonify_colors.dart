import 'package:flutter/material.dart';

/// Tokens de color de Sonify (ver CLAUDE.md → Sistema visual).
/// Es el único lugar de la app con colores escritos a mano.
abstract final class SonifyColors {
  static const primary = Color(0xFFDB4437);
  static const onPrimary = Color(0xFFFFFFFF);

  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF2F2F2);
  static const lightOnSurface = Color(0xFF000000);
  static const lightOnSurfaceVariant = Color(0xFF8A8A8A);
  static const lightOutline = Color(0xFFE6E6E6);

  static const darkSurface = Color(0xFF121212);
  static const darkSurfaceVariant = Color(0xFF2A2A2A);
  static const darkOnSurface = Color(0xFFFFFFFF);
  static const darkOnSurfaceVariant = Color(0xFFA0A0A0);
  static const darkOutline = Color(0xFF333333);

  /// El Login es igual en claro y oscuro: foto + degradado a negro, texto blanco.
  static const loginForeground = Color(0xFFFFFFFF);
  static const loginScrim = Color(0xFF000000);
  static const loginScrimClear = Color(0x00000000);
}
