import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/domain/song.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../player/presentation/player_providers.dart';

/// Canción elegida mientras no hay nada cargado en el reproductor.
final currentSongIdProvider = NotifierProvider<CurrentSongId, String?>(
  CurrentSongId.new,
);

class CurrentSongId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String songId) => state = songId;
}

/// Canción mostrada arriba: la que suena o, si no hay cola, la elegida.
final currentSongProvider = Provider<Song?>((ref) {
  final playing = ref.watch(playbackProvider).value?.current;
  if (playing != null) return playing;
  final songs = ref.watch(songsProvider).value;
  if (songs == null || songs.isEmpty) return null;
  final id = ref.watch(currentSongIdProvider);
  return songs.firstWhere((song) => song.id == id, orElse: () => songs.first);
});

enum HomeTab { similar, upNext }

final homeTabProvider = NotifierProvider<HomeTabNotifier, HomeTab>(
  HomeTabNotifier.new,
);

class HomeTabNotifier extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.similar;

  void select(HomeTab tab) => state = tab;
}

/// Mismo género que la canción actual.
final similarSongsProvider = Provider<List<Song>>((ref) {
  final songs = ref.watch(songsProvider).value ?? const [];
  final current = ref.watch(currentSongProvider);
  if (current == null) return const [];
  return songs
      .where((s) => s.id != current.id && s.genreId == current.genreId)
      .toList(growable: false);
});

/// La cola real del reproductor o, si no hay, lo que sigue en el catálogo.
final upNextSongsProvider = Provider<List<Song>>((ref) {
  final playback = ref.watch(playbackProvider).value;
  if (playback != null && playback.hasQueue) return playback.upNext;
  final songs = ref.watch(songsProvider).value ?? const [];
  final current = ref.watch(currentSongProvider);
  if (current == null) return const [];
  final index = songs.indexWhere((s) => s.id == current.id);
  return songs.sublist(index + 1);
});

/// Anterior / siguiente en el catálogo (con vuelta al inicio).
Song? adjacentSong(List<Song> songs, Song current, int step) {
  if (songs.isEmpty) return null;
  final index = songs.indexWhere((s) => s.id == current.id);
  return songs[(index + step) % songs.length];
}
