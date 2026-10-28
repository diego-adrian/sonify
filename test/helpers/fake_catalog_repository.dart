import 'package:sonify/core/result.dart';
import 'package:sonify/features/catalog/domain/catalog_failure.dart';
import 'package:sonify/features/catalog/domain/catalog_page.dart';
import 'package:sonify/features/catalog/domain/catalog_repository.dart';
import 'package:sonify/features/catalog/domain/genre.dart';
import 'package:sonify/features/catalog/domain/song.dart';

/// Catálogo de prueba con los datos del diseño de Figma.
final class FakeCatalogRepository implements CatalogRepository {
  const FakeCatalogRepository();

  // Mismos ids que la semilla de `public.genres` en Supabase.
  static const _genres = [
    Genre(id: 1, slug: 'baladas', name: 'Baladas'),
    Genre(id: 2, slug: 'rancheras', name: 'Rancheras'),
    Genre(id: 3, slug: 'cumbia', name: 'Cumbia'),
    Genre(id: 4, slug: 'romanticos', name: 'Románticos'),
  ];

  static final _songs = [
    _song('1', 'Mariposa Traicionera', 'Maná', 3, 56, 4),
    _song('2', 'Vuela Vuela', 'Magneto', 4, 12, 1),
    _song('3', 'Llorar llorar', 'Grupo Veneno', 2, 36, 3),
    _song('4', 'Hay amor', '18 Kilates', 2, 30, 3),
    _song('5', 'Inocente', 'La Delio Valdez', 4, 56, 3),
    _song('6', 'Cochabambina', 'Kalamarca', 3, 56, 2),
    _song('7', 'Nuestro amor', 'The Brothers', 3, 56, 4),
    _song('8', 'Fuiste mala', 'Cumbia Kings', 5, 56, 3),
  ];

  // Grabaciones de Satie en dominio público / CC0 de Wikimedia Commons.
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
  ) => Song(
    id: id,
    title: title,
    artistName: artist,
    duration: Duration(minutes: minutes, seconds: seconds),
    genreId: genreId,
    audio: Uri.parse(_devAudio[(int.parse(id) - 1) % _devAudio.length]),
  );

  @override
  Future<Result<List<Genre>, CatalogFailure>> getGenres() async =>
      const Ok(_genres);

  /// Cursor por id (los ids del fake ya están en orden).
  @override
  Future<Result<CatalogPage, CatalogFailure>> getSongs({
    int? genreId,
    int limit = catalogPageSize,
    SongCursor? after,
  }) async {
    final matching = _songs
        .where((song) => genreId == null || song.genreId == genreId)
        .toList();
    final start = after == null
        ? 0
        : matching.indexWhere((song) => song.id == after.id) + 1;
    final page = matching.skip(start).take(limit).toList(growable: false);
    final hasMore = start + page.length < matching.length;
    return Ok(
      CatalogPage(
        page,
        next: hasMore ? SongCursor(createdAt: '', id: page.last.id) : null,
      ),
    );
  }
}
