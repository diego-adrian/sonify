import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'aes_ctr.dart';

// Formato de una descarga: [IV aleatorio de 16 bytes][audio cifrado AES-CTR].
// Todo el trabajo de CPU corre en isolates, nunca en el hilo de la UI.

const ivLength = 16;
const _chunk = 256 * 1024;

typedef EncryptedFileInfo = ({int plainLength, String sha256});

/// Cifra [source] en [target] por bloques (sin cargarlo entero en RAM),
/// calcula su SHA-256 en la misma pasada y borra [source].
Future<EncryptedFileInfo> encryptFile({
  required String source,
  required String target,
  required Uint8List key,
}) {
  final iv = _randomIv();
  return Isolate.run(() => _encrypt(source, target, key, iv));
}

/// Lee [length] bytes en claro desde la posición [start] del audio.
Future<Uint8List> readDecrypted({
  required String path,
  required Uint8List key,
  required int start,
  required int length,
}) => Isolate.run(() => _read(path, key, start, length));

/// Tamaño del audio en claro.
int plainLengthOf(String path) => File(path).lengthSync() - ivLength;

/// Bloques en claro de [start] a [end], de a uno por isolate: cada uno
/// descifra unos 256 KB y lo devuelve sin copiar (`Isolate.exit`).
Stream<List<int>> decryptedRange({
  required String path,
  required Uint8List key,
  required int start,
  required int end,
}) async* {
  var position = start;
  while (position < end) {
    final length = end - position < _chunk ? end - position : _chunk;
    yield await readDecrypted(
      path: path,
      key: key,
      start: position,
      length: length,
    );
    position += length;
  }
}

Uint8List _randomIv() {
  final random = Random.secure();
  return Uint8List.fromList(
    List.generate(ivLength, (_) => random.nextInt(256)),
  );
}

EncryptedFileInfo _encrypt(
  String source,
  String target,
  Uint8List key,
  Uint8List iv,
) {
  final partial = File('$target.part');
  final input = File(source).openSync();
  final output = partial.openSync(mode: FileMode.write);
  final digest = _DigestSink();
  final hasher = sha256.startChunkedConversion(digest);
  final cipher = AesCtr(key, iv);
  final buffer = Uint8List(_chunk);
  var offset = 0;
  try {
    output.writeFromSync(iv);
    while (true) {
      final read = input.readIntoSync(buffer);
      if (read == 0) break;
      final block = Uint8List.sublistView(buffer, 0, read);
      hasher.add(block);
      cipher.apply(block, offset);
      output.writeFromSync(block);
      offset += read;
    }
    output.flushSync();
  } finally {
    input.closeSync();
    output.closeSync();
  }
  hasher.close();
  partial.renameSync(target);
  File(source).deleteSync();
  return (plainLength: offset, sha256: digest.value.toString());
}

Uint8List _read(String path, Uint8List key, int start, int length) {
  final file = File(path).openSync();
  try {
    final iv = Uint8List(ivLength);
    file.readIntoSync(iv);
    file.setPositionSync(ivLength + start);
    final data = Uint8List(length);
    final read = file.readIntoSync(data);
    final block = read == length ? data : Uint8List.sublistView(data, 0, read);
    AesCtr(key, iv).apply(block, start);
    return block;
  } finally {
    file.closeSync();
  }
}

final class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
