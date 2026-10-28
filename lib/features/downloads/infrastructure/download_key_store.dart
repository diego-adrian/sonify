import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Clave AES-256 de las descargas, por usuario y dispositivo, en Keychain /
/// Keystore. Nunca en disco plano ni en la base local.
///
/// [purpose] separa claves: la caché de lo escuchado usa la suya, así
/// "Borrar todo" en Descargas (que borra su clave) no la deja ilegible.
final class DownloadKeyStore {
  DownloadKeyStore(
    String userId, {
    String purpose = 'downloads',
    FlutterSecureStorage? storage,
  }) : _name = 'sonify.$purpose.key.v1.$userId',
       _storage =
           storage ??
           const FlutterSecureStorage(
             // Solo este dispositivo (sin iCloud Keychain) y legible con el
             // teléfono bloqueado tras el primer desbloqueo: así suena en
             // segundo plano y desde CarPlay.
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
           );

  final String _name;
  final FlutterSecureStorage _storage;
  Future<Uint8List>? _key;

  Future<Uint8List> key() => _key ??= _loadOrCreate();

  Future<void> delete() async {
    _key = null;
    await _storage.delete(key: _name);
  }

  Future<Uint8List> _loadOrCreate() async {
    final stored = await _storage.read(key: _name);
    if (stored != null) return base64Decode(stored);
    final random = Random.secure();
    final key = Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
    await _storage.write(key: _name, value: base64Encode(key));
    return key;
  }
}
