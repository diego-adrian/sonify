// StreamAudioSource es la única vía de just_audio para servir al reproductor
// bytes que pasan por la app (aquí, mientras se guardan en un archivo).
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:just_audio/just_audio.dart';

/// Streaming que baja la canción entera de una vez a [file] mientras suena
/// (la radio descansa después, y si se escucha lo suficiente pasa a la caché
/// de lo escuchado), como `LockCachingAudioSource`, pero **cancelable**: al
/// saltar la canción se corta la descarga en vez de bajarla igual hasta el
/// final (datos y batería).
///
/// Mientras baja escribe en `{file}.part` y al terminar lo renombra a [file];
/// el tipo que informó el CDN queda en `{file}.mime`.
final class CachingStreamSource extends StreamAudioSource {
  CachingStreamSource(
    this.uri, {
    required this.file,
    required super.tag,
    this.aheadLimit = defaultAheadLimit,
    this.networkTimeout = defaultNetworkTimeout,
  });

  /// Un rango que empieza más allá de lo bajado + esto (seek lejos) se pide
  /// aparte al CDN en vez de esperar a que llegue la descarga completa.
  static const defaultAheadLimit = 512 * 1024;

  /// Máximo sin recibir nada de la red. `HttpClient` no tiene límite: con
  /// señal débil o tras cambiar de red, una petición sobre una conexión muerta
  /// no falla nunca y el reproductor nativo la espera hasta 2 minutos.
  static const defaultNetworkTimeout = Duration(seconds: 15);

  final Uri uri;
  final File file;
  final int aheadLimit;
  final Duration networkTimeout;

  _Download? _download;
  final _rangeClients = <HttpClient>{};

  /// Bajando todavía (para decidir si cancelar).
  bool get downloading => _download?.active ?? false;

  /// Ya está entera en [file].
  bool get downloaded => (_download?.completed ?? false) && file.existsSync();

  /// Termina cuando la descarga completa acabó (o falló / se canceló).
  Future<void> get downloadFinished =>
      _download?.finished ?? Future<void>.value();

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    if (await file.exists() && !downloading) return _fromFile(start, end);

    var download = _download;
    // Falló, se canceló o ya bajó pero se borró el temporal.
    if (download == null || !download.active) {
      download = _download = _Download(uri, file, networkTimeout);
      unawaited(download.start());
    }
    await download.headers;
    final total = download.length ?? await download.lengthWhenDone;
    final from = start ?? 0;
    final to = math.min(end ?? total, total);

    if (from > download.received + aheadLimit) return _ranged(from, to, total);
    return StreamAudioResponse(
      rangeRequestsSupported: true,
      sourceLength: total,
      contentLength: to - from,
      offset: from,
      contentType: download.contentType,
      stream: download.read(from, to),
    );
  }

  /// Corta la descarga (y los rangos pedidos aparte) y borra lo bajado a
  /// medias. Si se vuelve a pedir, empieza de nuevo.
  Future<void> cancel() async {
    final download = _download;
    _download = null;
    for (final client in _rangeClients) {
      client.close(force: true);
    }
    _rangeClients.clear();
    await download?.cancel();
  }

  Future<StreamAudioResponse> _fromFile(int? start, int? end) async {
    final total = await file.length();
    final from = start ?? 0;
    final to = math.min(end ?? total, total);
    final mime = File('${file.path}.mime');
    return StreamAudioResponse(
      rangeRequestsSupported: true,
      sourceLength: total,
      contentLength: to - from,
      offset: from,
      contentType: await mime.exists()
          ? await mime.readAsString()
          : _Download.defaultContentType,
      stream: file.openRead(from, to),
    );
  }

  Future<StreamAudioResponse> _ranged(int from, int to, int total) async {
    final client = HttpClient()..connectionTimeout = networkTimeout;
    _rangeClients.add(client);
    try {
      final request = await client.getUrl(uri).timeout(networkTimeout);
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=$from-${to - 1}');
      final response = await request.close().timeout(networkTimeout);
      if (response.statusCode != HttpStatus.partialContent) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      return StreamAudioResponse(
        rangeRequestsSupported: true,
        sourceLength: total,
        contentLength: to - from,
        offset: from,
        contentType:
            response.headers.contentType?.mimeType ??
            _Download.defaultContentType,
        stream: response
            .timeout(networkTimeout)
            .transform(
              StreamTransformer.fromHandlers(
                handleError: (error, stackTrace, sink) {
                  _rangeClients.remove(client);
                  client.close(force: true);
                  sink.addError(error, stackTrace);
                },
                handleDone: (sink) {
                  _rangeClients.remove(client);
                  client.close();
                  sink.close();
                },
              ),
            ),
      );
    } on Object {
      _rangeClients.remove(client);
      client.close(force: true);
      rethrow;
    }
  }
}

