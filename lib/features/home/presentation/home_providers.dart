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
  final songs = ref.watch(catalogSongsProvider);
  if (songs == null || songs.isEmpty) return null;
  // Sin red se prefiere una que pueda sonar (descargada).
  final playable = ref.watch(playableSongsProvider);
  final id = ref.watch(currentSongIdProvider);
  Song? byId(List<Song> list) =>
      list.where((song) => song.id == id).firstOrNull;
  return byId(playable) ?? playable.firstOrNull ?? byId(songs) ?? songs.first;
});

/// Anterior / siguiente en el catálogo (con vuelta al inicio).
Song? adjacentSong(List<Song> songs, Song current, int step) {
  if (songs.isEmpty) return null;
  final index = songs.indexWhere((s) => s.id == current.id);
  return songs[(index + step) % songs.length];
}
