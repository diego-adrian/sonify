import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/result.dart';
import '../../catalog/domain/song.dart';
import '../domain/library.dart';
import '../domain/library_repository.dart';

/// Guarda en el dispositivo la última biblioteca que llegó y la devuelve sin
/// red (o si el backend no responde en [timeout]): las playlists y el cupo
/// siguen visibles en un sótano, y lo descargado suena. Los cambios sí
/// necesitan red.
final class OfflineLibraryRepository implements LibraryRepository {
  const OfflineLibraryRepository(
    this._remote, {
    required this.snapshot,
    this.timeout = const Duration(seconds: 12),
  });

  final LibraryRepository _remote;

  /// Archivo de la copia (`downloads/users/{userId}/library.json`: por
  /// usuario y excluido de los respaldos como las descargas).
  final Future<File> Function() snapshot;
  final Duration timeout;

  @override
  Future<Result<Library, LibraryFailure>> load() async {
    final remote = await _withTimeout(_remote.load());
    switch (remote) {
      case Ok(:final value):
        await _write(value);
        return remote;
      case Err(error: LibraryFailure.network):
        return switch (await _read()) {
          final cached? => Ok(cached),
          null => remote,
        };
      case Err():
        return remote;
    }
  }

  @override
  Future<Result<void, LibraryFailure>> saveSong(String songId) =>
      _withTimeout(_remote.saveSong(songId));

  @override
  Future<Result<void, LibraryFailure>> removeSong(String songId) =>
      _withTimeout(_remote.removeSong(songId));

  @override
  Future<Result<void, LibraryFailure>> createPlaylist(String name) =>
      _withTimeout(_remote.createPlaylist(name));

  @override
  Future<Result<void, LibraryFailure>> renamePlaylist(String id, String name) =>
      _withTimeout(_remote.renamePlaylist(id, name));

  @override
  Future<Result<void, LibraryFailure>> deletePlaylist(String id) =>
      _withTimeout(_remote.deletePlaylist(id));

  @override
  Future<Result<void, LibraryFailure>> addToPlaylist(
    String playlistId,
    String songId,
  ) => _withTimeout(_remote.addToPlaylist(playlistId, songId));

  @override
  Future<Result<void, LibraryFailure>> removeFromPlaylist(
    String playlistId,
    String songId,
  ) => _withTimeout(_remote.removeFromPlaylist(playlistId, songId));

  Future<Result<T, LibraryFailure>> _withTimeout<T>(
    Future<Result<T, LibraryFailure>> request,
  ) => request.timeout(
    timeout,
    onTimeout: () => const Err(LibraryFailure.network),
  );

  Future<void> _write(Library library) async {
    try {
      final file = await snapshot();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(LibrarySnapshot.encode(library)));
    } on Object catch (error) {
      debugPrint('Biblioteca: no se pudo guardar la copia local: $error');
    }
  }

  Future<Library?> _read() async {
    try {
      final file = await snapshot();
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return LibrarySnapshot.decode(json as Map<String, dynamic>);
    } on Object catch (error) {
      debugPrint('Biblioteca: copia local ilegible: $error');
      return null;
    }
  }
}

/// Formato de la copia local (DTO: no sale de infraestructura).
abstract final class LibrarySnapshot {
  static const _version = 1;

  static Map<String, Object?> encode(Library library) => {
    'v': _version,
    'account': {
      'is_premium': library.account.isPremium,
      'is_admin': library.account.isAdmin,
      'library_limit': library.account.libraryLimit,
      'premium_price_cents': library.account.premiumPriceCents,
      'premium_currency': library.account.premiumCurrency,
    },
    'songs': [for (final song in library.songs) _song(song)],
    'playlists': [
      for (final playlist in library.playlists)
        {'id': playlist.id, 'name': playlist.name, 'songs': playlist.songIds},
    ],
  };

  static Library? decode(Map<String, dynamic> json) {
    if (json['v'] != _version) return null;
    final account = json['account'] as Map<String, dynamic>;
    return Library(
      account: Account(
        isPremium: account['is_premium'] as bool,
        isAdmin: account['is_admin'] as bool,
        libraryLimit: account['library_limit'] as int?,
        premiumPriceCents: account['premium_price_cents'] as int?,
        premiumCurrency: account['premium_currency'] as String?,
      ),
      songs: [
        for (final song in json['songs'] as List<dynamic>)
          _decodeSong(song as Map<String, dynamic>),
      ],
      playlists: [
        for (final playlist in json['playlists'] as List<dynamic>)
          Playlist(
            id: (playlist as Map<String, dynamic>)['id'] as String,
            name: playlist['name'] as String,
            songIds: (playlist['songs'] as List<dynamic>).cast<String>(),
          ),
      ],
    );
  }

  static Map<String, Object?> _song(Song song) => {
    'id': song.id,
    'title': song.title,
    'artist': song.artistName,
    'duration_ms': song.duration.inMilliseconds,
    'genre_id': song.genreId,
    'description': song.description,
    'cover': song.cover?.toString(),
    'cover_large': song.coverLarge?.toString(),
    'audio': song.audio?.toString(),
    'size': song.audioSizeBytes,
    'sha256': song.audioSha256,
  };

  static Song _decodeSong(Map<String, dynamic> json) => Song(
    id: json['id'] as String,
    title: json['title'] as String,
    artistName: json['artist'] as String,
    duration: Duration(milliseconds: json['duration_ms'] as int),
    genreId: json['genre_id'] as int?,
    description: json['description'] as String?,
    cover: _uri(json['cover']),
    coverLarge: _uri(json['cover_large']),
    audio: _uri(json['audio']),
    audioSizeBytes: json['size'] as int?,
    audioSha256: json['sha256'] as String?,
  );

  static Uri? _uri(Object? value) => value is String ? Uri.parse(value) : null;
}

/// Sin sesión no hay biblioteca.
final class SignedOutLibraryRepository implements LibraryRepository {
  const SignedOutLibraryRepository();

  static const _err = Err<Never, LibraryFailure>(LibraryFailure.unknown);

  @override
  Future<Result<Library, LibraryFailure>> load() async => _err;

  @override
  Future<Result<void, LibraryFailure>> saveSong(String songId) async => _err;

  @override
  Future<Result<void, LibraryFailure>> removeSong(String songId) async => _err;

  @override
  Future<Result<void, LibraryFailure>> createPlaylist(String name) async =>
      _err;

  @override
  Future<Result<void, LibraryFailure>> renamePlaylist(
    String id,
    String name,
  ) async => _err;

  @override
  Future<Result<void, LibraryFailure>> deletePlaylist(String id) async => _err;

  @override
  Future<Result<void, LibraryFailure>> addToPlaylist(
    String playlistId,
    String songId,
  ) async => _err;

  @override
  Future<Result<void, LibraryFailure>> removeFromPlaylist(
    String playlistId,
    String songId,
  ) async => _err;
}
