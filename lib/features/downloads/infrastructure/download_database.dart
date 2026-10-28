import 'package:drift/drift.dart';

part 'download_database.g.dart';

enum DownloadRowState { queued, done, failed }

/// Una fila por canción descargada (o en cola). Guarda lo necesario para
/// listar y reproducir sin red. Las rutas son relativas a Application Support
/// porque en iOS la ruta absoluta del contenedor cambia entre actualizaciones.
class Downloads extends Table {
  TextColumn get songId => text()();
  TextColumn get title => text()();
  TextColumn get artistName => text()();
  IntColumn get genreId => integer().nullable()();
  IntColumn get durationMs => integer()();
  TextColumn get audioUrl => text()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get coverLargeUrl => text().nullable()();

  /// SHA-256 esperado según el catálogo; si no coincide, la descarga falla.
  TextColumn get expectedSha256 => text().nullable()();
  IntColumn get state => intEnum<DownloadRowState>()();
  TextColumn get taskId => text()();
  TextColumn get audioFile => text().nullable()();
  TextColumn get coverFile => text().nullable()();
  TextColumn get contentType => text().nullable()();

  /// Bytes que ocupa en disco (audio cifrado + portada).
  IntColumn get sizeBytes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {songId};
}

@DriftDatabase(tables: [Downloads])
class DownloadDatabase extends _$DownloadDatabase {
  DownloadDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
