import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/features/downloads/infrastructure/encrypted_file.dart';

void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('sonify'));
  tearDown(() => dir.delete(recursive: true));

  test('cifra por bloques, verifica SHA-256 y lee rangos en claro', () async {
    final random = Random(1);
    // Más de un bloque de 256 KB y sin múltiplo de 16.
    final plain = Uint8List.fromList(
      List.generate(600 * 1024 + 5, (_) => random.nextInt(256)),
    );
    final source = File('${dir.path}/song.part')..writeAsBytesSync(plain);
    final target = '${dir.path}/song.enc';
    final key = Uint8List.fromList(List.generate(32, (i) => i));

    final info = await encryptFile(
      source: source.path,
      target: target,
      key: key,
    );

    expect(info.plainLength, plain.length);
    expect(info.sha256, sha256.convert(plain).toString());
    expect(source.existsSync(), isFalse, reason: 'no queda el audio en claro');
    expect(plainLengthOf(target), plain.length);
    final stored = File(target).readAsBytesSync();
    expect(stored.length, plain.length + ivLength);
    expect(
      stored.sublist(ivLength, ivLength + 64),
      isNot(plain.sublist(0, 64)),
    );

    final whole = await decryptedRange(
      path: target,
      key: key,
      start: 0,
      end: plain.length,
    ).expand((chunk) => chunk).toList();
    expect(whole, plain);

    final middle = await readDecrypted(
      path: target,
      key: key,
      start: 300001,
      length: 1000,
    );
    expect(middle, plain.sublist(300001, 301001));
  });
}
