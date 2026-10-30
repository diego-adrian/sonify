import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/app_user.dart';
import '../../downloads/presentation/downloads_page.dart';
import '../../home/presentation/home_page.dart';
import '../../home/presentation/widgets/mini_player_bar.dart';
import '../../library/presentation/library_page.dart';
import '../../player/domain/playback_snapshot.dart';
import '../../player/presentation/player_providers.dart';
import '../../premium/presentation/premium_page.dart';
import '../../search/presentation/search_page.dart';
import 'shell_providers.dart';
import 'widgets/sonify_nav_bar.dart';

/// Menú inferior fijo: Inicio, Buscar, Tu biblioteca, Premium y Descargas.
///
/// Cada pestaña tiene su propia pila de navegación (abrir una playlist no
/// tapa el menú) y se construye la primera vez que se visita. Las ocultas
/// conservan su estado sin animar (`IndexedStack` apaga sus tickers). El
/// contenido sigue detrás del menú (`extendBody`), y las listas terminan con
/// un espacio del alto del menú (`MediaQuery.paddingOf(context).bottom`).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _navigators = {
    for (final tab in ShellTab.values) tab: GlobalKey<NavigatorState>(),
  };
  final _visited = <ShellTab>{ShellTab.home};

  /// Orden de las pestañas en el menú.
  static const _menuOrder = [
    ShellTab.home,
    ShellTab.search,
    ShellTab.library,
    ShellTab.premium,
    ShellTab.downloads,
  ];

  Widget _root(ShellTab tab) => switch (tab) {
    ShellTab.home => HomePage(user: widget.user),
    ShellTab.search => const SearchPage(),
    ShellTab.library => const LibraryPage(),
    ShellTab.premium => const PremiumPage(),
    ShellTab.downloads => const DownloadsPage(),
  };

  void _select(ShellTab tab, ShellTab current) {
    if (tab == current) {
      // Tocar la pestaña activa vuelve a su pantalla principal.
      _navigators[tab]!.currentState?.popUntil((route) => route.isFirst);
      return;
    }
    ref.read(shellTabProvider.notifier).select(tab);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tab = ref.watch(shellTabProvider);
    // La cola se queda con las URLs nuevas del catálogo y la biblioteca.
    ref.watch(queueFreshnessProvider);
    _visited.add(tab);

    return Scaffold(
      extendBody: true,
      body: NavigatorPopHandler<Object?>(
        // Atrás de Android: primero dentro de la pestaña, luego a Inicio.
        onPopWithResult: (_) {
          final navigator = _navigators[tab]!.currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
          } else if (tab != ShellTab.home) {
            ref.read(shellTabProvider.notifier).select(ShellTab.home);
          }
        },
        child: IndexedStack(
          index: tab.index,
          children: [
            for (final item in ShellTab.values)
              if (_visited.contains(item))
                Navigator(
                  key: _navigators[item],
                  onGenerateRoute: (settings) => MaterialPageRoute<void>(
                    settings: settings,
                    builder: (_) => _root(item),
                  ),
                )
              else
                const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inicio ya tiene su reproductor.
          if (tab != ShellTab.home) const _ShellMiniPlayer(),
          SonifyNavBar(
            selectedIndex: _menuOrder.indexOf(tab),
            onSelected: (index) => _select(_menuOrder[index], tab),
            items: [
              SonifyNavItem(icon: Icons.home_outlined, label: l10n.navHome),
              SonifyNavItem(icon: Icons.search_rounded, label: l10n.navSearch),
              SonifyNavItem(
                icon: Icons.library_music_outlined,
                label: l10n.navLibraryShort,
              ),
              SonifyNavItem(
                icon: Icons.workspace_premium_outlined,
                label: l10n.navPremium,
              ),
              SonifyNavItem(
                icon: Icons.download_for_offline_outlined,
                label: l10n.downloads,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lo que suena, sobre el menú, en las pestañas que no son Inicio. Tocarlo
/// vuelve a Inicio, donde está el reproductor grande.
class _ShellMiniPlayer extends ConsumerWidget {
  const _ShellMiniPlayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider).value ?? PlaybackSnapshot.idle;
    final song = playback.current;
    if (song == null) return const SizedBox.shrink();

    return MiniPlayerBar(
      song: song,
      playing: playback.playing,
      buffering: playback.buffering,
      onTap: () => ref.read(shellTabProvider.notifier).select(ShellTab.home),
      onPlayPause: () => ref.read(togglePlaybackProvider)(),
      onPrevious: () => ref.read(skipToPreviousProvider)(),
      onNext: () => ref.read(skipToNextProvider)(),
      loaded: true,
      duration: playback.duration ?? song.duration,
      floating: true,
    );
  }
}
