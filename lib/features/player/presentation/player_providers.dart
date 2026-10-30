import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/lifecycle/app_lifecycle_provider.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../library/presentation/library_providers.dart';
import '../domain/playback_snapshot.dart';

final playbackProvider = StreamProvider<PlaybackSnapshot>(
  (ref) => ref.watch(watchPlaybackProvider)(),
);

/// Solo se escucha con la app en primer plano (ahorro de batería).
final positionProvider = StreamProvider.autoDispose<Duration>((ref) {
  if (!ref.watch(appResumedProvider)) return const Stream.empty();
  return ref.watch(watchPositionProvider)();
});

/// Las URLs firmadas vencen en 24–48 h: cada vez que llegan el catálogo o la
/// biblioteca (al volver a la app tras 10 min, al recuperar la red), la cola
/// toma sus datos nuevos. Lo mantiene activo `MainShell`.
final queueFreshnessProvider = Provider<void>((ref) {
  final update = ref.read(updateQueueSongsProvider);
  ref.listen(catalogSongsProvider, (_, songs) {
    if (songs != null) update(songs);
  });
  ref.listen(libraryProvider, (_, library) {
    if (library.value case final library?) update(library.songs);
  });
});
