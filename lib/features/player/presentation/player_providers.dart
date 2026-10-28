import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/lifecycle/app_lifecycle_provider.dart';
import '../domain/playback_snapshot.dart';

final playbackProvider = StreamProvider<PlaybackSnapshot>(
  (ref) => ref.watch(watchPlaybackProvider)(),
);

/// Solo se escucha con la app en primer plano (ahorro de batería).
final positionProvider = StreamProvider.autoDispose<Duration>((ref) {
  if (!ref.watch(appResumedProvider)) return const Stream.empty();
  return ref.watch(watchPositionProvider)();
});
