/// Medidas compartidas de la interfaz. Las miniaturas siguen las de Spotify.
abstract final class AppSizes {
  /// Portada en filas de canciones (Home, Descargas).
  static const thumbnailTrack = 48.0;

  /// Portada del mini-reproductor.
  static const thumbnailMini = 40.0;

  /// Portada en listas de biblioteca (playlists, álbumes, artistas).
  static const thumbnailLibrary = 64.0;

  /// Alto de una fila de canción: miniatura + 8 px arriba y abajo.
  static const trackRowHeight = 64.0;

  /// Botones redondos de las filas (reproducir, descargar). 44 px es el
  /// mínimo táctil de Apple.
  static const rowButton = 44.0;

  /// Radio de las portadas cuadradas.
  static const thumbnailRadius = 6.0;
}
