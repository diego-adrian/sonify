import '../../../core/result.dart';
import '../domain/picked_audio_file.dart';
import '../domain/song_license.dart';
import '../domain/upload_failure.dart';
import '../domain/upload_ports.dart';
import '../domain/upload_request.dart';
import '../domain/upload_rules.dart';

final class UploadSong {
  const UploadSong(this._repository, this._tempFiles);

  final UploadRepository _repository;
  final UploadTempFiles _tempFiles;

  Future<Result<String, UploadFailure>> call({
    required PickedAudioFile? file,
    required String title,
    required SongLicense license,
    required bool rightsAccepted,
    int? genreId,
    String? description,
    PickedImageFile? cover,
    required void Function(double progress) onProgress,
  }) async {
    if (file == null) return const Err(UploadFailure.noFile);
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.length > UploadRules.maxTitleLength) {
      return const Err(UploadFailure.invalidTitle);
    }
    final about = description?.trim() ?? '';
    if (about.length > UploadRules.maxDescriptionLength) {
      return const Err(UploadFailure.descriptionTooLong);
    }
    if (!rightsAccepted) return const Err(UploadFailure.rightsNotAccepted);
    final contentType = UploadRules.contentTypeFor(file.name);
    if (contentType == null) return const Err(UploadFailure.unsupportedType);
    if (file.sizeBytes > UploadRules.maxOriginalBytes) {
      return const Err(UploadFailure.tooLarge);
    }

    String? coverContentType;
    if (cover != null) {
      coverContentType = UploadRules.coverContentTypeFor(cover.name);
      if (coverContentType == null) {
        return const Err(UploadFailure.coverUnsupported);
      }
      if (cover.sizeBytes > UploadRules.maxCoverBytes) {
        return const Err(UploadFailure.coverTooLarge);
      }
    }

    final result = await _repository.upload(
      UploadRequest(
        file: file,
        contentType: contentType,
        title: trimmed,
        license: license,
        genreId: genreId,
        description: about.isEmpty ? null : about,
        cover: cover,
        coverContentType: coverContentType,
      ),
      onProgress: onProgress,
    );
    if (result is Ok) await _tempFiles.clear();
    return result;
  }
}
