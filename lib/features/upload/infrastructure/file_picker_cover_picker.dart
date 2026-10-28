import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';

import '../domain/picked_audio_file.dart';
import '../domain/upload_ports.dart';
import '../domain/upload_rules.dart';

final class FilePickerCoverPicker implements CoverImagePicker {
  const FilePickerCoverPicker();

  @override
  Future<PickedImageFile?> pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: UploadRules.coverExtensions,
    );
    if (files.isEmpty) return null;
    final file = files.first;
    final path = file.path;
    if (path == null) return null;

    // Solo lee la cabecera de la imagen para saber sus dimensiones, sin
    // decodificarla entera (una portada de 3000×3000 ocuparía ~36 MB en RAM).
    final buffer = await ui.ImmutableBuffer.fromFilePath(path);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final picked = PickedImageFile(
      path: path,
      name: file.name,
      sizeBytes: file.lengthSync() ?? await File(path).length(),
      width: descriptor.width,
      height: descriptor.height,
    );
    descriptor.dispose();
    buffer.dispose();
    return picked;
  }
}
