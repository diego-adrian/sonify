import 'package:sonify/core/result.dart';
import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/library/domain/library.dart';
import 'package:sonify/features/library/domain/library_repository.dart';

/// Biblioteca en memoria. Por defecto premium (escucha todo) y no admin.
/// [catalog] son las canciones que se pueden guardar: al guardarlas, la
/// biblioteca devuelve su versión con audio (como hace la vista firmada).
final class FakeLibraryRepository implements LibraryRepository {
  FakeLibraryRepository({
    this.isPremium = true,
    this.isAdmin = false,
    this.limit = 5,
    List<Song> catalog = const [],
  }) : _catalog = {for (final song in catalog) song.id: song};

  bool isPremium;
  bool isAdmin;
  final int limit;
  final Map<String, Song> _catalog;

  /// `null` = responde; si no, todas las llamadas fallan con este error.
  LibraryFailure? failWith;

  final saved = <String>[];
  final playlists = <String, ({String name, List<String> songs})>{};
  int _nextPlaylist = 1;
  int loadCalls = 0;

  @override
  Future<Result<Library, LibraryFailure>> load() async {
    loadCalls++;
    if (failWith case final failure?) return Err(failure);
    return Ok(
      Library(
        account: Account(
          isPremium: isPremium,
          isAdmin: isAdmin,
          libraryLimit: limit,
          premiumPriceCents: 300,
          premiumCurrency: 'USD',
        ),
        songs: [for (final id in saved.reversed) ?_catalog[id]],
        playlists: [
          for (final MapEntry(:key, :value) in playlists.entries)
            Playlist(id: key, name: value.name, songIds: [...value.songs]),
        ],
      ),
    );
  }

  Result<void, LibraryFailure> _save(String songId) {
    if (saved.contains(songId)) return const Ok(null);
    if (!isPremium && saved.length >= limit) {
      return const Err(LibraryFailure.limitReached);
    }
    saved.add(songId);
    return const Ok(null);
  }

  @override
  Future<Result<void, LibraryFailure>> saveSong(String songId) async =>
      failWith != null ? Err(failWith!) : _save(songId);

  @override
  Future<Result<void, LibraryFailure>> removeSong(String songId) async {
    if (failWith case final failure?) return Err(failure);
    saved.remove(songId);
    for (final playlist in playlists.values) {
      playlist.songs.remove(songId);
    }
    return const Ok(null);
  }

  @override
  Future<Result<void, LibraryFailure>> createPlaylist(String name) async {
    if (failWith case final failure?) return Err(failure);
    playlists['p${_nextPlaylist++}'] = (name: name, songs: <String>[]);
    return const Ok(null);
  }

  @override
  Future<Result<void, LibraryFailure>> renamePlaylist(
    String id,
    String name,
  ) async {
    if (failWith case final failure?) return Err(failure);
    playlists[id] = (name: name, songs: playlists[id]!.songs);
    return const Ok(null);
  }

  @override
  Future<Result<void, LibraryFailure>> deletePlaylist(String id) async {
    if (failWith case final failure?) return Err(failure);
    playlists.remove(id);
    return const Ok(null);
  }

  @override
  Future<Result<void, LibraryFailure>> addToPlaylist(
    String playlistId,
    String songId,
  ) async {
    if (failWith case final failure?) return Err(failure);
    final result = _save(songId);
    if (result is Err) return result;
    final songs = playlists[playlistId]!.songs;
    if (!songs.contains(songId)) songs.add(songId);
    return const Ok(null);
  }

  @override
  Future<Result<void, LibraryFailure>> removeFromPlaylist(
    String playlistId,
    String songId,
  ) async {
    if (failWith case final failure?) return Err(failure);
    playlists[playlistId]!.songs.remove(songId);
    return const Ok(null);
  }
}
