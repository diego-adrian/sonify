import '../../../core/result.dart';
import '../domain/catalog_failure.dart';
import '../domain/catalog_repository.dart';
import '../domain/genre.dart';
import '../domain/song.dart';

/// Catálogo de desarrollo con los datos del diseño de Figma, hasta conectar
/// Supabase. Las portadas viven en `assets/dev/covers/` y se borran entonces.
final class InMemoryCatalogRepository implements CatalogRepository {
  const InMemoryCatalogRepository();

  // Mismos ids que la semilla de `public.genres` en Supabase.
  static const _genres = [
    Genre(id: 1, slug: 'baladas', name: 'Baladas'),
    Genre(id: 2, slug: 'rancheras', name: 'Rancheras'),
    Genre(id: 3, slug: 'cumbia', name: 'Cumbia'),
    Genre(id: 4, slug: 'romanticos', name: 'Románticos'),
  ];

  static final _songs = [
    _song('1', 'Mariposa Traicionera', 'Maná', 3, 56, 4, 'mana'),
    _song('2', 'Vuela Vuela', 'Magneto', 4, 12, 1, 'magneto'),
    _song('3', 'Llorar llorar', 'Grupo Veneno', 2, 36, 3, 'grupo_veneno'),
    _song('4', 'Hay amor', '18 Kilates', 2, 30, 3, '18_kilates'),
    _song('5', 'Inocente', 'La Delio Valdez', 4, 56, 3, 'delio_valdez'),
    _song('6', 'Cochabambina', 'Kalamarca', 3, 56, 2, 'kalamarca'),
    _song('7', 'Nuestro amor', 'The Brothers', 3, 56, 4, 'the_brothers'),
    _song('8', 'Fuiste mala', 'Cumbia Kings', 5, 56, 3, 'cumbia_kings'),
  ];

  // Audio de prueba: grabaciones de Satie en dominio público / CC0 de
  // Wikimedia Commons (MP3 con soporte de Range). Se reparten entre las
  // canciones del diseño solo para poder probar el reproductor.
  static const _devAudio = [
    'https://upload.wikimedia.org/wikipedia/commons/transcoded/9/90/Erik_Satie_-_gymnopedies_-_la_1_ere._lent_et_douloureux.ogg/Erik_Satie_-_gymnopedies_-_la_1_ere._lent_et_douloureux.ogg.mp3',
    'https://upload.wikimedia.org/wikipedia/commons/transcoded/b/b7/Gymnopedie_No._1..ogg/Gymnopedie_No._1..ogg.mp3',
    'https://upload.wikimedia.org/wikipedia/commons/transcoded/3/3d/Satie_Gymnopedie_No_2_performed_by_Michael_Laucke.flac/Satie_Gymnopedie_No_2_performed_by_Michael_Laucke.flac.mp3',
    'https://upload.wikimedia.org/wikipedia/commons/transcoded/0/05/Debussy_Gymnopedie_1%2C_arrangement_of_Satie%E2%80%99s_Gymnopedie_3.wav/Debussy_Gymnopedie_1%2C_arrangement_of_Satie%E2%80%99s_Gymnopedie_3.wav.mp3',
  ];

  static Song _song(
    String id,
    String title,
    String artist,
    int minutes,
    int seconds,
    int genreId,
    String cover,
  ) => Song(
    id: id,
    title: title,
    artistName: artist,
    duration: Duration(minutes: minutes, seconds: seconds),
    genreId: genreId,
    cover: Uri.parse('asset:assets/dev/covers/$cover.jpg'),
    coverLarge: Uri.parse('asset:assets/dev/covers/large/$cover.jpg'),
    audio: Uri.parse(_devAudio[(int.parse(id) - 1) % _devAudio.length]),
  );

  @override
  Future<Result<List<Genre>, CatalogFailure>> getGenres() async =>
      const Ok(_genres);

  @override
  Future<Result<List<Song>, CatalogFailure>> getSongs({
    int? genreId,
    int limit = 30,
    int offset = 0,
  }) async {
    final songs = _songs
        .where((song) => genreId == null || song.genreId == genreId)
        .skip(offset)
        .take(limit)
        .toList(growable: false);
    return Ok(songs);
  }
}
