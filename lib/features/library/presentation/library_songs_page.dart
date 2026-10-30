import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/network/online_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/domain/song.dart';
import '../../catalog/presentation/widgets/song_tile.dart';
import '../../downloads/presentation/widgets/song_download_button.dart';
import 'library_actions.dart';
import 'library_providers.dart';
import '../../../core/widgets/visible_center.dart';

/// Canciones de "Tus canciones" ([playlistId] nulo) o de una playlist.
class LibrarySongsPage extends ConsumerWidget {
  const LibrarySongsPage({super.key, this.playlistId});

  final String? playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final library = ref.watch(currentLibraryProvider);
    final access = ref.watch(songAccessProvider);
    final online = ref.watch(isOnlineProvider);
    final playlist = playlistId == null ? null : library.playlist(playlistId!);

    // La playlist se borró (aquí o en otro dispositivo).
    if (playlistId != null && playlist == null) {
      return Scaffold(appBar: AppBar());
    }

    final songs = playlist == null ? library.songs : library.songsOf(playlist);
    bool available(Song song) =>
        access.canPlay(song) && (online || access.local.contains(song.id));
    final queue = [
      for (final song in songs)
        if (available(song)) song,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          playlist?.name ?? l10n.librarySavedSongs,
          style: AppTypography.title,
        ),
        actions: [
          if (playlist != null)
            PopupMenuButton<_PlaylistAction>(
              tooltip: l10n.playlistMore,
              onSelected: (action) => switch (action) {
                _PlaylistAction.rename => _rename(
                  context,
                  ref,
                  playlist.id,
                  playlist.name,
                ),
                _PlaylistAction.delete => _delete(
                  context,
                  ref,
                  playlist.id,
                  playlist.name,
                ),
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _PlaylistAction.rename,
                  child: Text(l10n.playlistRename),
                ),
                PopupMenuItem(
                  value: _PlaylistAction.delete,
                  child: Text(l10n.playlistDelete),
                ),
              ],
            ),
        ],
      ),
      body: songs.isEmpty
          ? VisibleCenter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  playlist == null
                      ? l10n.librarySongsEmpty
                      : l10n.libraryPlaylistEmpty,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView.builder(
              itemExtent: SongTile.height,
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final enabled = available(song);
                Future<void> play() => ref.read(playSongsProvider)(queue, song);
                return SongTile(
                  song: song,
                  enabled: enabled,
                  actionTooltip: enabled
                      ? l10n.playSong(song.title)
                      : l10n.songNeedsConnection,
                  onTap: play,
                  onAction: play,
                  secondaryAction: SongDownloadButton(song: song, list: queue),
                  onLongPress: () => showSongActionsSheet(
                    context,
                    ref,
                    song: song,
                    list: songs,
                    playlistId: playlistId,
                  ),
                );
              },
            ),
    );
  }

  static Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    String id,
    String current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final name = await showPlaylistNameDialog(
      context,
      title: l10n.playlistRename,
      action: l10n.playlistSave,
      initial: current,
    );
    if (name == null || name == current || !context.mounted) return;
    final failure = await ref
        .read(libraryProvider.notifier)
        .renamePlaylist(id, name);
    if (context.mounted) showLibraryResult(context, ref, failure);
  }

  static Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.playlistDeleteConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final failure = await ref.read(libraryProvider.notifier).deletePlaylist(id);
    if (!context.mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      showLibraryResult(context, ref, failure);
    }
  }
}

enum _PlaylistAction { rename, delete }
