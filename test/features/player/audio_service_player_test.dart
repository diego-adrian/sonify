import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/player/domain/local_audio.dart';
import 'package:sonify/features/player/infrastructure/audio_service_player.dart';
import 'package:sonify/features/player/infrastructure/sonify_audio_handler.dart';

import '../../helpers/fake_just_audio_platform.dart';

/// Caché que deja los temporales en [dir] y anota qué se le pide.
final class _RecordingCache implements ListeningCache {
  _RecordingCache(this.dir);

  static const _none = NoListeningCache();

  final Directory dir;
  final discarded = <String>[];
  final finishedIds = <String>[];
  final listened = <String, bool>{};

  @override
  Future<LocalAudio?> find(String songId) => _none.find(songId);

  @override
  Stream<List<Song>> watchSongs() => _none.watchSongs();

  @override
  void protect(Set<String> songIds) {}

  @override
  Future<void> clearTemporary() async {}

  @override
  Future<int> usedBytes() async => 0;

  @override
  Future<void> clear() async {}

  @override
  Future<String?> tempPathFor(String songId) async => '${dir.path}/$songId';

  @override
  Future<void> discardTemporary(String songId) async => discarded.add(songId);

  @override
  Future<void> finished(
    Song song, {
    required bool listenedEnough,
    required bool stillCurrent,
  }) async {
    finishedIds.add(song.id);
    listened[song.id] = listenedEnough;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioSession = MethodChannel('com.ryanheise.audio_session');

  late FakeJustAudioPlatform platform;
  late SonifyAudioHandler handler;
  late AudioServicePlayer player;

  final now = DateTime.now().toUtc();
  int unix(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;
  final yesterday = unix(now.subtract(const Duration(days: 1)));
  final tomorrow = unix(now.add(const Duration(days: 1)));

  Song song(String id, int exp) => Song(
    id: id,
    title: id,
    artistName: 'Artista',
    duration: const Duration(minutes: 3),
    audio: Uri.parse('https://cdn.test/audio/$id/128.m4a?exp=$exp&sig=s'),
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioSession, (_) async => null);
    JustAudioPlatform.instance = platform = FakeJustAudioPlatform(
      seekLatency: Duration.zero,
    );
    handler = SonifyAudioHandler();
    player = AudioServicePlayer(
      handler,
      () => const EmptyLocalAudioLibrary(),
      () => const NoListeningCache(),
    );
  });

  tearDown(() async {
    await player.dispose();
    await handler.player.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioSession, null);
  });

  test('al día siguiente, "siguiente" recarga la cola con las URLs que trajo '
      'el catálogo', () async {
    // La cola se armó ayer: hoy sus URLs ya vencieron.
    await player.playQueue([
      song('a', yesterday),
      song('b', yesterday),
    ], startIndex: 0);
    await player.pause();
    expect(platform.player!.loadedUrls, hasLength(1));

    // Al volver a la app llega el catálogo con URLs nuevas.
    player.updateSongs([song('b', tomorrow), song('otra', tomorrow)]);
    await player.skipToNext();

    final last = platform.player!.loadedUrls.last;
    expect(platform.player!.loadedUrls, hasLength(2));
    expect(last[1], contains('exp=$tomorrow'));
    expect(platform.player!.index, 1);
  });

  test('con URLs vigentes no recarga nada', () async {
    await player.playQueue([
      song('a', tomorrow),
      song('b', tomorrow),
    ], startIndex: 0);
    await player.pause();

    player.updateSongs([song('b', tomorrow + 86400)]);
    await player.skipToNext();

    expect(platform.player!.loadedUrls, hasLength(1));
    expect(platform.player!.index, 1);
  });

  test('una URL más vieja no reemplaza a la de la cola', () async {
    await player.playQueue([
      song('a', yesterday),
      song('b', yesterday),
    ], startIndex: 0);
    await player.pause();

    player.updateSongs([song('b', yesterday - 86400)]);
    await player.skipToNext();

    // No hay nada mejor con qué recargar: sigue con lo que tenía.
    expect(platform.player!.loadedUrls, hasLength(1));
  });

  group('canción saltada ya bajada', () {
    late Directory dir;
    late HttpServer cdn;
    late _RecordingCache cache;
    late AudioServicePlayer streaming;

    setUp(() async {
      // Sin esto, los tests responden 400 a toda petición HTTP.
      HttpOverrides.global = null;
      dir = await Directory.systemTemp.createTemp('saltada');
      cdn = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      cdn.listen((request) async {
        request.response.headers.contentLength = 2048;
        request.response.add(Uint8List(2048));
        await request.response.close();
      });
      cache = _RecordingCache(dir);
      streaming = AudioServicePlayer(
        handler,
        () => const EmptyLocalAudioLibrary(),
        () => cache,
      );
    });

    tearDown(() async {
      await streaming.dispose();
      await cdn.close(force: true);
      await dir.delete(recursive: true);
    });

    Song remote(String id) => Song(
      id: id,
      title: id,
      artistName: 'Artista',
      duration: const Duration(minutes: 3),
      audio: Uri.parse('http://127.0.0.1:${cdn.port}/audio/$id/128.m4a'),
    );

    /// El reproductor nativo precarga la canción [index] de la cola.
    Future<void> preload(int index) async {
      final url = Uri.parse(platform.player!.loadedUrls.last[index]);
      final client = HttpClient();
      final request = await client.getUrl(url);
      await (await request.close()).drain<void>();
      client.close();
      while (!await File('${dir.path}/b').exists()) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }

    test('saltar a otra borra el temporal en claro de la que quedó', () async {
      await streaming.playQueue([
        remote('a'),
        remote('b'),
        remote('c'),
        remote('d'),
      ], startIndex: 0);
      await preload(1);

      await streaming.skipToSong('d');
      await Future<void>.delayed(Duration.zero);

      expect(cache.discarded, ['b']);
      // La de antes la atiende `finished`, que puede guardarla en la caché.
      expect(cache.finishedIds, contains('a'));
    });

    test('saltar tras escucharla 30 s la guarda en la caché', () async {
      await streaming.playQueue([remote('a'), remote('b')], startIndex: 0);
      await streaming.seek(const Duration(seconds: 40));

      await streaming.skipToNext();

      expect(cache.listened['a'], isTrue);
    });

    test('saltar sin escucharla 30 s no la guarda', () async {
      await streaming.playQueue([remote('a'), remote('b')], startIndex: 0);

      await streaming.skipToNext();

      expect(cache.listened['a'], isFalse);
    });

    test('"siguiente" en la última no da por terminada la que suena', () async {
      await streaming.playQueue([remote('a'), remote('b')], startIndex: 1);

      await streaming.skipToNext();

      expect(cache.finishedIds, isEmpty);
    });
  });
}
