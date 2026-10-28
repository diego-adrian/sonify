import 'song.dart';

/// Canciones por página del catálogo. Una página pesa ~10 KB (texto y
/// URLs); lo pesado son las portadas, que se cargan solo para las filas
/// visibles. Páginas más chicas despertarían la radio más seguido.
const catalogPageSize = 30;

/// Dónde sigue la lista: después de la última canción recibida. Paginar por
/// posición repetiría o saltaría canciones si alguien sube una mientras se
/// navega. Opaco para el dominio: lo arma y lo interpreta el adaptador.
final class SongCursor {
  const SongCursor({required this.createdAt, required this.id});

  final String createdAt;
  final String id;
}

final class CatalogPage {
  const CatalogPage(this.songs, {this.next});

  final List<Song> songs;

  /// `null` si no hay más canciones.
  final SongCursor? next;

  bool get hasMore => next != null;
}
