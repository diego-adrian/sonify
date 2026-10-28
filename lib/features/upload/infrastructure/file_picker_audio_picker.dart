import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../domain/picked_audio_file.dart';
import '../domain/upload_ports.dart';
import '../domain/upload_rules.dart';

final class FilePickerAudioPicker implements AudioFilePicker {
  const FilePickerAudioPicker();

  @override
  Future<PickedAudioFile?> pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: UploadRules.extensions,
    );
    if (files.isEmpty) return null;
    final file = files.first;
    final path = file.path;
    if (path == null) return null;
    return PickedAudioFile(
      path: path,
      name: file.name,
      sizeBytes: file.lengthSync() ?? await File(path).length(),
    );
  }
}
