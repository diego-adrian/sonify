import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result.dart';
import '../domain/upload_failure.dart';
import '../domain/upload_ports.dart';
import '../domain/upload_request.dart';

/// 1. `create-upload` (Edge Function) crea la canción y da URLs prefirmadas.
/// 2. Portada (si hay) y audio se suben directo a B2 con
///    `background_downloader` (sigue en segundo plano y reintenta).
/// 3. `complete-upload` confirma en B2 y pasa la canción a "processing".
final class SupabaseUploadRepository implements UploadRepository {
  SupabaseUploadRepository(this._functions, {FileDownloader? downloader})
    : _downloader = downloader ?? FileDownloader();

  final FunctionsClient _functions;
  final FileDownloader _downloader;

  @override
  Future<Result<String, UploadFailure>> upload(
    UploadRequest request, {
    required void Function(double progress) onProgress,
  }) async {
    final tempCopies = <File>[];
    try {
      final created = await _functions.invoke(
        'create-upload',
        body: {
          'title': request.title,
          'genre_id': request.genreId,
          'license': request.license.code,
          'rights_accepted': true,
          'content_type': request.contentType,
          'size_bytes': request.file.sizeBytes,
          'description': request.description,
          'cover_content_type': request.coverContentType,
          'cover_size_bytes': request.cover?.sizeBytes,
        },
      );
      final data = created.data as Map<String, dynamic>;
      final songId = data['song_id'] as String;
      final uploadUrl = data['upload_url'] as String;
      final headers = (data['headers'] as Map).cast<String, String>();

      // Progreso total ponderado por bytes (portada + audio).
      final cover = request.cover;
      final coverUrl = data['cover_upload_url'] as String?;
      final coverBytes = cover != null && coverUrl != null
          ? cover.sizeBytes
          : 0;
      final totalBytes = coverBytes + request.file.sizeBytes;

      if (cover != null && coverUrl != null) {
        final ok = await _put(
          path: cover.path,
          url: coverUrl,
          headers: (data['cover_headers'] as Map).cast<String, String>(),
          displayName: request.title,
          tempCopies: tempCopies,
          onProgress: (p) => onProgress(p * coverBytes / totalBytes),
        );
        if (!ok) return const Err(UploadFailure.network);
      }

      final ok = await _put(
        path: request.file.path,
        url: uploadUrl,
        headers: headers,
        displayName: request.title,
        tempCopies: tempCopies,
        onProgress: (p) =>
            onProgress((coverBytes + p * request.file.sizeBytes) / totalBytes),
      );
      if (!ok) return const Err(UploadFailure.network);

      await _functions.invoke('complete-upload', body: {'song_id': songId});
      return Ok(songId);
    } on FunctionException catch (error) {
      debugPrint('Subida: ${error.status} ${error.details}');
      return Err(_failureFor(error));
    } on SocketException {
      return const Err(UploadFailure.network);
    } finally {
      for (final copy in tempCopies) {
        await copy.delete().catchError((Object _) => copy);
      }
    }
  }

  Future<bool> _put({
    required String path,
    required String url,
    required Map<String, String> headers,
    required String displayName,
    required List<File> tempCopies,
    required void Function(double progress) onProgress,
  }) async {
    final (baseDirectory, directory, filename, copy) = await _locate(path);
    if (copy != null) tempCopies.add(copy);

    final task = UploadTask(
      url: url,
      filename: filename,
      directory: directory,
      baseDirectory: baseDirectory,
      httpRequestMethod: 'PUT',
      post: 'binary',
      // En subidas binarias la librería fija Content-Type = mimeType; debe
      // ser exactamente el que firmó el servidor o B2 rechaza la firma.
      mimeType: headers['Content-Type'],
      headers: {
        ...headers,
        // Sin Content-Disposition automático: no hace falta en B2.
        'Content-Disposition': '',
      },
      updates: Updates.statusAndProgress,
      retries: 3,
      displayName: displayName,
    );
    final status = await _downloader.upload(
      task,
      onProgress: (progress) {
        if (progress >= 0) onProgress(progress);
      },
    );
    if (status.status != TaskStatus.complete) {
      debugPrint(
        'Subida a B2: ${status.status} '
        'HTTP ${status.responseStatusCode} ${status.exception} '
        '${status.responseBody}',
      );
      return false;
    }
    return true;
  }

  /// `background_downloader` necesita el archivo dentro de un directorio de
  /// la app. Si el selector lo dejó en otro sitio, se copia a temporales.
  Future<(BaseDirectory, String, String, File?)> _locate(String path) async {
    try {
      final (base, dir, name) = await Task.split(filePath: path);
      return (base, dir, name, null);
    } on Object {
      final tmp = await getTemporaryDirectory();
      final target = File(p.join(tmp.path, 'uploads', p.basename(path)));
      await target.parent.create(recursive: true);
      final copy = await File(path).copy(target.path);
      final (base, dir, name) = await Task.split(filePath: copy.path);
      return (base, dir, name, copy);
    }
  }

  static UploadFailure _failureFor(FunctionException error) {
    final code = switch (error.details) {
      {'error': final String code} => code,
      _ => null,
    };
    return switch ((error.status, code)) {
      (_, 'unsupported_cover_type') => UploadFailure.coverUnsupported,
      (_, 'cover_too_large') => UploadFailure.coverTooLarge,
      (_, 'not_admin') => UploadFailure.notAdmin,
      (413, _) => UploadFailure.tooLarge,
      (415, _) => UploadFailure.unsupportedType,
      (429, _) => UploadFailure.dailyLimit,
      (_, 'description_too_long') => UploadFailure.descriptionTooLong,
      (_, 'invalid_title') => UploadFailure.invalidTitle,
      (_, 'rights_not_accepted') => UploadFailure.rightsNotAccepted,
      _ => UploadFailure.unknown,
    };
  }
}
