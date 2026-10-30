import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/library.dart';
import 'library_actions.dart';
import 'library_providers.dart';
import 'library_songs_page.dart';
import '../../../core/widgets/visible_center.dart';

/// Tu biblioteca (menú inferior): las canciones guardadas y las playlists.
/// Sin red muestra la última copia guardada en el dispositivo.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(libraryProvider);

    Future<void> createPlaylist() async {
      final name = await showPlaylistNameDialog(
        context,
        title: l10n.libraryNewPlaylist,
        action: l10n.playlistCreate,
      );
      if (name == null || !context.mounted) return;
      final failure = await ref
          .read(libraryProvider.notifier)
          .createPlaylist(name);
      if (context.mounted) showLibraryResult(context, ref, failure);
    }

    final Widget body = switch (state) {
      AsyncValue(:final value?) => RefreshIndicator.adaptive(
        onRefresh: () => ref.refresh(libraryProvider.future),
        child: _LibraryList(library: value, onCreatePlaylist: createPlaylist),
      ),
      AsyncValue(hasError: true) => VisibleCenter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.libraryError,
              style: AppTypography.body.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(libraryProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      _ => const VisibleCenter(child: CircularProgressIndicator()),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navLibrary, style: AppTypography.appBarTitle),
        actions: [
          IconButton(
            tooltip: l10n.libraryNewPlaylist,
            onPressed: state.hasValue ? createPlaylist : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _LibraryList extends StatelessWidget {
  const _LibraryList({required this.library, required this.onCreatePlaylist});

  final Library library;
  final VoidCallback onCreatePlaylist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final limit = library.account.unlimited
        ? null
        : library.account.libraryLimit;

    void open(String? playlistId) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LibrarySongsPage(playlistId: playlistId),
      ),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _CollectionTile(
          icon: Icons.favorite_rounded,
          highlighted: true,
          title: l10n.librarySavedSongs,
          subtitle: limit == null
              ? l10n.librarySongCount(library.songs.length)
              : l10n.librarySongCountLimit(library.songs.length, limit),
          onTap: () => open(null),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(
            l10n.libraryPlaylists,
            style: AppTypography.title.copyWith(color: scheme.onSurface),
          ),
        ),
        if (library.playlists.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              l10n.libraryPlaylistsEmpty,
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final playlist in library.playlists)
          _CollectionTile(
            icon: Icons.queue_music_rounded,
            title: playlist.name,
            subtitle: l10n.librarySongCount(library.songsOf(playlist).length),
            onTap: () => open(playlist.id),
          ),
        _CollectionTile(
          icon: Icons.add_rounded,
          title: l10n.libraryNewPlaylist,
          onTap: onCreatePlaylist,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Fila de "Tus canciones" o de una playlist: ícono cuadrado del tamaño de
/// las miniaturas de biblioteca (64 px), nombre y cuántas canciones tiene.
class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            SizedBox.square(
              dimension: AppSizes.thumbnailLibrary,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: highlighted
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSizes.thumbnailRadius),
                ),
                child: Icon(
                  icon,
                  color: highlighted
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.trackTitle.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  if (subtitle case final subtitle?) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.trackSubtitle.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
