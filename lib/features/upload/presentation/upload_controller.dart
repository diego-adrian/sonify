import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/result.dart';
import '../domain/picked_audio_file.dart';
import '../domain/song_license.dart';
import '../domain/upload_failure.dart';

sealed class UploadState {
  const UploadState();
}

final class UploadIdle extends UploadState {
  const UploadIdle();
}

final class UploadInProgress extends UploadState {
  const UploadInProgress(this.progress);

  final double progress;
}

final class UploadSucceeded extends UploadState {
  const UploadSucceeded();
}

final class UploadFailed extends UploadState {
  const UploadFailed(this.failure);

  final UploadFailure failure;
}

/// No es autoDispose: la subida sigue aunque se salga de la pantalla.
final uploadControllerProvider =
    NotifierProvider<UploadController, UploadState>(UploadController.new);

class UploadController extends Notifier<UploadState> {
  @override
  UploadState build() => const UploadIdle();

  Future<PickedAudioFile?> pickFile() =>
      ref.read(audioFilePickerProvider).pick();

  Future<PickedImageFile?> pickCover() =>
      ref.read(coverImagePickerProvider).pick();

  Future<void> upload({
    required PickedAudioFile? file,
    required String title,
    required SongLicense license,
    required bool rightsAccepted,
    int? genreId,
    String? description,
    PickedImageFile? cover,
  }) async {
    if (state is UploadInProgress) return;
    state = const UploadInProgress(0);

    final result = await ref.read(uploadSongProvider)(
      file: file,
      title: title,
      license: license,
      rightsAccepted: rightsAccepted,
      genreId: genreId,
      description: description,
      cover: cover,
      onProgress: (progress) => state = UploadInProgress(progress),
    );

    state = switch (result) {
      Ok() => const UploadSucceeded(),
      Err(:final error) => UploadFailed(error),
    };
  }

  void reset() => state = const UploadIdle();
}
