import 'package:flutter/services.dart';

import '../domain/download_ports.dart';

/// Canal nativo propio (AppDelegate.swift / MainActivity.kt): espacio libre
/// y exclusión de respaldos en iOS. En Android los respaldos se excluyen en
/// el manifiesto (`data_extraction_rules.xml`).
final class DeviceStorage implements StorageSpace {
  DeviceStorage(this._path);

  static const _channel = MethodChannel('app.sonify.sonify/storage');

  /// Carpeta de referencia (el volumen donde se guardan las descargas).
  final Future<String> Function() _path;

  @override
  Future<int?> freeBytes() async {
    try {
      return await _channel.invokeMethod<int>('freeBytes', {
        'path': await _path(),
      });
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Marca [path] para que no vaya a iCloud (`isExcludedFromBackup`).
  static Future<void> excludeFromBackup(String path) async {
    try {
      await _channel.invokeMethod<void>('excludeFromBackup', {'path': path});
    } on MissingPluginException {
      // Plataformas sin canal (tests de escritorio).
    }
  }
}
