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
import 'package:sonify/features/catalog/presentation/widgets/song_tile.dart';
import 'package:sonify/features/downloads/domain/download_entry.dart';

import '../../helpers/fake_audio_player.dart';
import '../../helpers/fake_download_repository.dart';
import '../../helpers/fake_network_status.dart';

final class _CountingCatalog implements CatalogRepository {
  int calls = 0;

  @override
  Future<Result<List<Genre>, CatalogFailure>> getGenres() async => const Ok([]);

  @override
  Future<Result<CatalogPage, CatalogFailure>> getSongs({
    int? genreId,
    int limit = catalogPageSize,
    SongCursor? after,
  }) async {
    calls++;
    return Ok(CatalogPage([_remote, _downloaded]));
  }
}

final _remote = _song('1', 'Solo en línea');
final _downloaded = _song('2', 'Descargada');

Song _song(String id, String title) => Song(
  id: id,
  title: title,
  artistName: 'Artista',
  duration: const Duration(minutes: 3),
  audio: Uri.parse('https://cdn/$id.m4a'),
);

SongTile _tile(WidgetTester tester, String title) => tester.widget<SongTile>(
  find.ancestor(of: find.text(title), matching: find.byType(SongTile)).first,
);

void main() {
  testWidgets(
    'sin red atenúa las no descargadas y al volver la red recarga el catálogo',
    (tester) async {
      tester.view.physicalSize = const Size(1320, 2868);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final auth = FakeAuthRepository(latency: Duration.zero);
      addTearDown(auth.dispose);
      final player = FakeAudioPlayer();
      addTearDown(player.dispose);
      final downloads = FakeDownloadRepository()
        ..entries.add(
          DownloadEntry(song: _downloaded, state: DownloadState.done),
        );
      addTearDown(downloads.dispose);
      final network = FakeNetworkStatus();
      addTearDown(network.dispose);
      final catalog = _CountingCatalog();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            audioPlayerProvider.overrideWithValue(player),
            downloadRepositoryProvider.overrideWithValue(downloads),
            networkStatusProvider.overrideWithValue(network),
            catalogRepositoryProvider.overrideWithValue(catalog),
          ],
          child: const SonifyApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ingresar con Google'));
      await tester.pumpAndSettle();
      expect(_tile(tester, 'Solo en línea').enabled, isTrue);
      expect(catalog.calls, 1);

      // Entra al sótano: la lista se mantiene, pero solo suena lo descargado.
      network.online = false;
      await tester.pumpAndSettle();
      expect(_tile(tester, 'Solo en línea').enabled, isFalse);
      expect(_tile(tester, 'Descargada').enabled, isTrue);

      await tester.tap(find.byTooltip('Reproducir Descargada'));
      await tester.pumpAndSettle();
      expect(player.state.queue.map((s) => s.id), ['2']);

      network.online = true;
      await tester.pumpAndSettle();
      expect(_tile(tester, 'Solo en línea').enabled, isTrue);
      expect(catalog.calls, 2);
    },
  );
}
