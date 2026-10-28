import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/result.dart';
import '../domain/genre.dart';
import '../domain/song.dart';

/// Catálogo público, las más recientes primero.
final songsProvider = FutureProvider<List<Song>>((ref) async {
  return switch (await ref.watch(getSongsProvider)()) {
    Ok(:final value) => value,
    Err(:final error) => throw error,
  };
});

final genresProvider = FutureProvider<List<Genre>>((ref) async {
  return switch (await ref.watch(getGenresProvider)()) {
    Ok(:final value) => value,
    Err(:final error) => throw error,
  };
});
