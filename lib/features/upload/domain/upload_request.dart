import 'picked_audio_file.dart';
import 'song_license.dart';

final class UploadRequest {
  const UploadRequest({
    required this.file,
    required this.contentType,
    required this.title,
    required this.license,
    this.genreId,
    this.description,
    this.cover,
    this.coverContentType,
  });

  final PickedAudioFile file;
  final String contentType;
  final String title;
  final SongLicense license;
  final int? genreId;
  final String? description;
  final PickedImageFile? cover;
  final String? coverContentType;
}
