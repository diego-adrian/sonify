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

/// 75 canciones: 3 páginas de 30, 30 y 15.
final class _PagedCatalog implements CatalogRepository {
  final requests = <String?>[];
  bool failNext = false;

  static final _songs = [
    for (var i = 1; i <= 75; i++)
      Song(
        id: '$i',
        title: 'Canción $i',
        artistName: 'Artista',
        duration: const Duration(minutes: 3),
        audio: Uri.parse('https://cdn/$i.m4a'),
      ),
  ];

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
  }) async {
    requests.add(after?.id);
    if (failNext) {
      failNext = false;
      return const Err(CatalogFailure.network);
    }
    final start = after == null ? 0 : int.parse(after.id);
    final page = _songs.skip(start).take(limit).toList();
    final end = start + page.length;
    return Ok(
      CatalogPage(
        page,
        next: end < _songs.length
            ? SongCursor(createdAt: '', id: '$end')
            : null,
      ),
    );
  }
}

void main() {
  late _PagedCatalog catalog;

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final auth = FakeAuthRepository(latency: Duration.zero);
    addTearDown(auth.dispose);
    final player = FakeAudioPlayer();
    addTearDown(player.dispose);
    final downloads = FakeDownloadRepository();
    addTearDown(downloads.dispose);
    catalog = _PagedCatalog();

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
  }

  Future<void> scrollToEnd(WidgetTester tester) async {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
    await tester.pumpAndSettle();
  }

  testWidgets('carga de a 30 al acercarse al final, hasta la última', (
    tester,
  ) async {
    await pumpHome(tester);
    expect(catalog.requests, [null]);

    await scrollToEnd(tester);
    expect(catalog.requests, [null, '30']);
    await scrollToEnd(tester);
    expect(catalog.requests, [null, '30', '60']);

    // No hay más: seguir bajando no pide nada.
    await scrollToEnd(tester);
    expect(find.text('Canción 75'), findsOneWidget);
    expect(catalog.requests, hasLength(3));
  });

  testWidgets('si falla una página conserva la lista y deja reintentar', (
    tester,
  ) async {
    await pumpHome(tester);
    catalog.failNext = true;

    await scrollToEnd(tester);
    expect(find.text('No se pudieron cargar más canciones'), findsOneWidget);
    expect(find.text('Canción 30'), findsOneWidget);

    // Seguir bajando no reintenta solo (sin red gastaría peticiones).
    await scrollToEnd(tester);
    expect(catalog.requests, [null, '30']);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudieron cargar más canciones'), findsNothing);
    expect(catalog.requests, [null, '30', '30']);
  });
}
