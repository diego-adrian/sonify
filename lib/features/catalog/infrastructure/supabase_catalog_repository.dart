import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result.dart';
import '../domain/catalog_failure.dart';
import '../domain/catalog_page.dart';
import '../domain/catalog_repository.dart';
import '../domain/genre.dart';
import '../domain/song.dart';

/// Catálogo desde la vista `catalog_songs`: una sola consulta trae las
/// canciones listas, el artista y las rutas firmadas del CDN. La RLS decide
/// qué ve cada usuario (públicas + las propias).
final class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository(this._client, {required String cdnBaseUrl})
    : _cdn = cdnBaseUrl.endsWith('/')
          ? cdnBaseUrl.substring(0, cdnBaseUrl.length - 1)
          : cdnBaseUrl;

  final SupabaseClient _client;
  final String _cdn;

  static const _columns =
      'id,created_at,title,artist_name,genre_id,duration_ms,cover_path,'
      'cover_large_path,audio_path,audio_size_bytes,audio_sha256';

  @override
  Future<Result<List<Genre>, CatalogFailure>> getGenres() => _guard(() async {
    final rows = await _client
        .from('genres')
        .select('id,slug,name')
        .order('sort_order')
        .order('name');
    return [
      for (final row in rows)
        Genre(
          id: (row['id'] as num).toInt(),
          slug: row['slug'] as String,
          name: row['name'] as String,
        ),
    ];
  });

  @override
  Future<Result<CatalogPage, CatalogFailure>> getSongs({
    int? genreId,
    int limit = catalogPageSize,
    SongCursor? after,
  }) => _guard(() async {
    var query = _client.from('catalog_songs').select(_columns);
    if (genreId != null) query = query.eq('genre_id', genreId);
    if (after != null) {
      // Lo que va después de la última recibida, en el mismo orden
      // (created_at desc, id desc). Comillas: la fecha lleva ':' y '.'.
      final at = '"${after.createdAt}"';
      query = query.or(
        'created_at.lt.$at,and(created_at.eq.$at,id.lt.${after.id})',
      );
    }
    // Una de más para saber si hay otra página sin pedirla.
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit + 1);
    final page = rows.take(limit).toList();
    final last = page.isEmpty ? null : page.last;
    return CatalogPage(
      [for (final row in page) _song(row)],
      next: rows.length > limit && last != null
          ? SongCursor(
              createdAt: last['created_at'] as String,
              id: last['id'] as String,
            )
          : null,
    );
  });

  Song _song(Map<String, dynamic> row) => Song(
    id: row['id'] as String,
    title: row['title'] as String,
    artistName: row['artist_name'] as String,
    duration: Duration(milliseconds: (row['duration_ms'] as num).toInt()),
    genreId: (row['genre_id'] as num?)?.toInt(),
    cover: _url(row['cover_path']),
    coverLarge: _url(row['cover_large_path']),
    audio: _url(row['audio_path']),
    audioSizeBytes: (row['audio_size_bytes'] as num?)?.toInt(),
    audioSha256: row['audio_sha256'] as String?,
  );

  /// `null` si la canción no tiene ese archivo o aún no está configurado el
  /// secreto de firma.
  Uri? _url(Object? path) => path is String ? Uri.parse('$_cdn/$path') : null;

  static Future<Result<T, CatalogFailure>> _guard<T>(
    Future<T> Function() body,
  ) async {
    try {
      return Ok(await body());
    } on PostgrestException catch (error) {
      debugPrint('Catálogo: $error');
      return const Err(CatalogFailure.unknown);
    } on Exception catch (error) {
      // Sin red: SocketException, ClientException de http, timeouts…
      debugPrint('Catálogo sin conexión: $error');
      return const Err(CatalogFailure.network);
    }
  }
}
