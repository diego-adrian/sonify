import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/app_user.dart';
import '../../catalog/domain/song.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../catalog/presentation/widgets/song_tile.dart';
import '../../downloads/presentation/download_actions.dart';
import '../../downloads/presentation/downloads_page.dart';
import '../../downloads/presentation/downloads_providers.dart';
import '../../player/domain/playback_snapshot.dart';
import '../../player/presentation/player_providers.dart';
import '../../upload/presentation/upload_page.dart';
import 'home_providers.dart';
import 'widgets/home_tabs.dart';
import 'widgets/now_playing_header.dart';
import 'widgets/user_avatar.dart';
import '../../../core/theme/app_typography.dart';

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
      body = _Message(text: l10n.catalogEmpty);
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(body: SafeArea(bottom: false, child: body));
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.user, required this.current});

  final AppUser user;
  final Song current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tab = ref.watch(homeTabProvider);
    final list = ref.watch(
      tab == HomeTab.similar ? similarSongsProvider : upNextSongsProvider,
    );
    final playback = ref.watch(playbackProvider).value ?? PlaybackSnapshot.idle;
    final isLoaded = playback.current?.id == current.id;
    final downloads = ref.watch(downloadStatesProvider);

    List<Song> catalog() => ref.read(songsProvider).value ?? const <Song>[];
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

    void openSong(Song song) {
      if (tab == HomeTab.upNext && playback.hasQueue) {
        ref.read(skipToSongProvider)(song.id);
      } else {
        playFrom(song);
      }
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _TopBar(user: user)),
        SliverToBoxAdapter(
          child: NowPlayingHeader(
            song: current,
            isLoaded: isLoaded,
            playing: isLoaded && playback.playing,
            buffering: isLoaded && playback.buffering,
            shuffle: playback.shuffle,
            duration: isLoaded
                ? (playback.duration ?? current.duration)
                : current.duration,
            onPlayPause: () => isLoaded
                ? ref.read(togglePlaybackProvider)(playback)
                : playFrom(current),
            onPrevious: () => step(-1),
            onNext: () => step(1),
            onShuffle: () async {
              if (!playback.hasQueue) await playFrom(current);
              await ref.read(setShuffleProvider)(!playback.shuffle);
            },
            onQueue: () =>
                ref.read(homeTabProvider.notifier).select(HomeTab.upNext),
            onSeek: (position) => ref.read(seekToProvider)(position),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabsDelegate(
            selected: tab,
            onSelected: ref.read(homeTabProvider.notifier).select,
          ),
        ),
        if (list.isEmpty)
          SliverToBoxAdapter(
            child: _Message(
              text: tab == HomeTab.similar
                  ? l10n.similarEmpty
                  : l10n.upNextEmpty,
            ),
          )
        else
          SliverFixedExtentList.builder(
            itemExtent: SongTile.height,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final song = list[index];
              final isQueue = tab == HomeTab.upNext;
              return SongTile(
                song: song,
                action: isQueue ? SongTileAction.queue : SongTileAction.play,
                actionTooltip: isQueue
                    ? l10n.reorder
                    : l10n.playSong(song.title),
                onTap: () => openSong(song),
                // TODO: reordenar la cola arrastrando.
                onAction: () => openSong(song),
                downloadState: downloads[song.id],
                onLongPress: () =>
                    showSongDownloadSheet(context, ref, song: song, list: list),
              );
            },
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
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
          IconButton(
            tooltip: l10n.uploadTitle,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const UploadPage())),
            icon: const Icon(Icons.add_rounded),
          ),
          IconButton(
            tooltip: l10n.downloads,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DownloadsPage()),
            ),
            icon: const Icon(Icons.download_for_offline_outlined),
          ),
          IconButton(
            tooltip: l10n.search,
            // TODO: búsqueda.
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
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

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  const _TabsDelegate({required this.selected, required this.onSelected});

  final HomeTab selected;
  final ValueChanged<HomeTab> onSelected;

  @override
  double get minExtent => HomeTabs.height;

  @override
  double get maxExtent => HomeTabs.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      HomeTabs(selected: selected, onSelected: onSelected);

  @override
  bool shouldRebuild(_TabsDelegate oldDelegate) =>
      oldDelegate.selected != selected;
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
