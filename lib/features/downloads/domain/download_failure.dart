sealed class DownloadFailure {
  const DownloadFailure();
}

/// Se comprueba antes de encolar un lote, para no fallar a mitad.
final class NotEnoughSpace extends DownloadFailure {
  const NotEnoughSpace({
    required this.requiredBytes,
    required this.availableBytes,
  });

  final int requiredBytes;
  final int availableBytes;
}
