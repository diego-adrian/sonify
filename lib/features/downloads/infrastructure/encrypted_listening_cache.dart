import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../catalog/domain/song.dart';
import '../../player/domain/local_audio.dart';
import 'encrypted_file.dart';
import 'listening_cache_database.dart';

/// Caché de lo escuchado, cifrada con AES-256-CTR como las descargas, con
/// clave propia del usuario. Vive junto a sus descargas (excluida de
/// respaldos y fuera de la carpeta de cachés: el sistema no la purga):
///
/// ```
/// downloads/users/{userId}/cache/cache.sqlite   metadatos (Drift)
/// downloads/users/{userId}/cache/tmp/           en claro mientras suena
/// downloads/users/{userId}/cache/audio/{id}.enc audio cifrado
/// ```
///
/// Al pasar de [maxBytes] se borra lo que hace más tiempo que no suena, solo
/// en ese momento (sin timers ni revisiones periódicas) y nunca la cola
/// actual.
final class EncryptedListeningCache implements ListeningCache {
  EncryptedListeningCache({
    required Future<String> Function() root,
    required this._key,
    required this._openDatabase,
    this.maxBytes = defaultMaxBytes,
    this._clock = DateTime.now,
  }) : _rootPath = root;

  static const defaultMaxBytes = 300 * 1024 * 1024;

  final int maxBytes;
  final Future<String> Function() _rootPath;
  final Future<Uint8List> Function() _key;
  final ListeningCacheDatabase Function(String root) _openDatabase;
  final DateTime Function() _clock;
  late final Future<_Storage> _storage = _open();

  Set<String> _protected = const {};

  /// Una operación a la vez: guardar, liberar espacio y borrar no se pisan.
  Future<void> _serial = Future.value();

  @override
  Future<String?> tempPathFor(String songId) async =>
      p.join((await _storage).root, 'tmp', '$songId.audio');

  @override
  Future<LocalAudio?> find(String songId) async {
    final storage = await _storage;
    final row = await _row(storage, songId);
    if (row == null) return null;
    final path = p.join(storage.root, row.audioFile);
    if (!await File(path).exists()) {
      await _deleteRow(storage, songId);
      return null;
    }
    return _CachedAudio(
      path: path,
      key: await _key(),
      length: plainLengthOf(path),
      contentType: row.contentType,
    );
  }

  @override
  Stream<List<Song>> watchSongs() async* {
    final storage = await _storage;
    final query = storage.db.select(storage.db.cachedSongs)
      ..orderBy([(row) => OrderingTerm.desc(row.lastPlayedAt)]);
    yield* query.watch().map((rows) => [for (final row in rows) _song(row)]);
  }

  @override
  void protect(Set<String> songIds) => _protected = Set.unmodifiable(songIds);

  @override
  Future<void> finished(
    Song song, {
    required bool listenedEnough,
    required bool stillCurrent,
  }) => _enqueue(() async {
    final storage = await _storage;
    final temp = p.join(storage.root, 'tmp', '${song.id}.audio');

    if (await _row(storage, song.id) != null) {
      await _touch(storage, song.id);
    } else if (listenedEnough && await File(temp).exists()) {
      await _store(storage, song, temp, keepSource: stillCurrent);
    }
    if (!stillCurrent) await _deleteTemporary(storage, song.id);
  });

  @override
  Future<void> clearTemporary() => _enqueue(() async {
    final storage = await _storage;
    await _resetTemporary(storage.root);
  });

  /// Lo que ocupa la caché (para una futura pantalla de almacenamiento).
  Future<int> usedBytes() async => _usedBytes(await _storage);

  Future<void> dispose() async {
    await _serial;
    await (await _storage).db.close();
  }

  // --- Interno ---

  Future<_Storage> _open() async {
    final root = await _rootPath();
    await Directory(p.join(root, 'audio')).create(recursive: true);
    // Si la app murió mientras sonaba algo, no queda audio en claro.
    await _resetTemporary(root);
    return _Storage(db: _openDatabase(root), root: root);
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _serial.then((_) => action()).catchError((Object error) {
      debugPrint('Caché de lo escuchado: $error');
    });
    _serial = next;
    return next;
  }

