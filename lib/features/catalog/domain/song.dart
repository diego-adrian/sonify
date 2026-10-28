final class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artistName,
    required this.duration,
    this.genreId,
    this.cover,
    this.coverLarge,
    this.audio,
    this.audioSizeBytes,
    this.audioSha256,
  });

  final String id;
  final String title;

  /// Nombre del perfil dueño de la canción (todo usuario es artista).
  final String artistName;
  final Duration duration;
  final int? genreId;

  /// Miniatura para listas. `asset:` (datos de desarrollo) o `https:` (CDN).
  final Uri? cover;

  /// Portada grande para el reproductor; si falta se usa [cover].
  final Uri? coverLarge;

  /// Audio remoto (CDN). Si está descargada, el reproductor usa la copia
  /// local cifrada en su lugar.
  final Uri? audio;

  /// Tamaño y hash del audio según el catálogo (si los trae): sirven para
  /// estimar el espacio de una descarga y verificarla.
  final int? audioSizeBytes;
  final String? audioSha256;
}
