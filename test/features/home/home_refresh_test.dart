import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/app.dart';
import 'package:sonify/core/di/providers.dart';
import 'package:sonify/core/result.dart';
import 'package:sonify/features/auth/infrastructure/fake_auth_repository.dart';
import 'package:sonify/features/catalog/domain/catalog_failure.dart';
import 'package:sonify/features/catalog/domain/catalog_page.dart';
import 'package:sonify/features/catalog/domain/catalog_repository.dart';
import 'package:sonify/features/catalog/domain/genre.dart';
import 'package:sonify/features/catalog/domain/song.dart';

import '../../helpers/fake_audio_player.dart';
import '../../helpers/fake_download_repository.dart';
import '../../helpers/fake_library_repository.dart';
import '../../helpers/fake_network_status.dart';

final class _GrowingCatalog implements CatalogRepository {
  final songs = <Song>[_song('1', 'Primera')];

  @override
  Future<Result<List<Genre>, CatalogFailure>> getGenres() async => const Ok([]);

  @override
  Future<Result<List<Song>, CatalogFailure>> searchSongs(String query) async =>
      const Ok([]);

  @override
  Future<Result<CatalogPage, CatalogFailure>> getSongs({
    int? genreId,
    int limit = catalogPageSize,
    SongCursor? after,
  }) async => Ok(CatalogPage(List.of(songs.reversed)));
}

Song _song(String id, String title) => Song(
  id: id,
  title: title,
  artistName: 'Artista',
  duration: const Duration(minutes: 3),
  audio: Uri.parse('https://cdn/$id.m4a'),
);

void main() {
  testWidgets('deslizar hacia abajo trae las canciones nuevas', (tester) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final auth = FakeAuthRepository(latency: Duration.zero);
    addTearDown(auth.dispose);
    final player = FakeAudioPlayer();
    addTearDown(player.dispose);
    final downloads = FakeDownloadRepository();
    addTearDown(downloads.dispose);
    final catalog = _GrowingCatalog();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          audioPlayerProvider.overrideWithValue(player),
          downloadRepositoryProvider.overrideWithValue(downloads),
          libraryRepositoryProvider.overrideWithValue(FakeLibraryRepository()),
          networkStatusProvider.overrideWithValue(FakeNetworkStatus()),
          catalogRepositoryProvider.overrideWithValue(catalog),
        ],
        child: const SonifyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ingresar con Google'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva'), findsNothing);

    // Alguien sube una canción mientras la app está abierta.
    catalog.songs.add(_song('2', 'Nueva'));
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 600),
      1500,
    );
    await tester.pumpAndSettle();

    expect(find.text('Nueva'), findsWidgets);
  });
}
