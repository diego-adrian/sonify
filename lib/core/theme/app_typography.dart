import 'package:flutter/painting.dart';

/// Escala tipográfica de Sonify: Poppins Light/Regular como el Login.
/// No usar pesos mayores a Regular (400). El color lo pone cada widget.
abstract final class AppTypography {
  /// Fuente principal de toda la app (la aplica el tema).
  static const fontFamily = 'Poppins';

  /// Fuente secundaria, alternativa libre (OFL) a la de Spotify, que es
  /// privada. Empaquetada en Light/Regular como Poppins.
  static const secondaryFontFamily = 'Figtree';

  /// Cualquier estilo de la escala con la fuente secundaria:
  /// `AppTypography.secondary(AppTypography.title)`.
  static TextStyle secondary(TextStyle style) =>
      style.copyWith(fontFamily: secondaryFontFamily);
  static const _light = FontWeight.w300;
  static const _regular = FontWeight.w400;

  /// "Sonify" en el Login.
  static const brand = TextStyle(fontSize: 42, fontWeight: _light, height: 1.2);

  /// Título de la canción actual en la Home.
  static const headline = TextStyle(fontSize: 23, fontWeight: _regular);

  /// Títulos de pantalla y de secciones.
  static const title = TextStyle(fontSize: 17, fontWeight: _regular);

  /// Texto general, artista en la Home, botones, saludo.
  /// Filas de canciones (Home y Descargas): un punto menos que title/bodySmall.
  static const trackTitle = TextStyle(fontSize: 16, fontWeight: _regular);
  static const trackSubtitle = TextStyle(fontSize: 13, fontWeight: _light);

  static const body = TextStyle(fontSize: 15, fontWeight: _light);

  /// Texto secundario (resúmenes, estados).
  static const bodySmall = TextStyle(fontSize: 14, fontWeight: _light);

  /// Tiempos de la barra de progreso.
  static const caption = TextStyle(
    fontSize: 13,
    fontWeight: _light,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
