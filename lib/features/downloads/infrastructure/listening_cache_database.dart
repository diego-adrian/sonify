import 'package:drift/drift.dart';

part 'listening_cache_database.g.dart';

/// Una fila por canción en la caché de lo escuchado. Guarda lo necesario
/// para listarla y reproducirla sin red. Rutas relativas a la carpeta de la
/// caché (en iOS la ruta absoluta del contenedor cambia al actualizar).
class CachedSongs extends Table {
  TextColumn get songId => text()();
  TextColumn get title => text()();
  TextColumn get artistName => text()();
  IntColumn get genreId => integer().nullable()();
  IntColumn get durationMs => integer()();
  TextColumn get audioUrl => text()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get coverLargeUrl => text().nullable()();
  TextColumn get audioFile => text()();
  TextColumn get contentType => text()();

  /// Bytes del audio cifrado en disco.
  IntColumn get sizeBytes => integer()();

  /// Al llenarse la caché se borra primero la de fecha más vieja.
  DateTimeColumn get lastPlayedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {songId};
}

@DriftDatabase(tables: [CachedSongs])
class ListeningCacheDatabase extends _$ListeningCacheDatabase {
  ListeningCacheDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