  Future<void> _store(
    _Storage storage,
    Song song,
    String temp, {
    required bool keepSource,
  }) async {
    final audio = song.audio;
    if (audio == null) return;
    final relative = p.join('audio', '${song.id}.enc');
    final target = p.join(storage.root, relative);
    final info = await encryptFile(
      source: temp,
      target: target,
      key: await _key(),
      keepSource: keepSource,
    );
    final expected = song.audioSha256;
    if (expected != null && expected.toLowerCase() != info.sha256) {
      // Llegó cortado o distinto: mejor no guardarlo.
      debugPrint('Caché de lo escuchado: ${song.id} no coincide el SHA-256');
      await _deleteIfExists(File(target));
      return;
    }
    await storage.db
        .into(storage.db.cachedSongs)
        .insertOnConflictUpdate(
          CachedSongsCompanion.insert(
            songId: song.id,
            title: song.title,
            artistName: song.artistName,
            genreId: Value(song.genreId),
            durationMs: song.duration.inMilliseconds,
            audioUrl: audio.toString(),
            coverUrl: Value(song.cover?.toString()),
            coverLargeUrl: Value(song.coverLarge?.toString()),
            audioFile: relative,
            contentType: await _contentType(temp),
            sizeBytes: await File(target).length(),
            lastPlayedAt: _clock(),
          ),
        );
    await _evict(storage, keep: song.id);
  }

  /// Borra lo que hace más tiempo que no suena hasta volver a caber.
  Future<void> _evict(_Storage storage, {required String keep}) async {
    var used = await _usedBytes(storage);
    if (used <= maxBytes) return;
    final oldestFirst = await (storage.db.select(
      storage.db.cachedSongs,
    )..orderBy([(row) => OrderingTerm.asc(row.lastPlayedAt)])).get();
    for (final row in oldestFirst) {
      if (used <= maxBytes) break;
      if (row.songId == keep || _protected.contains(row.songId)) continue;
      await _deleteIfExists(File(p.join(storage.root, row.audioFile)));
      await _deleteRow(storage, row.songId);
      used -= row.sizeBytes;
    }
  }

  Future<int> _usedBytes(_Storage storage) async {
    final total = storage.db.cachedSongs.sizeBytes.sum();
    final query = storage.db.selectOnly(storage.db.cachedSongs)
      ..addColumns([total]);
    return (await query.getSingle()).read(total) ?? 0;
  }

  Future<void> _touch(_Storage storage, String songId) =>
      (storage.db.update(storage.db.cachedSongs)
            ..where((row) => row.songId.equals(songId)))
          .write(CachedSongsCompanion(lastPlayedAt: Value(_clock())));

  Future<CachedSong?> _row(_Storage storage, String songId) =>
      (storage.db.select(
        storage.db.cachedSongs,
      )..where((row) => row.songId.equals(songId))).getSingleOrNull();

  Future<void> _deleteRow(_Storage storage, String songId) =>
      (storage.db.delete(
        storage.db.cachedSongs,
      )..where((row) => row.songId.equals(songId))).go();

  Future<void> _deleteTemporary(_Storage storage, String songId) async {
    final base = p.join(storage.root, 'tmp', '$songId.audio');
    for (final path in [base, '$base.part', '$base.mime']) {
      await _deleteIfExists(File(path));
    }
  }

  static Future<void> _resetTemporary(String root) async {
    final tmp = Directory(p.join(root, 'tmp'));
    if (await tmp.exists()) await tmp.delete(recursive: true);
    await tmp.create(recursive: true);
  }

  /// El reproductor guarda junto al audio el tipo que informó el CDN.
  static Future<String> _contentType(String temp) async {
    final mime = File('$temp.mime');
    if (await mime.exists()) {
      final value = (await mime.readAsString()).split(';').first.trim();
      if (value.startsWith('audio/')) return value;
    }
    return 'audio/mp4';
  }

  static Song _song(CachedSong row) => Song(
    id: row.songId,
    title: row.title,
    artistName: row.artistName,
    duration: Duration(milliseconds: row.durationMs),
    genreId: row.genreId,
    cover: row.coverUrl == null ? null : Uri.parse(row.coverUrl!),
    coverLarge: row.coverLargeUrl == null
        ? null
        : Uri.parse(row.coverLargeUrl!),
    audio: Uri.parse(row.audioUrl),
  );

  static Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }
}

final class _Storage {
  const _Storage({required this.db, required this.root});

  final ListeningCacheDatabase db;
  final String root;
}

final class _CachedAudio implements LocalAudio {
  const _CachedAudio({
    required this.path,
    required this.key,
    required this.length,
    required this.contentType,
  });

  final String path;
  final Uint8List key;

  @override
  final int length;

  @override
  final String contentType;

  @override
  Stream<List<int>> read(int start, int end) =>
      decryptedRange(path: path, key: key, start: start, end: end);
}