/// La descarga completa de una canción a disco, que varios lectores pueden
/// seguir mientras avanza.
final class _Download {
  _Download(this.uri, this.file, this._timeout) {
    _client.connectionTimeout = _timeout;
  }

  static const defaultContentType = 'audio/mp4';

  /// Lo que se le entrega al reproductor de una vez.
  static const _readChunk = 64 * 1024;

  final Uri uri;
  final File file;
  final Duration _timeout;
  final _client = HttpClient();
  final _headers = Completer<void>();
  final _finished = Completer<void>();

  /// Avisa a los lectores que llegó más audio (o que terminó o falló).
  final _progress = StreamController<void>.broadcast();

  StreamSubscription<List<int>>? _subscription;
  RandomAccessFile? _output;

  int? length;
  String contentType = defaultContentType;

  /// Bytes ya escritos en disco (se pueden leer).
  int received = 0;
  bool _done = false;
  bool _cancelled = false;
  Object? _error;

  File get _part => File('${file.path}.part');

  Future<void> get headers => _headers.future;
  Future<void> get finished => _finished.future;
  bool get active => !_done && !_cancelled && _error == null;
  bool get completed => _done;

  Future<int> get lengthWhenDone async {
    await finished;
    if (_error case final error?) throw error;
    return received;
  }

  Future<void> start() async {
    try {
      final request = await _client.getUrl(uri).timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      if (_cancelled) return;
      length = response.contentLength >= 0 ? response.contentLength : null;
      contentType = response.headers.contentType?.mimeType ?? contentType;
      await _part.parent.create(recursive: true);
      await File('${file.path}.mime').writeAsString(contentType);
      _output = await _part.open(mode: FileMode.write);
      _headers.complete();

      _subscription = response
          .timeout(_timeout)
          .listen(
            (data) async {
              // Cada bloque queda en disco antes de avisar a los lectores.
              _subscription!.pause();
              try {
                await _output!.writeFrom(data);
                received += data.length;
                _progress.add(null);
              } on Object catch (error) {
                await _fail(error);
                return;
              }
              if (!_cancelled) _subscription!.resume();
            },
            onDone: _complete,
            onError: _fail,
            cancelOnError: true,
          );
    } on Object catch (error) {
      await _fail(error);
    }
  }

  Future<void> _complete() async {
    if (_cancelled) return;
    try {
      await _output?.close();
      _output = null;
      await _part.rename(file.path);
      _done = true;
    } on Object catch (error) {
      // Se borró el temporal mientras bajaba (cambió la canción).
      _error = error;
    }
    _client.close();
    _progress.add(null);
    if (!_finished.isCompleted) _finished.complete();
  }

  Future<void> _fail(Object error) async {
    if (_done || _cancelled) return;
    _error = error;
    if (!_headers.isCompleted) {
      _headers.completeError(error);
      // Nadie más espera los encabezados: que no quede como no atendido.
      unawaited(_headers.future.catchError((Object _) {}));
    }
    await _discard();
  }

  Future<void> cancel() async {
    if (_done || _cancelled) return;
    _cancelled = true;
    if (!_headers.isCompleted) {
      _headers.completeError(const HttpException('Cancelada'));
      unawaited(_headers.future.catchError((Object _) {}));
    }
    await _discard();
  }

  Future<void> _discard() async {
    await _subscription?.cancel();
    _client.close(force: true);
    try {
      await _output?.close();
    } on Object {
      // Ya cerrado.
    }
    _output = null;
    if (await _part.exists()) await _part.delete();
    _progress.add(null);
    if (!_finished.isCompleted) _finished.complete();
  }

  /// Bytes de [from] a [to] a medida que llegan a disco.
  Stream<List<int>> read(int from, int to) async* {
    final input = await _openForRead();
    try {
      var position = from;
      while (position < to) {
        if (position >= received) {
          if (_cancelled) throw const HttpException('Cancelada');
          if (_error case final error?) throw error;
          if (_done) break;
          await _progress.stream.first;
          continue;
        }
        final count = math.min(math.min(received, to) - position, _readChunk);
        await input.setPosition(position);
        final bytes = await input.read(count);
        if (bytes.isEmpty) break;
        yield bytes;
        position += bytes.length;
      }
    } finally {
      await input.close();
    }
  }

  /// El temporal mientras baja, o el archivo final si ya se renombró.
  Future<RandomAccessFile> _openForRead() async {
    try {
      return await _part.open();
    } on FileSystemException {
      return file.open();
    }
  }
}
