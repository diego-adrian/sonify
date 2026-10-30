import '../../../core/network/media_url.dart';
import '../../catalog/domain/song.dart';
import 'download_ports.dart';

/// [songs] con la URL de audio renovada en las que ya venció. Si no se
/// consigue una nueva (sin red), quedan como estaban.
Future<List<Song>> withFreshUrls(
  List<Song> songs,
  SongRefresher refresher, {
  DateTime? now,
}) async {
  final expired = [
    for (final song in songs)
      if (isMediaUrlExpired(song.audio, now: now)) song.id,
  ];
  if (expired.isEmpty) return songs;
  final fresh = {
    for (final song in await refresher.fresh(expired))
      if (!isMediaUrlExpired(song.audio, now: now)) song.id: song,
  };
  return [for (final song in songs) fresh[song.id] ?? song];
}
