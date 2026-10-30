import '../domain/song.dart';

/// Filas de la vista `catalog_songs` (y de `search_songs`, que devuelve el
/// mismo tipo) → [Song]. Las rutas firmadas llegan sin dominio: se antepone
/// el del CDN.
final class CatalogSongRow {
  CatalogSongRow({required String cdnBaseUrl})
    : _cdn = cdnBaseUrl.endsWith('/')
          ? cdnBaseUrl.substring(0, cdnBaseUrl.length - 1)
          : cdnBaseUrl;

  final String _cdn;

  static const columns =
      'id,created_at,title,artist_name,genre_id,duration_ms,cover_path,'
      'cover_large_path,audio_path,audio_size_bytes,audio_sha256,description';

  Song song(Map<String, dynamic> row) => Song(
    id: row['id'] as String,
    title: row['title'] as String,
    artistName: row['artist_name'] as String,
    duration: Duration(milliseconds: (row['duration_ms'] as num).toInt()),
    genreId: (row['genre_id'] as num?)?.toInt(),
    description: row['description'] as String?,
    cover: _url(row['cover_path']),
    coverLarge: _url(row['cover_large_path']),
    audio: _url(row['audio_path']),
    audioSizeBytes: (row['audio_size_bytes'] as num?)?.toInt(),
    audioSha256: row['audio_sha256'] as String?,
  );

  /// `null` si la canción no tiene ese archivo, si el usuario no puede
  /// escucharla (audio) o si aún no está configurado el secreto de firma.
  Uri? _url(Object? path) => path is String ? Uri.parse('$_cdn/$path') : null;
}
