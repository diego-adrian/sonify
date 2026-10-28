import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/features/downloads/infrastructure/aes_ctr.dart';

Uint8List _hex(String value) => Uint8List.fromList([
  for (var i = 0; i < value.length; i += 2)
    int.parse(value.substring(i, i + 2), radix: 16),
]);

String _toHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  final key = _hex(
    '603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4',
  );

  test('vector NIST SP 800-38A F.5.5 (CTR-AES256)', () {
    final data = _hex(
      '6bc1bee22e409f96e93d7e117393172a'
      'ae2d8a571e03ac9c9eb76fac45af8e51'
      '30c81c46a35ce411e5fbc1191a0a52ef'
      'f69f2445df4f9b17ad2b417be66c3710',
    );
    AesCtr(key, _hex('f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff')).apply(data, 0);
    expect(
      _toHex(data),
      '601ec313775789a5b7a7f504bbf3d228'
      'f443e3ca4d62b59aca84e990cacaf5c5'
      '2b0930daa23de94ce87017ba2d84988d'
      'dfc9c58db67aada613c2dd08457941a6',
    );
  });

  test('el contador acarrea los 128 bits como OpenSSL', () {
    // openssl enc -aes-256-ctr -K <key> -iv 0000000000000000ffffffffffffffff
    final data = Uint8List(40);
    AesCtr(key, _hex('0000000000000000ffffffffffffffff')).apply(data, 0);
    expect(
      _toHex(data),
      '289e23e13ec8c34291f27c4ccf3eaa29579be1a0d892238805feb810a4a10aaa'
      '51ffb50816f5e9fa',
    );
  });

  test('descifrar desde cualquier posición da lo mismo que de corrido', () {
    final random = Random(7);
    final plain = Uint8List.fromList(
      List.generate(5000, (_) => random.nextInt(256)),
    );
    final iv = Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );
    final cipher = Uint8List.fromList(plain);
    AesCtr(key, iv).apply(cipher, 0);

    for (final (start, length) in [
      (0, 1),
      (15, 2),
      (16, 16),
      (1001, 777),
      (4999, 1),
    ]) {
      final part = Uint8List.fromList(cipher.sublist(start, start + length));
      AesCtr(key, iv).apply(part, start);
      expect(part, plain.sublist(start, start + length), reason: '$start');
    }
  });
}
