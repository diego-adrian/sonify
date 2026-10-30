import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sonify/features/player/infrastructure/caching_stream_source.dart';

/// CDN de prueba sobre un socket TCP (un `HttpServer` de Dart no avisa
/// cuando el cliente corta): manda el audio en bloques de [chunk] con una
/// pausa entre cada uno y anota si el cliente cortó antes de terminar.
final class _Cdn {
  _Cdn(this.audio, {this.status = 200, this.silent = false, this.hangAfter});

  static const chunk = 1024;

  final Uint8List audio;
  final int status;

  /// Acepta la conexión y nunca responde (conexión muerta).
  final bool silent;

  /// Deja de mandar tras estos bytes, sin cerrar la conexión.
  final int? hangAfter;
  late final ServerSocket server;
  final ranges = <String?>[];
  int sentBytes = 0;
  bool aborted = false;
  final _done = Completer<void>();

  Uri get url => Uri.parse('http://127.0.0.1:${server.port}/audio/x/128.m4a');

  Future<void> start() async {
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(_serve);
  }

  Future<void> _serve(Socket socket) async {
    var closed = false;
    final head = Completer<String>();
    final buffer = StringBuffer();
    socket.listen(
      (data) {
        buffer.write(String.fromCharCodes(data));
        if (!head.isCompleted && buffer.toString().contains('\r\n\r\n')) {
          head.complete(buffer.toString());
        }
      },
      onDone: () => closed = true,
      onError: (Object _) => closed = true,
    );
    final request = await head.future;
    final range = RegExp(
      r'^range: *(.+)\r$',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(request)?[1];
    ranges.add(range);
    if (silent) return;

    if (status != 200) {
      socket.write('HTTP/1.1 $status Forbidden\r\nContent-Length: 0\r\n\r\n');
      await socket.flush();
      await socket.close();
      return;
    }
    var from = 0;
    var to = audio.length;
    final headers = StringBuffer();
    if (range != null) {
      final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(range)!;
      from = int.parse(match[1]!);
      if (match[2]!.isNotEmpty) to = int.parse(match[2]!) + 1;
      headers
        ..write('HTTP/1.1 206 Partial Content\r\n')
        ..write('Content-Range: bytes $from-${to - 1}/${audio.length}\r\n');
    } else {
      headers.write('HTTP/1.1 200 OK\r\n');
    }
    headers
      ..write('Content-Type: audio/mp4\r\n')
      ..write('Accept-Ranges: bytes\r\n')
      ..write('Content-Length: ${to - from}\r\n')
      ..write('Connection: close\r\n\r\n');
    socket.write(headers);
    try {
      for (var i = from; i < to; i += chunk) {
        if (hangAfter != null && i >= hangAfter!) return;
        if (closed) {
          if (range == null) aborted = true;
          break;
        }
        socket.add(audio.sublist(i, i + chunk < to ? i + chunk : to));
        await socket.flush();
        if (range == null) sentBytes = i + chunk < to ? i + chunk : to;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await socket.close();
    } on Object {
      if (range == null) aborted = true;
    } finally {
      if (range == null && !_done.isCompleted) _done.complete();
    }
  }

  /// Termina cuando la descarga completa acabó o se cortó.
  Future<void> get fullRequestFinished => _done.future;

  Future<void> close() => server.close();
}

void main() {
  late Directory dir;
  final audio = Uint8List.fromList(List.generate(200 * 1024, (i) => i % 251));

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('caching_stream_source');
  });

  tearDown(() => dir.delete(recursive: true));

