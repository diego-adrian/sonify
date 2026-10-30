import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/app_user.dart';
import '../../catalog/domain/song.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../catalog/presentation/widgets/song_tile.dart';
import '../../downloads/presentation/widgets/song_download_button.dart';
import '../../library/presentation/library_actions.dart';
import '../../library/presentation/library_providers.dart';
import '../../player/domain/playback_snapshot.dart';
import '../../player/presentation/player_providers.dart';
import '../../upload/presentation/upload_page.dart';
import 'home_providers.dart';
import 'widgets/mini_player_bar.dart';
import 'widgets/now_playing_header.dart';
import 'widgets/user_avatar.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_mode_provider.dart';

/// Home (Figma node 106:97 "Home V1 Oficial").
class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final songs = ref.watch(songsProvider);
    final current = ref.watch(currentSongProvider);

    final Widget body;
    if (current != null) {
      body = _HomeContent(user: user, current: current);
    } else if (songs.hasError) {
      body = _Message(
        text: l10n.catalogError,
        action: TextButton(
          onPressed: () => ref.invalidate(songsProvider),
          child: Text(l10n.retry),
        ),
      );
    } else if (songs.hasValue) {
      body = _Message(
        text: l10n.catalogEmpty,
        action: TextButton(
          onPressed: () => ref.invalidate(songsProvider),
          child: Text(l10n.refresh),
        ),
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(body: SafeArea(bottom: false, child: body));
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent({required this.user, required this.current});

  final AppUser user;
  final Song current;

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  final _scroll = ScrollController();
  final _headerKey = GlobalKey();

  /// `true` cuando el reproductor grande quedó tapado al bajar por la lista.
  /// Solo cambia al cruzar el umbral: hacer scroll no reconstruye la Home.
  final _showMini = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _scroll
      ..addListener(_updateMini)
      ..addListener(_loadMoreNearEnd);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _showMini.dispose();
    super.dispose();
  }

  /// Pide la siguiente página cuando faltan ~10 filas para el final, así al
  /// bajar no se llega a ver la espera.
  void _loadMoreNearEnd() {
    if (_scroll.position.extentAfter < AppSizes.trackRowHeight * 10) {
      ref.read(songsProvider.notifier).loadMore();
    }
  }

  void _updateMini() {
    final header = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (header == null || !header.attached) return;
    // Posición del reproductor grande dentro de la lista (no en pantalla: la
    // de pantalla no se actualiza cuando sale del área visible).
    final top = RenderAbstractViewport.of(header)
        .getOffsetToReveal(header, 0)
        .offset;
    final bottom = top + header.size.height;
    _showMini.value = _scroll.offset > bottom - MiniPlayerBar.height;
  }

  void _scrollToTop() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final current = widget.current;
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(catalogSongsProvider) ?? const <Song>[];
    // Solo con el catálogo remoto: lo descargado no se pagina.
    final feed = ref.watch(songsProvider).value;
    final playback = ref.watch(playbackProvider).value ?? PlaybackSnapshot.idle;
    final isLoaded = playback.current?.id == current.id;
    final access = ref.watch(songAccessProvider);

    // Sin red, la cola y anterior/siguiente solo usan lo descargado.
    final playable = {
      for (final song in ref.watch(playableSongsProvider)) song.id,
    };
    List<Song> catalog() => ref.read(playableSongsProvider);
    Future<void> playFrom(Song song) =>
        ref.read(playSongsProvider)(catalog(), song);

    void step(int delta) {
      if (playback.hasQueue) {
        delta < 0
            ? ref.read(skipToPreviousProvider)()
            : ref.read(skipToNextProvider)();
        return;
      }
      final target = adjacentSong(catalog(), current, delta);
      if (target != null) {
        ref.read(currentSongIdProvider.notifier).select(target.id);
      }
    }

    // Cuenta gratis y canción no guardada: ofrece guardarla y la reproduce.
    void unlock(Song song) => showLockedSongSheet(
      context,
      ref,
      song: song,
      onSaved: (saved) {
        // Tras guardarla ya está en la cola de lo que se puede escuchar.
        final queue = catalog();
        ref.read(playSongsProvider)(
          queue.any((song) => song.id == saved.id) ? queue : [saved],
          saved,
        );
      },
    );

    void playPause() => isLoaded
        ? ref.read(togglePlaybackProvider)()
        : access.canPlay(current)
        ? playFrom(current)
        : unlock(current);

    // Deslizar hacia abajo trae las canciones nuevas (mientras recarga se
    // sigue viendo la lista anterior).
    final scrollView = RefreshIndicator.adaptive(
      onRefresh: () => ref.refresh(songsProvider.future),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _TopBar(user: user)),
          SliverToBoxAdapter(
            child: NowPlayingHeader(
              key: _headerKey,
              song: current,
              isLoaded: isLoaded,
              playing: isLoaded && playback.playing,
              buffering: isLoaded && playback.buffering,
              shuffle: playback.shuffle,
              repeat: playback.repeat,
              duration: isLoaded
                  ? (playback.duration ?? current.duration)
                  : current.duration,
              onPlayPause: playPause,
              onPrevious: () => step(-1),
              onNext: () => step(1),
              onShuffle: () async {
                if (!playback.hasQueue) await playFrom(current);
                await ref.read(setShuffleProvider)(!playback.shuffle);
              },
              onRepeat: () async {
                if (!playback.hasQueue) await playFrom(current);
                await ref.read(cycleRepeatProvider)(playback);
              },
              onSeek: (position) => ref.read(seekToProvider)(position),
              loading: !ref.watch(currentSongSettledProvider),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverFixedExtentList.builder(
            itemExtent: SongTile.height,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final song = list[index];
              final locked = !access.canPlay(song);
              final available = locked || playable.contains(song.id);
              final isCurrent = playback.current?.id == song.id;
              final nowPlaying = isCurrent && playback.playing;
              void open() => locked
                  ? unlock(song)
                  // La que ya suena no vuelve a empezar: tocarla la retoma
                  // si estaba en pausa.
                  : isCurrent
                  ? (nowPlaying ? null : ref.read(togglePlaybackProvider)())
                  : playFrom(song);
              return SongTile(
                song: song,
                // La descripción o, si no tiene, el artista.
                subtitle: song.descriptionOrArtist,
                locked: locked,
                nowPlaying: nowPlaying,
                enabled: available,
                actionTooltip: locked
                    ? l10n.lockedTooltip
                    : nowPlaying
                    ? l10n.pause
                    : available
                    ? l10n.playSong(song.title)
                    : l10n.songNeedsConnection,
                onTap: open,
                // La onda pausa lo que suena.
                onAction: nowPlaying
                    ? () => ref.read(togglePlaybackProvider)()
                    : open,
                // Solo se descarga lo que se puede escuchar.
                secondaryAction: locked
                    ? null
                    : SongDownloadButton(song: song, list: catalog()),
                onLongPress: () =>
                    showSongActionsSheet(context, ref, song: song, list: list),
              );
            },
          ),
          if (feed != null && feed.loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            )
          else if (feed != null && feed.loadMoreFailed)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      l10n.catalogLoadMoreError,
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(songsProvider.notifier)
                          .loadMore(retry: true),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
          ),
        ],
      ),
    );

    final animate = !MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: [
        scrollView,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          // Oculta no se construye: ni widgets de más ni texto duplicado.
          child: ValueListenableBuilder<bool>(
            valueListenable: _showMini,
            builder: (context, show, child) => AnimatedSwitcher(
              duration: animate
                  ? const Duration(milliseconds: 200)
                  : Duration.zero,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: show ? child : const SizedBox.shrink(),
            ),
            child: MiniPlayerBar(
              song: current,
              playing: isLoaded && playback.playing,
              buffering: isLoaded && playback.buffering,
              onTap: _scrollToTop,
              onPlayPause: playPause,
              onPrevious: () => step(-1),
              onNext: () => step(1),
              loaded: isLoaded,
              duration: isLoaded
                  ? (playback.duration ?? current.duration)
                  : current.duration,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l10n.account,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => _showAccountSheet(context, ref),
              child: UserAvatar(
                name: user.displayName,
                imageUrl: user.avatarUrl,
                size: 40,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.homeGreeting(user.displayName.split(' ').first),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(color: scheme.onSurface),
            ),
          ),
          const _ThemeToggle(),
          // Solo los admins suben canciones (el backend también lo exige).
          if (ref.watch(accountProvider.select((account) => account.isAdmin)))
            IconButton(
              tooltip: l10n.uploadTitle,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const UploadPage()),
              ),
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
    );
  }

  void _showAccountSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.logout_rounded),
          title: Text(l10n.signOut),
          onTap: () async {
            Navigator.of(sheetContext).pop();
            await ref.read(stopPlaybackProvider)();
            // Lo descargado se conserva para cuando vuelva a entrar.
            await ref.read(suspendDownloadsProvider)();
            await ref.read(signOutProvider)();
          },
        ),
      ),
    );
  }
}

/// Luna en modo claro (pasa a oscuro) y sol en modo oscuro (pasa a claro).
/// La elección se recuerda; sin elegir, la app sigue al sistema.
class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shown = Theme.of(context).brightness;
    final dark = shown == Brightness.dark;
    return IconButton(
      tooltip: dark ? l10n.themeToLight : l10n.themeToDark,
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(shown),
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
