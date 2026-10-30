import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/app.dart';
import 'package:sonify/core/di/providers.dart';
import 'package:sonify/features/catalog/presentation/widgets/now_playing_bars.dart';
import 'package:sonify/features/auth/infrastructure/fake_auth_repository.dart';

import '../../../helpers/fake_audio_player.dart';
import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/fake_download_repository.dart';
import '../../../helpers/fake_library_repository.dart';
import '../../../helpers/fake_network_status.dart';

void main() {
  testWidgets('login con Google lleva a la Home y cerrar sesión vuelve', (
    tester,
  ) async {
    // Pantalla de iPhone (440×956 pt).
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    // La onda de lo que suena se anima sin fin: con "reducir movimiento"
    // queda quieta y pumpAndSettle puede terminar.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    addTearDown(tester.view.reset);

    final repository = FakeAuthRepository(latency: Duration.zero);
    addTearDown(repository.dispose);
    final player = FakeAudioPlayer();
    addTearDown(player.dispose);
    final downloads = FakeDownloadRepository();
    addTearDown(downloads.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          audioPlayerProvider.overrideWithValue(player),
          downloadRepositoryProvider.overrideWithValue(downloads),
          libraryRepositoryProvider.overrideWithValue(FakeLibraryRepository()),
          networkStatusProvider.overrideWithValue(FakeNetworkStatus()),
          catalogRepositoryProvider.overrideWithValue(
            const FakeCatalogRepository(),
          ),
        ],
        child: const SonifyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sonify'), findsOneWidget);
    expect(find.text('tu ritmo son latino'), findsOneWidget);

    await tester.tap(find.text('Ingresar con Google'));
    await tester.pumpAndSettle();

    expect(find.text('Hola, Artista'), findsOneWidget);
    // La primera canción del catálogo queda arriba como actual.
    // (arriba y también en la lista, que muestra todo el catálogo).
    expect(find.text('Mariposa Traicionera'), findsNWidgets(2));
    // Cada fila tiene su botón de descarga, además de mantenerla presionada.
    expect(find.byTooltip('Descargar'), findsWidgets);

    // ▶ reproduce desde la canción mostrada.
    await tester.tap(find.byTooltip('Reproducir'));
    await tester.pumpAndSettle();
    expect(player.state.current?.title, 'Mariposa Traicionera');
    // Pausar en el reproductor grande y en la fila, que muestra la onda.
    expect(find.byTooltip('Pausar'), findsNWidgets(2));
    expect(find.byType(NowPlayingBars), findsOneWidget);

    // La onda pausa: la fila vuelve a ▷.
    await tester.tap(find.byType(NowPlayingBars));
    await tester.pumpAndSettle();
    expect(player.state.playing, isFalse);
    expect(find.byType(NowPlayingBars), findsNothing);
    await tester.tap(find.byTooltip('Reproducir').first);
    await tester.pumpAndSettle();

    // Siguiente avanza en la cola.
    await tester.tap(find.byTooltip('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Vuela Vuela'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    // Cerrar sesión detiene la música y pausa las descargas sin borrarlas.
    expect(player.state.hasQueue, isFalse);
    expect(downloads.suspendCalls, 1);
    expect(downloads.removeAllCalls, 0);

    expect(find.text('Ingresar con Google'), findsOneWidget);
  });
}
