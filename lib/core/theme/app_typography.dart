import 'package:flutter/painting.dart';

/// Escala tipográfica de Sonify: Poppins Light/Regular como el Login, SemiBold
/// (600) solo en títulos de pantalla/sección y Medium (500) en el de la canción
/// actual. El color lo pone cada widget.
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
  static const _medium = FontWeight.w500;
  static const _semiBold = FontWeight.w600;

  /// "Sonify" en el Login.
  static const brand = TextStyle(fontSize: 42, fontWeight: _light, height: 1.2);

  /// Título de la canción actual en la Home.
  static const headline = TextStyle(fontSize: 20, fontWeight: _medium);

  /// Títulos de pantalla y de secciones.
  static const title = TextStyle(fontSize: 14, fontWeight: _semiBold);

  /// Barra de Descargas, Premium y Biblioteca.
  static const appBarTitle = TextStyle(fontSize: 15, fontWeight: _semiBold);

  /// Filas de canciones y listas, y mini-reproductor.
  static const trackTitle = TextStyle(fontSize: 14, fontWeight: _regular);
  static const trackSubtitle = TextStyle(fontSize: 11, fontWeight: _light);

  /// Texto general, artista en la Home, botones, saludo.
  static const body = TextStyle(fontSize: 15, fontWeight: _light);

  /// Texto secundario (resúmenes, estados).
  static const bodySmall = TextStyle(fontSize: 14, fontWeight: _light);

  /// Nombres del menú inferior.
  static const navLabel = TextStyle(fontSize: 11, fontWeight: _regular);

  /// Tiempos de la barra de progreso.
  static const caption = TextStyle(
    fontSize: 13,
    fontWeight: _light,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
