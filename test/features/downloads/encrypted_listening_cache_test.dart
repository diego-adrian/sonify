import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/downloads/infrastructure/encrypted_listening_cache.dart';
import 'package:sonify/features/downloads/infrastructure/listening_cache_database.dart';

const _audioBytes = 1000;

void main() {
  late Directory root;
  late EncryptedListeningCache cache;
  late DateTime now;

  EncryptedListeningCache open({int maxBytes = 1 << 20}) =>
      EncryptedListeningCache(
        root: () async => root.path,
        key: () async => Uint8List.fromList(List.generate(32, (i) => i)),
        openDatabase: (_) => ListeningCacheDatabase(NativeDatabase.memory()),
        maxBytes: maxBytes,
        clock: () => now,
      );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('listening_cache_test');
    now = DateTime(2026, 10, 28, 12);
    cache = open();
  });

  tearDown(() async {
    await cache.dispose();
    await root.delete(recursive: true);
  });

  Uint8List audioOf(String id) => Uint8List.fromList(
    List.generate(_audioBytes, (i) => (i + id.hashCode) % 256),
  );

  Song song(String id, {String? sha256}) => Song(
    id: id,
    title: 'Canción $id',
    artistName: 'Artista',
    duration: const Duration(minutes: 3),
    audio: Uri.parse('https://cdn/audio/$id/128.m4a?sig=x'),
    audioSha256: sha256,
  );

  /// Lo que deja el reproductor al terminar de bajar la canción.
  Future<String> streamed(String id) async {
    final path = (await cache.tempPathFor(id))!;
    await File(path).writeAsBytes(audioOf(id));
    await File('$path.mime').writeAsString('audio/mp4');
    return path;
  }

  Future<Uint8List> played(String id) async {
    final audio = (await cache.find(id))!;
    final chunks = await audio.read(0, audio.length).toList();
    return Uint8List.fromList([for (final c in chunks) ...c]);
  }

  test('escuchada lo suficiente se guarda cifrada y suena igual', () async {
    final temp = await streamed('a');

    await cache.finished(song('a'), listenedEnough: true, stillCurrent: false);

    expect(await played('a'), audioOf('a'));
    expect(await File(temp).exists(), isFalse, reason: 'sin audio en claro');
    final encrypted = await File(p.join(root.path, 'audio', 'a.enc'))
        .readAsBytes();
    expect(encrypted.sublist(16), isNot(audioOf('a')));
    expect((await cache.watchSongs().first).single.id, 'a');
  });

  test('saltada antes de tiempo no se guarda y se borra el temporal', () async {
    final temp = await streamed('a');

    await cache.finished(song('a'), listenedEnough: false, stillCurrent: false);

    expect(await cache.find('a'), isNull);
    expect(await File(temp).exists(), isFalse);
  });

  test('si sigue sonando (repetir una) conserva el temporal', () async {
    final temp = await streamed('a');

    await cache.finished(song('a'), listenedEnough: true, stillCurrent: true);

    expect(await cache.find('a'), isNotNull);
    expect(await File(temp).exists(), isTrue);
  });

  test('si el SHA-256 no coincide no se guarda', () async {
    await streamed('a');

    await cache.finished(
      song('a', sha256: 'f' * 64),
      listenedEnough: true,
      stillCurrent: false,
    );

    expect(await cache.find('a'), isNull);
  });

  test('con el SHA-256 correcto se guarda', () async {
    await streamed('a');

    await cache.finished(
      song('a', sha256: sha256.convert(audioOf('a')).toString()),
      listenedEnough: true,
      stillCurrent: false,
    );

    expect(await cache.find('a'), isNotNull);
  });

  test('al llenarse borra la que hace más tiempo que no suena', () async {
    await cache.dispose();
    // Caben 3 (cada una ocupa 1000 bytes + 16 de IV).
    cache = open(maxBytes: 3 * (_audioBytes + 16));

    for (final id in ['a', 'b', 'c']) {
      await streamed(id);
      await cache.finished(song(id), listenedEnough: true, stillCurrent: false);
      now = now.add(const Duration(minutes: 1));
    }
    // Se vuelve a escuchar "a": ahora la más vieja es "b".
    await cache.finished(song('a'), listenedEnough: true, stillCurrent: false);
    now = now.add(const Duration(minutes: 1));

    await streamed('d');
    await cache.finished(song('d'), listenedEnough: true, stillCurrent: false);

    final ids = {for (final s in await cache.watchSongs().first) s.id};
    expect(ids, {'a', 'c', 'd'});
    expect(await File(p.join(root.path, 'audio', 'b.enc')).exists(), isFalse);
  });

  test('nunca borra la cola actual al liberar espacio', () async {
    await cache.dispose();
    cache = open(maxBytes: 2 * (_audioBytes + 16));

    for (final id in ['a', 'b']) {
      await streamed(id);
      await cache.finished(song(id), listenedEnough: true, stillCurrent: false);
      now = now.add(const Duration(minutes: 1));
    }
    cache.protect({'a', 'c'});

    await streamed('c');
    await cache.finished(song('c'), listenedEnough: true, stillCurrent: false);

    final ids = {for (final s in await cache.watchSongs().first) s.id};
    expect(ids, {'a', 'c'});
  });

  test('al abrir borra los temporales que quedaron en claro', () async {
    final temp = await streamed('a');
    await cache.dispose();

    cache = open();
    await cache.tempPathFor('x');

    expect(await File(temp).exists(), isFalse);
  });

  test('clearTemporary borra lo que se estaba bajando', () async {
    final temp = await streamed('a');

    await cache.clearTemporary();

    expect(await File(temp).exists(), isFalse);
  });
}
