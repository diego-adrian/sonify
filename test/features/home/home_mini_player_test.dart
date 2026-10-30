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
import 'package:sonify/features/home/presentation/widgets/mini_player_bar.dart';
import 'package:sonify/features/player/presentation/widgets/mini_progress_line.dart';

import '../../helpers/fake_audio_player.dart';
import '../../helpers/fake_download_repository.dart';
import '../../helpers/fake_library_repository.dart';
import '../../helpers/fake_network_status.dart';

final class _LongCatalog implements CatalogRepository {
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
  }) async => Ok(
    CatalogPage([
      for (var i = 1; i <= 30; i++)
        Song(
          id: '$i',
          title: 'Canción $i',
          artistName: 'Artista',
          duration: const Duration(minutes: 3),
          audio: Uri.parse('https://cdn/$i.m4a'),
        ),
    ]),
  );
}

bool _miniShown(WidgetTester tester) =>
    find.byType(MiniPlayerBar).evaluate().isNotEmpty;

void main() {
  testWidgets(
    'al bajar por la lista el reproductor queda pegado arriba en compacto',
    (tester) async {
      tester.view.physicalSize = const Size(1320, 2868);
      tester.view.devicePixelRatio = 3;
      // La onda de lo que suena se anima sin fin: con "reducir movimiento"
      // queda quieta y pumpAndSettle puede terminar.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      addTearDown(tester.view.reset);

      final auth = FakeAuthRepository(latency: Duration.zero);
      addTearDown(auth.dispose);
      final player = FakeAudioPlayer();
      addTearDown(player.dispose);
      final downloads = FakeDownloadRepository();
      addTearDown(downloads.dispose);

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
            catalogRepositoryProvider.overrideWithValue(_LongCatalog()),
          ],
          child: const SonifyApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ingresar con Google'));
      await tester.pumpAndSettle();
      expect(_miniShown(tester), isFalse);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(_miniShown(tester), isTrue);

      // Play desde la barra compacta.
      await tester.tap(
        find.descendant(
          of: find.byType(MiniPlayerBar),
          matching: find.byTooltip('Reproducir'),
        ),
      );
      await tester.pumpAndSettle();
      expect(player.state.playing, isTrue);
      // Con su línea de progreso al pie.
      expect(
        find.descendant(
          of: find.byType(MiniPlayerBar),
          matching: find.byType(MiniProgressLine),
        ),
        findsOneWidget,
      );

      // Siguiente y anterior desde la barra compacta.
      Finder mini(String tooltip) => find.descendant(
        of: find.byType(MiniPlayerBar),
        matching: find.byTooltip(tooltip),
      );
      final first = player.state.current?.id;
      await tester.tap(mini('Siguiente'));
      await tester.pumpAndSettle();
      expect(player.state.current?.id, isNot(first));
      await tester.tap(mini('Anterior'));
      await tester.pumpAndSettle();
      expect(player.state.current?.id, first);

      // Tocarla vuelve al reproductor grande.
      await tester.tap(find.byType(MiniPlayerBar));
      await tester.pumpAndSettle();
      expect(_miniShown(tester), isFalse);
    },
  );
}
