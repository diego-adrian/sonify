import '../../catalog/domain/song.dart';

enum DownloadState {
  /// En cola o descargando (puede estar esperando Wi-Fi).
  queued,

  /// Cifrada en el dispositivo y lista para sonar sin red.
  done,
  failed,
}

final class DownloadEntry {
  const DownloadEntry({
    required this.song,
    required this.state,
    this.sizeBytes,
  });

  final Song song;
  final DownloadState state;

  /// Espacio que ocupa en disco cuando está lista.
  final int? sizeBytes;
}
