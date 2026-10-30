import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/network/media_url.dart';
import '../../catalog/domain/song.dart';
import '../../player/domain/local_audio.dart';
import '../domain/download_entry.dart';
import '../domain/download_ports.dart';
import '../domain/fresh_urls.dart';
import 'device_storage.dart';
import 'download_database.dart';
import 'download_key_store.dart';
import 'encrypted_file.dart';

/// Descargas con `background_downloader` (URLSession en segundo plano en
/// iOS, WorkManager en Android), cifradas con AES-256-CTR al terminar y
/// registradas en Drift. Cada usuario tiene su carpeta, su base y su clave:
/// al cerrar sesión sus descargas se conservan (ocultas) y vuelven al entrar
/// con la misma cuenta; otra cuenta en el mismo teléfono no las ve ni puede
/// descifrarlas. Todo vive en `Application Support/downloads/`, excluido de
/// respaldos:
///
/// ```
/// downloads/users/{userId}/downloads.sqlite   metadatos (Drift)
/// downloads/users/{userId}/tmp/               en curso (se borran al cifrar)
/// downloads/users/{userId}/audio/{id}.enc     audio cifrado: [IV][AES-CTR]
/// downloads/users/{userId}/covers/{id}.img    miniatura de la portada
/// ```
final class BackgroundDownloadRepository
    implements DownloadRepository, LocalAudioLibrary {
  BackgroundDownloadRepository({
    required this.userId,
    FileDownloader? downloader,
    DownloadKeyStore? keys,
    this._refresher,
    this.wifiOnly = true,
    this.maxConcurrent = 4,
  }) : _downloader = downloader ?? FileDownloader(),
       _keys = keys ?? DownloadKeyStore(userId),
       _group = 'sonify.downloads.$userId',
       _base = 'downloads/users/$userId';

  /// `auth.users.id`: un uuid, seguro como nombre de carpeta.
  final String userId;
  final String _group;

  /// Carpeta del usuario, relativa a Application Support.
  final String _base;

  /// Solo Wi-Fi por defecto (el plan de datos del usuario).
  final bool wifiOnly;
  final int maxConcurrent;

  final FileDownloader _downloader;
  final DownloadKeyStore _keys;

  /// URLs firmadas nuevas para reintentar (vencen en 24–48 h).
  final SongRefresher? _refresher;
  late final Future<_Storage> _storage = _open();

  final _progress = <String, double>{};
  final _progressChanges = StreamController<Map<String, double>>.broadcast();
  final _finishing = <String>{};

  @override
  Stream<List<DownloadEntry>> watchAll() async* {
    final storage = await _storage;
    final query = storage.db.select(storage.db.downloads)
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    yield* query.watch().map(
      (rows) => [for (final row in rows) _entry(row, storage)],
    );
  }

  @override
  Stream<Map<String, double>> watchProgress() async* {
    yield Map.unmodifiable(_progress);
    yield* _progressChanges.stream;
  }

  @override
  Future<Set<String>> activeSongIds() async {
    final db = (await _storage).db;
    final query = db.selectOnly(db.downloads)
      ..addColumns([db.downloads.songId])
      ..where(db.downloads.state.equalsValue(DownloadRowState.failed).not());
    return {
      for (final row in await query.get()) row.read(db.downloads.songId)!,
    };
  }

  @override
  Future<void> enqueue(List<Song> songs) async {
    final storage = await _storage;
    for (final song in songs) {
      final audio = song.audio;
      if (audio == null) continue;
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final task = _task(
        id: '${song.id}.a.$stamp',
        url: audio.toString(),
        kind: _Kind.audio,
        songId: song.id,
        directory: '$_base/tmp',
        filename: '${song.id}.part',
      );
      await storage.db
          .into(storage.db.downloads)
          .insertOnConflictUpdate(
            DownloadsCompanion.insert(
              songId: song.id,
              title: song.title,
              artistName: song.artistName,
              genreId: Value(song.genreId),
              description: Value(song.description),
              durationMs: song.duration.inMilliseconds,
              audioUrl: audio.toString(),
              coverUrl: Value(song.cover?.toString()),
              coverLargeUrl: Value(song.coverLarge?.toString()),
              expectedSha256: Value(song.audioSha256),
              state: DownloadRowState.queued,
              taskId: task.taskId,
              createdAt: DateTime.now(),
            ),
          );
      await _downloader.enqueue(task);

      // La miniatura se baja tal cual (no es secreta) para listas offline y
      // la pantalla de bloqueo / CarPlay.
      final cover = song.cover;
      if (cover != null && cover.scheme.startsWith('http')) {
        await _downloader.enqueue(
          _task(
            id: '${song.id}.c.$stamp',
            url: cover.toString(),
            kind: _Kind.cover,
            songId: song.id,
            directory: '$_base/covers',
            filename: '${song.id}.img',
          ),
        );
      }
    }
  }

  @override
  Future<void> remove(String songId) async {
    final storage = await _storage;
    final row = await _row(storage, songId);
    if (row == null) return;
    await _downloader.cancelTaskWithId(row.taskId);
    await _downloader.database.deleteRecordWithId(row.taskId);
    await (storage.db.delete(
      storage.db.downloads,
    )..where((r) => r.songId.equals(songId))).go();
    for (final path in [
      p.join(storage.root, 'tmp', '$songId.part'),
      p.join(storage.root, 'audio', '$songId.enc'),
      p.join(storage.root, 'covers', '$songId.img'),
    ]) {
      await _deleteIfExists(File(path));
    }
    _setProgress(songId, null);
  }

  @override
  Future<void> removeAll() async {
    final storage = await _storage;
    await _downloader.cancelAll(group: _group);
    await _downloader.database.deleteAllRecords(group: _group);
    await storage.db.delete(storage.db.downloads).go();
    for (final folder in _folders) {
      final dir = Directory(p.join(storage.root, folder));
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
    await _keys.delete();
    _progress.clear();
    _progressChanges.add(const {});
  }

  @override
  Future<void> suspend() async {
    final storage = await _storage;
    // Las que estaban bajando quedan en cola y se retoman al volver a entrar
    // (`_reconcile`); así no queda audio en claro bajando sin quien lo cifre.
    await _downloader.cancelAll(group: _group);
    await _downloader.database.deleteAllRecords(group: _group);
    final tmp = Directory(p.join(storage.root, 'tmp'));
    if (await tmp.exists()) await tmp.delete(recursive: true);
    await tmp.create();
    _progress.clear();
    if (!_progressChanges.isClosed) _progressChanges.add(const {});
  }

  @override
  Future<LocalAudio?> find(String songId) async {
    final storage = await _storage;
    final row = await _row(storage, songId);
    final file = row?.audioFile;
    if (row == null || row.state != DownloadRowState.done || file == null) {
      return null;
    }
    final path = p.join(storage.root, file);
    if (!await File(path).exists()) return null;
    return _EncryptedLocalAudio(
      path: path,
      key: await _keys.key(),
      length: plainLengthOf(path),
      contentType: row.contentType ?? 'audio/mp4',
    );
  }

  Future<void> dispose() async {
    _downloader.unregisterCallbacks(group: _group);
    await _progressChanges.close();
    await (await _storage).db.close();
  }

  // --- Interno ---

  static const _folders = ['tmp', 'audio', 'covers'];

  Future<_Storage> _open() async {
    final support = (await getApplicationSupportDirectory()).path;
    final root = p.join(support, _base);
    for (final folder in _folders) {
      await Directory(p.join(root, folder)).create(recursive: true);
    }
    // Nada de iCloud: todo queda solo en el dispositivo.
    await DeviceStorage.excludeFromBackup(p.join(support, 'downloads'));
    await _removeLegacyLayout(p.join(support, 'downloads'));

    final db = DownloadDatabase(
      driftDatabase(
        name: 'downloads',
        native: DriftNativeOptions(databaseDirectory: () async => root),
      ),
    );
    final storage = _Storage(db: db, root: root);

    _downloader.registerCallbacks(
      group: _group,
      taskStatusCallback: _onStatus,
      taskProgressCallback: _onProgress,
    );
    await _downloader.configure(
      globalConfig: [(Config.holdingQueue, (maxConcurrent, null, null))],
    );
    await _downloader.trackTasksInGroup(_group);
    // Entrega lo que terminó mientras la app estaba cerrada o suspendida.
    await _downloader.resumeFromBackground();
    unawaited(_reconcile(storage));
    return storage;
  }

  /// Por si la app murió entre que terminó una descarga y se cifró, o el
  /// sistema perdió la tarea.
  Future<void> _reconcile(_Storage storage) async {
    try {
      await _downloader.rescheduleKilledTasks();
      final queued = await (storage.db.select(
        storage.db.downloads,
      )..where((r) => r.state.equalsValue(DownloadRowState.queued))).get();
      final lost = <Song>[];
      for (final row in queued) {
        final record = await _downloader.database.recordForId(row.taskId);
        switch (record?.status) {
          case TaskStatus.complete:
            await _finishAudio(record!.task, null);
          case TaskStatus.failed || TaskStatus.notFound:
            await _markFailed(storage, row.songId);
          case null:
            lost.add(_remoteSong(row));
          default:
            break;
        }
      }
      // Tras volver a entrar pueden haber pasado días: URLs nuevas.
      if (lost.isNotEmpty) await enqueue(await _withFreshUrls(lost));
    } catch (error, stack) {
      debugPrint('Descargas: no se pudo reconciliar: $error\n$stack');
    }
  }

  DownloadTask _task({
    required String id,
    required String url,
    required _Kind kind,
    required String songId,
    required String directory,
    required String filename,
  }) => DownloadTask(
    taskId: id,
    url: url,
    filename: filename,
    directory: directory,
    baseDirectory: BaseDirectory.applicationSupport,
    group: _group,
    updates: kind == _Kind.audio ? Updates.statusAndProgress : Updates.status,
    requiresWiFi: wifiOnly,
    retries: 3,
    allowPause: kind == _Kind.audio,
    metaData: '${kind.name}:$songId',
  );

  void _onStatus(TaskStatusUpdate update) {
    final (kind, songId) = _parse(update.task.metaData);
    if (songId == null) return;
    unawaited(
      _handleStatus(update, kind, songId).catchError((Object error) {
        debugPrint('Descargas: $songId: $error');
      }),
    );
  }

  Future<void> _handleStatus(
    TaskStatusUpdate update,
    _Kind? kind,
    String songId,
  ) async {
    final storage = await _storage;
    switch ((kind, update.status)) {
      case (_Kind.audio, TaskStatus.complete):
        await _finishAudio(update.task, update.mimeType);
      case (_Kind.audio, TaskStatus.failed || TaskStatus.notFound):
        debugPrint(
          'Descargas: $songId falló (${update.responseStatusCode}): '
          '${update.exception?.description}',
        );
        if (!await _retryWithFreshUrl(storage, update.task, songId)) {
          await _markFailed(storage, songId);
        }
      case (_Kind.cover, TaskStatus.complete):
        if (await _row(storage, songId) == null) {
          // Se quitó la descarga mientras bajaba la portada.
          await _deleteIfExists(File(await update.task.filePath()));
          return;
        }
        await _updateRow(
          storage,
          songId,
          DownloadsCompanion(coverFile: Value(p.join('covers', '$songId.img'))),
        );
      default:
        break;
    }
  }

  void _onProgress(TaskProgressUpdate update) {
    final (kind, songId) = _parse(update.task.metaData);
    if (kind != _Kind.audio || songId == null) return;
    // Valores negativos = estados especiales (fallo, en pausa, en espera).
    if (update.progress >= 0 && update.progress < 1) {
      _setProgress(songId, update.progress);
    }
  }

  Future<void> _finishAudio(Task task, String? mimeType) async {
    final (_, songId) = _parse(task.metaData);
    if (songId == null || !_finishing.add(songId)) return;
    try {
      final storage = await _storage;
      final row = await _row(storage, songId);
      final source = await task.filePath();
      if (row == null || row.taskId != task.taskId) {
        await _deleteIfExists(File(source));
        return;
      }
      if (row.state == DownloadRowState.done) return;
      if (!await File(source).exists()) {
        await _markFailed(storage, songId);
        return;
      }

      final relative = p.join('audio', '$songId.enc');
      final target = p.join(storage.root, relative);
      final info = await encryptFile(
        source: source,
        target: target,
        key: await _keys.key(),
      );
      final expected = row.expectedSha256;
      if (expected != null && expected.toLowerCase() != info.sha256) {
        debugPrint('Descargas: $songId no coincide el SHA-256');
        await _deleteIfExists(File(target));
        await _markFailed(storage, songId);
        return;
      }

      await _updateRow(
        storage,
        songId,
        DownloadsCompanion(
          state: const Value(DownloadRowState.done),
          audioFile: Value(relative),
          contentType: Value(mimeType ?? _guessContentType(row.audioUrl)),
          sizeBytes: Value(await File(target).length()),
        ),
      );
      await _downloader.database.deleteRecordWithId(task.taskId);
      _setProgress(songId, null);
    } finally {
      _finishing.remove(songId);
    }
  }

  /// Si falló porque la URL firmada venció (p. ej. esperó Wi-Fi más de un
  /// día), se vuelve a encolar una vez con una nueva. `false` si no aplica.
  Future<bool> _retryWithFreshUrl(
    _Storage storage,
    Task task,
    String songId,
  ) async {
    if (!isMediaUrlExpired(Uri.tryParse(task.url))) return false;
    final row = await _row(storage, songId);
    if (row == null || row.taskId != task.taskId) return false;
    final song = (await _withFreshUrls([_remoteSong(row)])).single;
    if (isMediaUrlExpired(song.audio)) return false;
    await _deleteIfExists(File(p.join(storage.root, 'tmp', '$songId.part')));
    await enqueue([song]);
    return true;
  }

  Future<List<Song>> _withFreshUrls(List<Song> songs) {
    final refresher = _refresher;
    return refresher == null
        ? Future.value(songs)
        : withFreshUrls(songs, refresher);
  }

  Future<void> _markFailed(_Storage storage, String songId) async {
    await _updateRow(
      storage,
      songId,
      const DownloadsCompanion(state: Value(DownloadRowState.failed)),
    );
    await _deleteIfExists(File(p.join(storage.root, 'tmp', '$songId.part')));
    _setProgress(songId, null);
  }

  Future<Download?> _row(_Storage storage, String songId) => (storage.db.select(
    storage.db.downloads,
  )..where((r) => r.songId.equals(songId))).getSingleOrNull();

  Future<void> _updateRow(
    _Storage storage,
    String songId,
    DownloadsCompanion changes,
  ) => (storage.db.update(
    storage.db.downloads,
  )..where((r) => r.songId.equals(songId))).write(changes);

  void _setProgress(String songId, double? progress) {
    if (progress == null) {
      if (_progress.remove(songId) == null) return;
    } else {
      _progress[songId] = progress;
    }
    if (!_progressChanges.isClosed) {
      _progressChanges.add(Map.unmodifiable(_progress));
    }
  }

  DownloadEntry _entry(Download row, _Storage storage) => DownloadEntry(
    song: _song(row, storage),
    state: switch (row.state) {
      DownloadRowState.queued => DownloadState.queued,
      DownloadRowState.done => DownloadState.done,
      DownloadRowState.failed => DownloadState.failed,
    },
    sizeBytes: row.sizeBytes,
  );

  Song _song(Download row, _Storage storage) {
    final coverFile = row.coverFile;
    final localCover = coverFile == null
        ? null
        : Uri.file(p.join(storage.root, coverFile));
    final cover = localCover ?? _uri(row.coverUrl);
    return Song(
      id: row.songId,
      title: row.title,
      artistName: row.artistName,
      duration: Duration(milliseconds: row.durationMs),
      genreId: row.genreId,
      description: row.description,
      cover: cover,
      // Sin red, la grande no se puede cargar: se usa la miniatura local.
      coverLarge: localCover ?? _uri(row.coverLargeUrl) ?? cover,
      audio: Uri.parse(row.audioUrl),
      audioSha256: row.expectedSha256,
    );
  }

  /// Para volver a encolarla: con las URLs remotas (no la portada local).
  Song _remoteSong(Download row) => Song(
    id: row.songId,
    title: row.title,
    artistName: row.artistName,
    duration: Duration(milliseconds: row.durationMs),
    genreId: row.genreId,
    description: row.description,
    cover: _uri(row.coverUrl),
    coverLarge: _uri(row.coverLargeUrl),
    audio: Uri.parse(row.audioUrl),
    audioSha256: row.expectedSha256,
  );

  static Uri? _uri(String? value) => value == null ? null : Uri.parse(value);

  static (_Kind?, String?) _parse(String metaData) {
    final separator = metaData.indexOf(':');
    if (separator < 0) return (null, null);
    final kind = _Kind.values.asNameMap()[metaData.substring(0, separator)];
    return (kind, metaData.substring(separator + 1));
  }

  static String _guessContentType(String url) =>
      switch (p.extension(Uri.parse(url).path).toLowerCase()) {
        '.mp3' => 'audio/mpeg',
        '.aac' => 'audio/aac',
        '.flac' => 'audio/flac',
        '.wav' => 'audio/wav',
        _ => 'audio/mp4',
      };

  /// Primera versión (sin carpetas por usuario, solo builds de desarrollo).
  // TODO: quitar cuando ya no queden instalaciones de esa versión.
  static Future<void> _removeLegacyLayout(String downloads) async {
    for (final name in ['downloads.sqlite', 'tmp', 'audio', 'covers']) {
      final path = p.join(downloads, name);
      final type = await FileSystemEntity.type(path);
      if (type != FileSystemEntityType.notFound) {
        await (type == FileSystemEntityType.directory
                ? Directory(path)
                : File(path))
            .delete(recursive: true);
      }
    }
  }

  static Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }
}

enum _Kind { audio, cover }

final class _Storage {
  const _Storage({required this.db, required this.root});

  final DownloadDatabase db;

  /// Carpeta del usuario (base de las rutas relativas guardadas).
  final String root;
}

final class _EncryptedLocalAudio implements LocalAudio {
  const _EncryptedLocalAudio({
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
