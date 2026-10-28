import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/lifecycle/app_lifecycle_provider.dart';
import '../../../core/network/online_provider.dart';
import '../../../core/result.dart';
import '../../downloads/presentation/downloads_providers.dart';
import '../domain/catalog_page.dart';
import '../domain/genre.dart';
import '../domain/song.dart';

/// Pasado este tiempo, volver a la app recarga el catálogo (canciones nuevas
/// y URLs firmadas frescas: vencen a las 24–48 h).
const catalogMaxAge = Duration(minutes: 10);

/// Lo cargado del catálogo hasta ahora (páginas de [catalogPageSize]).
final class CatalogFeed {
  const CatalogFeed(
    this.songs, {
    this.next,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<Song> songs;
  final SongCursor? next;
  final bool loadingMore;

  /// Falló la última página pedida: se muestra "Reintentar" al final.
  final bool loadMoreFailed;

  bool get hasMore => next != null;
}

/// Catálogo público, las más recientes primero, de a [catalogPageSize]
/// (la Home pide la siguiente al acercarse al final). Se recarga desde la
/// primera página al deslizar hacia abajo, al volver a la app si pasaron
/// [catalogMaxAge] o al recuperar la red; nada de consultas periódicas.
final songsProvider = AsyncNotifierProvider<SongsFeed, CatalogFeed>(
  SongsFeed.new,
);

class SongsFeed extends AsyncNotifier<CatalogFeed> {
  /// Cambia en cada recarga: una página pedida antes no se mezcla después.
  Object _generation = Object();

  @override
  Future<CatalogFeed> build() async {
    _generation = Object();
    final loadedAt = DateTime.now();
    ref.listen(appResumedProvider, (_, resumed) {
      if (resumed && DateTime.now().difference(loadedAt) > catalogMaxAge) {
        ref.invalidateSelf();
      }
    });
    ref.listen(isOnlineProvider, (wasOnline, online) {
      if (wasOnline == false && online) ref.invalidateSelf();
    });
    return switch (await ref.watch(getSongsProvider)()) {
      Ok(:final value) => CatalogFeed(value.songs, next: value.next),
      Err(:final error) => throw error,
    };
  }

  /// Pide la siguiente página. No hace nada si no hay más o ya se está
  /// pidiendo una (se puede llamar en cada evento de scroll). Si la anterior
  /// falló, solo reintenta con [retry] (el botón): sin red, cada scroll
  /// volvería a gastar una petición.
  Future<void> loadMore({bool retry = false}) async {
    final current = state.value;
    if (current == null ||
        !current.hasMore ||
        current.loadingMore ||
        (current.loadMoreFailed && !retry) ||
        state.isLoading) {
      return;
    }
    final generation = _generation;
    state = AsyncData(
      CatalogFeed(current.songs, next: current.next, loadingMore: true),
    );
    final result = await ref.read(getSongsProvider)(after: current.next);
    if (!ref.mounted || generation != _generation) return;
    // Por si acaso: nunca dos filas de la misma canción.
    final seen = {for (final song in current.songs) song.id};
    state = AsyncData(switch (result) {
      Ok(:final value) => CatalogFeed([
        ...current.songs,
        ...value.songs.where((song) => !seen.contains(song.id)),
      ], next: value.next),
      Err() => CatalogFeed(
        current.songs,
        next: current.next,
        loadMoreFailed: true,
      ),
    });
  }
}

/// Lo que lista la Home (offline primero): el catálogo cuando llega y,
/// mientras tanto, lo descargado, que suena sin red. Así, con señal débil, la
/// app no se queda en la pantalla de carga esperando a Supabase. `null` si
/// todavía no hay nada que mostrar.
final catalogSongsProvider = Provider<List<Song>?>((ref) {
  final remote = ref.watch(songsProvider).value?.songs;
  if (remote != null) return remote;
  final downloaded = ref.watch(downloadedSongsProvider);
  return downloaded.isEmpty ? null : downloaded;
});

/// Las de [catalogSongsProvider] que pueden sonar ahora: todas con red; sin
/// red, las descargadas y las de la caché de lo escuchado (las demás se ven
/// atenuadas).
final playableSongsProvider = Provider<List<Song>>((ref) {
  final songs = ref.watch(catalogSongsProvider) ?? const <Song>[];
  if (ref.watch(isOnlineProvider)) return songs;
  final local = {
    for (final song in ref.watch(downloadedSongsProvider)) song.id,
    for (final song in ref.watch(cachedSongsProvider).value ?? const <Song>[])
      song.id,
  };
  return [
    for (final song in songs)
      if (local.contains(song.id)) song,
  ];
});

final genresProvider = FutureProvider<List<Genre>>((ref) async {
  return switch (await ref.watch(getGenresProvider)()) {
    Ok(:final value) => value,
    Err(:final error) => throw error,
  };
});
