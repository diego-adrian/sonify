import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result.dart';
import '../../catalog/infrastructure/catalog_song_row.dart';
import '../domain/library.dart';
import '../domain/library_repository.dart';

/// Biblioteca en Supabase: `library_songs`, `playlists`, `playlist_songs` y la
/// RPC `my_account`. La RLS limita todo al usuario del JWT; el cupo de la
/// cuenta gratis lo hace cumplir un trigger (`library_limit`).
final class SupabaseLibraryRepository implements LibraryRepository {
  SupabaseLibraryRepository(this._client, {required String cdnBaseUrl})
    : _rows = CatalogSongRow(cdnBaseUrl: cdnBaseUrl);

  final SupabaseClient _client;
  final CatalogSongRow _rows;

  @override
  Future<Result<Library, LibraryFailure>> load() => _guard(() async {
    final (account, songs, playlists) = await (
      _client.rpc<Map<String, dynamic>>('my_account'),
      _client
          .from('catalog_songs')
          .select(CatalogSongRow.columns)
          .eq('in_library', true)
          .order('saved_at', ascending: false),
      _client
          .from('playlists')
          .select('id,name,playlist_songs(song_id,added_at)')
          .order('created_at')
          .order('added_at', referencedTable: 'playlist_songs'),
    ).wait;
    return Library(
      account: Account(
        isPremium: account['is_premium'] as bool? ?? false,
        isAdmin: account['is_admin'] as bool? ?? false,
        libraryLimit: (account['library_limit'] as num?)?.toInt(),
        premiumPriceCents: (account['premium_price_cents'] as num?)?.toInt(),
        premiumCurrency: account['premium_currency'] as String?,
      ),
      songs: [for (final row in songs) _rows.song(row)],
      playlists: [
        for (final row in playlists)
          Playlist(
            id: row['id'] as String,
            name: row['name'] as String,
            songIds: [
              for (final entry in row['playlist_songs'] as List<dynamic>)
                (entry as Map<String, dynamic>)['song_id'] as String,
            ],
          ),
      ],
    );
  });

  @override
  Future<Result<void, LibraryFailure>> saveSong(String songId) =>
      _guard(() => _client.from('library_songs').insert({'song_id': songId}));

  @override
  Future<Result<void, LibraryFailure>> removeSong(String songId) => _guard(
    () => _client.from('library_songs').delete().eq('song_id', songId),
  );

  @override
  Future<Result<void, LibraryFailure>> createPlaylist(String name) =>
      _guard(() => _client.from('playlists').insert({'name': name}));

  @override
  Future<Result<void, LibraryFailure>> renamePlaylist(String id, String name) =>
      _guard(
        () => _client.from('playlists').update({'name': name}).eq('id', id),
      );

  @override
  Future<Result<void, LibraryFailure>> deletePlaylist(String id) =>
      _guard(() => _client.from('playlists').delete().eq('id', id));

  @override
  Future<Result<void, LibraryFailure>> addToPlaylist(
    String playlistId,
    String songId,
  ) => _guard(
    () => _client.from('playlist_songs').insert({
      'playlist_id': playlistId,
      'song_id': songId,
    }),
  );

  @override
  Future<Result<void, LibraryFailure>> removeFromPlaylist(
    String playlistId,
    String songId,
  ) => _guard(
    () => _client
        .from('playlist_songs')
        .delete()
        .eq('playlist_id', playlistId)
        .eq('song_id', songId),
  );

  static Future<Result<T, LibraryFailure>> _guard<T>(
    Future<T> Function() body,
  ) async {
    try {
      return Ok(await body());
    } on PostgrestException catch (error) {
      // Ya estaba guardada / en la playlist: no es un error para el usuario.
      if (error.code == '23505') return Ok(null as T);
      debugPrint('Biblioteca: $error');
      return Err(switch (error) {
        PostgrestException(code: 'P0001', message: 'library_limit') =>
          LibraryFailure.limitReached,
        PostgrestException(code: '23514') => LibraryFailure.invalidName,
        _ => LibraryFailure.unknown,
      });
    } on Exception catch (error) {
      debugPrint('Biblioteca sin conexión: $error');
      return const Err(LibraryFailure.network);
    }
  }
}
