import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../domain/upload_ports.dart';

/// `file_picker` copia cada archivo elegido a la carpeta temporal y no los
/// borra nunca. En iOS, limpiar vacía toda esa carpeta.
final class FilePickerTempFiles implements UploadTempFiles {
  const FilePickerTempFiles();

  @override
  Future<void> clear() async {
    try {
      await FilePicker.clearTemporaryFiles();
    } on Exception catch (error) {
      // Quedan para la próxima: no afecta a la subida.
      debugPrint('Subida: no se pudo limpiar temporales ($error)');
    }
  }
}
