import '../../../core/result.dart';
import 'picked_audio_file.dart';
import 'upload_failure.dart';
import 'upload_request.dart';

/// Elegir un archivo de audio del dispositivo.
abstract interface class AudioFilePicker {
  /// `null` si el usuario cancela.
  Future<PickedAudioFile?> pick();
}

/// Elegir la portada (imagen) del dispositivo.
abstract interface class CoverImagePicker {
  /// `null` si el usuario cancela.
  Future<PickedImageFile?> pick();
}

/// Subida de una canción: el backend registra la canción a nombre del
/// usuario y el archivo va directo al almacenamiento.
abstract interface class UploadRepository {
  /// Devuelve el id de la canción creada.
  Future<Result<String, UploadFailure>> upload(
    UploadRequest request, {
    required void Function(double progress) onProgress,
  });
}
