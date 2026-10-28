import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/lifecycle/app_lifecycle_provider.dart';
import '../domain/download_entry.dart';

final downloadsProvider = StreamProvider<List<DownloadEntry>>(
  (ref) => ref.watch(watchDownloadsProvider)(),
);

/// Estado por id de canción, para marcar las filas del catálogo.
final downloadStatesProvider = Provider<Map<String, DownloadState>>((ref) {
  final entries = ref.watch(downloadsProvider).value ?? const [];
  return {for (final entry in entries) entry.song.id: entry.state};
});

/// Avance en vivo; solo con la app en primer plano y la pantalla abierta.
final downloadProgressProvider =
    StreamProvider.autoDispose<Map<String, double>>((ref) {
      if (!ref.watch(appResumedProvider)) return const Stream.empty();
      return ref.watch(watchDownloadProgressProvider)();
    });

String formatBytes(int bytes) {
  const mb = 1024 * 1024;
  if (bytes >= 1024 * mb) {
    return '${(bytes / (1024 * mb)).toStringAsFixed(1).replaceAll('.', ',')} GB';
  }
  return '${(bytes / mb).ceil()} MB';
}
