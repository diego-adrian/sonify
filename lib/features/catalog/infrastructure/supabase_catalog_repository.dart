import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result.dart';
import '../domain/catalog_failure.dart';
import '../domain/catalog_page.dart';
import '../domain/catalog_repository.dart';
import '../domain/genre.dart';
import '../../downloads/domain/download_ports.dart';
import '../domain/song.dart';
import 'catalog_song_row.dart';

/// Catálogo desde la vista `catalog_songs`: una sola consulta trae las
/// canciones listas, el artista y las rutas firmadas del CDN. La RLS decide
/// qué ve cada usuario (públicas + las propias).
final class SupabaseCatalogRepository
    implements CatalogRepository, SongRefresher {
  SupabaseCatalogRepository(this._client, {required String cdnBaseUrl})
    : _rows = CatalogSongRow(cdnBaseUrl: cdnBaseUrl);

  final SupabaseClient _client;
  final CatalogSongRow _rows;

  static const _columns = CatalogSongRow.columns;

  /// Máximo de resultados de una búsqueda (la función lo limita a 50).
  static const searchLimit = 30;

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
      [for (final row in page) _rows.song(row)],
      next: rows.length > limit && last != null
          ? SongCursor(
              createdAt: last['created_at'] as String,
              id: last['id'] as String,
            )
          : null,
    );
  });

  /// Título o artista, sin distinguir tildes ni mayúsculas (RPC
  /// `search_songs`, que aplica la misma RLS que el catálogo).
  @override
  Future<Result<List<Song>, CatalogFailure>> searchSongs(String query) =>
      _guard(() async {
        final rows = await _client
            .rpc(
              'search_songs',
              params: {'p_query': query, 'p_limit': searchLimit},
            )
            .select(_columns);
        return [for (final row in rows) _rows.song(row)];
      });

  /// Las mismas canciones con rutas firmadas nuevas.
  @override
  Future<List<Song>> fresh(List<String> songIds) async {
    if (songIds.isEmpty) return const [];
    final result = await _guard(() async {
      final rows = await _client
          .from('catalog_songs')
          .select(_columns)
          .inFilter('id', songIds);
      return [for (final row in rows) _rows.song(row)];
    });
    return switch (result) {
      Ok(:final value) => value,
      Err() => const [],
    };
  }

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
