import 'dart:typed_data';

import 'package:pointycastle/api.dart' show KeyParameter;
import 'package:pointycastle/block/aes.dart';

/// AES-256 en modo CTR con contador de 128 bits big-endian (como OpenSSL y
/// NIST SP 800-38A). Permite cifrar o descifrar desde cualquier posición, que
/// es lo que necesita el reproductor para hacer seek sin leer el archivo
/// entero. Cifrar y descifrar son la misma operación.
final class AesCtr {
  AesCtr(Uint8List key, Uint8List iv)
    : assert(key.length == 32),
      assert(iv.length == 16),
      _iv = Uint8List.fromList(iv) {
    _aes.init(true, KeyParameter(key));
  }

  final _aes = AESEngine();
  final Uint8List _iv;
  final _counter = Uint8List(16);
  final _keystream = Uint8List(16);

  /// Aplica el flujo de clave a [data] en el sitio; [data] empieza en el byte
  /// [offset] del mensaje.
  void apply(Uint8List data, int offset) {
    _setCounter(offset ~/ 16);
    var skip = offset % 16;
    var i = 0;
    while (i < data.length) {
      _aes.processBlock(_counter, 0, _keystream, 0);
      final end = i + 16 - skip < data.length ? i + 16 - skip : data.length;
      for (var k = skip; i < end; k++, i++) {
        data[i] ^= _keystream[k];
      }
      skip = 0;
      _increment();
    }
  }

  /// contador = IV + [block] (suma de 128 bits).
  void _setCounter(int block) {
    var carry = block;
    for (var j = 15; j >= 0; j--) {
      final sum = _iv[j] + (carry & 0xff);
      _counter[j] = sum & 0xff;
      carry = (carry >> 8) + (sum >> 8);
    }
  }

  void _increment() {
    for (var j = 15; j >= 0; j--) {
      final value = (_counter[j] + 1) & 0xff;
      _counter[j] = value;
      if (value != 0) return;
    }
  }
}
