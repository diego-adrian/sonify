import 'dart:async';

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
import 'package:sonify/features/downloads/domain/download_entry.dart';
import 'package:sonify/features/home/presentation/widgets/now_playing_header.dart';

import '../../helpers/fake_audio_player.dart';
import '../../helpers/fake_download_repository.dart';
import '../../helpers/fake_library_repository.dart';
import '../../helpers/fake_network_status.dart';

/// Señal débil (sótano): el catálogo tarda en responder.
final class _SlowCatalog implements CatalogRepository {
  final response = Completer<Result<CatalogPage, CatalogFailure>>();

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
  }) => response.future;
}

Song _song(String id, String title) => Song(
  id: id,
  title: title,
  artistName: 'Artista',
  duration: const Duration(minutes: 3),
  audio: Uri.parse('https://cdn/$id.m4a'),
);

void main() {
  testWidgets(
    'muestra lo descargado sin esperar al catálogo y luego lo reemplaza',
    (tester) async {
      tester.view.physicalSize = const Size(1320, 2868);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final auth = FakeAuthRepository(latency: Duration.zero);
      addTearDown(auth.dispose);
      final player = FakeAudioPlayer();
      addTearDown(player.dispose);
      final downloads = FakeDownloadRepository()
        ..entries.addAll([
          DownloadEntry(
            song: _song('1', 'Descargada'),
            state: DownloadState.done,
          ),
          DownloadEntry(
            song: _song('2', 'A medias'),
            state: DownloadState.queued,
          ),
        ]);
      addTearDown(downloads.dispose);
      final catalog = _SlowCatalog();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            audioPlayerProvider.overrideWithValue(player),
            downloadRepositoryProvider.overrideWithValue(downloads),
            libraryRepositoryProvider.overrideWithValue(
              FakeLibraryRepository(),
            ),
            networkStatusProvider.overrideWithValue(FakeNetworkStatus()),
            catalogRepositoryProvider.overrideWithValue(catalog),
          ],
          child: const SonifyApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ingresar con Google'));
      // Sin pumpAndSettle: el indicador de carga de la portada gira hasta
      // que llega el catálogo.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // La lista ya muestra lo descargado (no hay pantalla de carga)...
      expect(find.byType(NowPlayingHeader), findsOneWidget);
      expect(find.text('Descargada'), findsWidgets);
      expect(find.text('A medias'), findsNothing);
      // ...pero arriba no se fija una canción que va a cambiar: indicador de
      // carga en la portada y título oculto, hasta que llegue el catálogo.
      final header = find.byType(NowPlayingHeader);
      expect(
        find.descendant(
          of: header,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find
            .descendant(of: header, matching: find.text('Descargada'))
            .hitTestable(),
        findsNothing,
      );

      catalog.response.complete(Ok(CatalogPage([_song('3', 'Remota')])));
      await tester.pumpAndSettle();

      expect(find.text('Remota'), findsWidgets);
      expect(find.text('Descargada'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
