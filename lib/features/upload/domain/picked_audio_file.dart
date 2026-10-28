final class PickedAudioFile {
  const PickedAudioFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final int sizeBytes;
}

final class PickedImageFile {
  const PickedImageFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.width,
    required this.height,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final int width;
  final int height;
}