  Future<Uint8List> collect(Stream<List<int>> stream) async {
    final bytes = BytesBuilder();
    await for (final chunk in stream) {
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  test(
    'sirve el audio mientras lo baja y lo deja entero en el archivo',
    () async {
      final cdn = _Cdn(audio);
      await cdn.start();
      addTearDown(cdn.close);
      final file = File(p.join(dir.path, 'a.audio'));
      final source = CachingStreamSource(cdn.url, file: file, tag: 'a');

      final response = await source.request();
      expect(await collect(response.stream), audio);
      await cdn.fullRequestFinished;
      await source.downloadFinished;

      expect(await file.readAsBytes(), audio);
      expect(await File('${file.path}.mime').readAsString(), 'audio/mp4');
      expect(await File('${file.path}.part').exists(), isFalse);
      expect(response.contentType, 'audio/mp4');
      // Una sola descarga, sin rangos aparte.
      expect(cdn.ranges, [null]);
    },
  );

  test('un rango cercano sale de la misma descarga', () async {
    final cdn = _Cdn(audio);
    await cdn.start();
    addTearDown(cdn.close);
    final source = CachingStreamSource(
      cdn.url,
      file: File(p.join(dir.path, 'a.audio')),
      tag: 'a',
    );

    final response = await source.request(1000, 3000);

    expect(await collect(response.stream), audio.sublist(1000, 3000));
    expect(response.offset, 1000);
    expect(response.sourceLength, audio.length);
    await source.cancel();
  });

  test('un rango muy adelante (seek lejos) se pide aparte al CDN', () async {
    final cdn = _Cdn(audio);
    await cdn.start();
    addTearDown(cdn.close);
    final source = CachingStreamSource(
      cdn.url,
      file: File(p.join(dir.path, 'a.audio')),
      tag: 'a',
      aheadLimit: 4096,
    );
    await source.request(0, 2); // empieza la descarga completa

    final response = await source.request(150 * 1024, 160 * 1024);

    expect(
      await collect(response.stream),
      audio.sublist(150 * 1024, 160 * 1024),
    );
    expect(cdn.ranges, contains('bytes=${150 * 1024}-${160 * 1024 - 1}'));
    await source.cancel();
  });

  test('cancelar corta la descarga y borra lo bajado a medias', () async {
    final cdn = _Cdn(audio);
    await cdn.start();
    addTearDown(cdn.close);
    final file = File(p.join(dir.path, 'a.audio'));
    final source = CachingStreamSource(cdn.url, file: file, tag: 'a');

    final response = await source.request(0, 1024);
    await collect(response.stream);
    await source.cancel();
    await cdn.fullRequestFinished.timeout(const Duration(seconds: 5));

    expect(cdn.aborted, isTrue);
    expect(cdn.sentBytes, lessThan(audio.length));
    expect(await file.exists(), isFalse);
    expect(await File('${file.path}.part').exists(), isFalse);
  });

  test('después de cancelar, volver a pedirla empieza de nuevo', () async {
    final cdn = _Cdn(audio);
    await cdn.start();
    addTearDown(cdn.close);
    final file = File(p.join(dir.path, 'a.audio'));
    final source = CachingStreamSource(cdn.url, file: file, tag: 'a');
    await source.request(0, 2);
    await source.cancel();

    final response = await source.request();

    expect(await collect(response.stream), audio);
  });

  test('si se borró el temporal de una ya bajada, la vuelve a bajar', () async {
    final cdn = _Cdn(audio);
    await cdn.start();
    addTearDown(cdn.close);
    final file = File(p.join(dir.path, 'a.audio'));
    final source = CachingStreamSource(cdn.url, file: file, tag: 'a');
    await collect((await source.request()).stream);
    await source.downloadFinished;
    expect(source.downloaded, isTrue);

    await file.delete();
    expect(source.downloaded, isFalse);

    expect(await collect((await source.request()).stream), audio);
  });

  test('un error del CDN (URL vencida) falla la petición', () async {
    final cdn = _Cdn(audio, status: 403);
    await cdn.start();
    addTearDown(cdn.close);
    final source = CachingStreamSource(
      cdn.url,
      file: File(p.join(dir.path, 'a.audio')),
      tag: 'a',
    );

    await expectLater(source.request(), throwsA(isA<HttpException>()));
  });

  test('si el CDN no responde, la petición falla en vez de colgarse', () async {
    final cdn = _Cdn(audio, silent: true);
    await cdn.start();
    addTearDown(cdn.close);
    final source = CachingStreamSource(
      cdn.url,
      file: File(p.join(dir.path, 'a.audio')),
      tag: 'a',
      networkTimeout: const Duration(milliseconds: 100),
    );

    await expectLater(source.request(), throwsA(isA<TimeoutException>()));
  });

  test('si la descarga se queda sin datos, la lectura falla', () async {
    final cdn = _Cdn(audio, hangAfter: 8 * 1024);
    await cdn.start();
    addTearDown(cdn.close);
    final file = File(p.join(dir.path, 'a.audio'));
    final source = CachingStreamSource(
      cdn.url,
      file: file,
      tag: 'a',
      networkTimeout: const Duration(milliseconds: 200),
    );

    final response = await source.request();

    await expectLater(
      collect(response.stream),
      throwsA(isA<TimeoutException>()),
    );
    expect(await File('${file.path}.part').exists(), isFalse);
  });

  test('tras quedarse sin datos, volver a pedirla empieza de nuevo', () async {
    final cdn = _Cdn(audio, hangAfter: 8 * 1024);
    await cdn.start();
    addTearDown(cdn.close);
    final source = CachingStreamSource(
      cdn.url,
      file: File(p.join(dir.path, 'a.audio')),
      tag: 'a',
      networkTimeout: const Duration(milliseconds: 200),
    );
    final response = await source.request();
    await expectLater(collect(response.stream), throwsA(anything));

    await source.request(0, 2);

    expect(cdn.ranges, [null, null]);
    await source.cancel();
  });
}
