import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/app.dart';
import 'package:sonify/core/di/providers.dart';
import 'package:sonify/core/result.dart';
import 'package:sonify/core/theme/theme_preference.dart';
import 'package:sonify/features/auth/infrastructure/fake_auth_repository.dart';
import 'package:sonify/features/catalog/domain/catalog_failure.dart';
import 'package:sonify/features/catalog/domain/catalog_page.dart';
import 'package:sonify/features/home/presentation/widgets/mini_player_bar.dart';
import 'package:sonify/features/shell/presentation/widgets/sonify_nav_bar.dart';

import '../../helpers/fake_audio_player.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_download_repository.dart';
import '../../helpers/fake_library_repository.dart';
import '../../helpers/fake_network_status.dart';

/// Lo que se guardó del modo claro/oscuro.
final class _ThemePreference implements ThemePreference {
  ThemeMode? saved;

  @override
  Future<ThemeMode> load() async => saved ?? ThemeMode.system;

  @override
  Future<void> save(ThemeMode mode) async => saved = mode;
}

void main() {
  late FakeAuthRepository auth;
  late FakeAudioPlayer player;
  late FakeDownloadRepository downloads;
  late _ThemePreference theme;

  setUp(() {
    auth = FakeAuthRepository(latency: Duration.zero);
    player = FakeAudioPlayer();
    downloads = FakeDownloadRepository();
    theme = _ThemePreference();
  });

  tearDown(() async {
    auth.dispose();
    await player.dispose();
    await downloads.dispose();
  });

  Future<void> signIn(
    WidgetTester tester,
    FakeLibraryRepository library,
  ) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    // La onda de lo que suena se anima sin fin: con "reducir movimiento"
    // queda quieta y pumpAndSettle puede terminar.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          audioPlayerProvider.overrideWithValue(player),
          downloadRepositoryProvider.overrideWithValue(downloads),
          libraryRepositoryProvider.overrideWithValue(library),
          networkStatusProvider.overrideWithValue(FakeNetworkStatus()),
          themePreferenceProvider.overrideWithValue(theme),
          catalogRepositoryProvider.overrideWithValue(
            const FakeCatalogRepository(),
          ),
        ],
        child: const SonifyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ingresar con Google'));
    await tester.pumpAndSettle();
  }

  Finder navTab(String label) => find.descendant(
    of: find.byType(SonifyNavBar),
    matching: find.bySemanticsLabel(label),
  );

  testWidgets(
    'cuenta gratis: guarda para escuchar, busca, biblioteca y Premium',
    (tester) async {
      final catalog =
          (await const FakeCatalogRepository().getSongs()
                  as Ok<CatalogPage, CatalogFailure>)
              .value
              .songs;
      final library = FakeLibraryRepository(isPremium: false, catalog: catalog);
      await signIn(tester, library);

      // Menú inferior con las cinco pestañas; subir canciones solo es del admin.
      for (final label in [
        'Inicio',
        'Buscar',
        'Biblioteca',
        'Premium',
        'Descargas',
      ]) {
        expect(navTab(label), findsOneWidget);
      }
      expect(find.byTooltip('Subir canción'), findsNothing);

      // Sin guardar, nada suena: ▷ ofrece guardarla y luego la reproduce.
      expect(find.byTooltip('Guardar para escuchar'), findsWidgets);
      await tester.tap(find.byTooltip('Reproducir'));
      await tester.pumpAndSettle();
      expect(find.text('Guárdala para escucharla'), findsOneWidget);
      expect(player.state.hasQueue, isFalse);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Guardar en tu biblioteca'),
      );
      await tester.pumpAndSettle();
      expect(library.saved, ['1']);
      expect(player.state.current?.title, 'Mariposa Traicionera');

      // Buscar en todo el catálogo y guardar desde el resultado.
      await tester.tap(navTab('Buscar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'vuela');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Vuela Vuela'), findsOneWidget);
      // Lo que suena sigue visible sobre el menú.
      expect(find.byType(MiniPlayerBar), findsOneWidget);
      await tester.tap(find.byTooltip('Guardar en tu biblioteca'));
      await tester.pumpAndSettle();
      expect(library.saved, ['1', '2']);

      // Tu biblioteca muestra el cupo y permite crear una playlist.
      await tester.tap(navTab('Biblioteca'));
      await tester.pumpAndSettle();
      expect(find.text('2 de 5 canciones'), findsOneWidget);
      await tester.tap(find.byTooltip('Nueva playlist'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Adrian auto');
      await tester.pump();
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();
      expect(find.text('Adrian auto'), findsOneWidget);

      // Premium explica el límite y cuánto usa.
      await tester.tap(navTab('Premium'));
      await tester.pumpAndSettle();
      expect(find.text('Usas 2 de 5'), findsOneWidget);
    },
  );

  testWidgets('el catálogo que llega pasa a la cola (URLs nuevas)', (
    tester,
  ) async {
    await signIn(tester, FakeLibraryRepository());

    expect(
      player.updated.map((song) => song.title),
      contains('Mariposa Traicionera'),
    );
  });

  testWidgets('el admin ve el botón de subir canciones', (tester) async {
    await signIn(tester, FakeLibraryRepository(isAdmin: true));

    expect(find.byTooltip('Subir canción'), findsOneWidget);
  });

  testWidgets('el mensaje de Buscar queda centrado en lo visible, sobre el '
      'menú', (tester) async {
    await signIn(tester, FakeLibraryRepository());
    await tester.tap(navTab('Buscar'));
    await tester.pumpAndSettle();

    final field = tester.getRect(find.byType(TextField));
    final menu = tester.getRect(find.byType(SonifyNavBar));
    final message = tester.getRect(
      find.textContaining('Busca en todo el catálogo'),
    );
    final visibleCenter = (field.bottom + menu.top) / 2;

    expect((message.center.dy - visibleCenter).abs(), lessThan(24));
  });

  testWidgets('en modo claro, tras el Login la hora y la batería se ven '
      'oscuras (el Login las deja blancas por la foto)', (tester) async {
    await signIn(tester, FakeLibraryRepository());

    expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.light);
    expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.dark);
  });

  testWidgets('con el sistema en oscuro, elegir claro cambia el tema, la '
      'barra de estado y se recuerda', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await signIn(tester, FakeLibraryRepository());

    BuildContext home() => tester.element(find.byType(SonifyNavBar));
    expect(Theme.of(home()).brightness, Brightness.dark);
    expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.dark);

    await tester.tap(find.byTooltip('Cambiar a modo claro'));
    await tester.pumpAndSettle();

    expect(Theme.of(home()).brightness, Brightness.light);
    // iOS: contenido claro detrás → hora y batería oscuras. Android: íconos
    // oscuros.
    expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.light);
    expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.dark);
    expect(theme.saved, ThemeMode.light);
    expect(find.byTooltip('Cambiar a modo oscuro'), findsOneWidget);
  });
}
