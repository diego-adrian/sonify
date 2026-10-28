import 'package:flutter/painting.dart';

/// Escala tipográfica de Sonify: Poppins Light/Regular como el Login.
/// No usar pesos mayores a Regular (400). El color lo pone cada widget.
abstract final class AppTypography {
  static const _light = FontWeight.w300;
  static const _regular = FontWeight.w400;

  /// "Sonify" en el Login.
  static const brand = TextStyle(fontSize: 42, fontWeight: _light, height: 1.2);

  /// Título de la canción actual en la Home.
  static const headline = TextStyle(fontSize: 24, fontWeight: _regular);

  /// Título en filas de pista y pestaña activa.
  static const title = TextStyle(fontSize: 17, fontWeight: _regular);

  /// Texto general, artista en la Home, botones, saludo.
  static const body = TextStyle(fontSize: 15, fontWeight: _light);

  /// Artistas en filas de pista, pestaña inactiva.
  static const bodySmall = TextStyle(fontSize: 14, fontWeight: _light);

  /// Tiempos de la barra de progreso.
  static const caption = TextStyle(
    fontSize: 13,
    fontWeight: _light,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
