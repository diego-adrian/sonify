import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/domain/song.dart';
import '../../downloads/presentation/download_actions.dart';
import '../../shell/presentation/shell_providers.dart';
import '../application/library_use_cases.dart';
import '../domain/library_repository.dart';
import 'library_providers.dart';

/// Avisa con un snackbar cómo terminó un cambio de la biblioteca. Si se llenó
/// el cupo, ofrece ir a Premium.
void showLibraryResult(
  BuildContext context,
  WidgetRef ref,
  LibraryFailure? failure, {
  String? success,
}) {
  final l10n = AppLocalizations.of(context);
  final limit = ref.read(accountProvider).libraryLimit ?? 0;
  final text = switch (failure) {
    null => success,
    LibraryFailure.limitReached => l10n.libraryErrorLimit(limit),
    LibraryFailure.network => l10n.libraryErrorNetwork,
    LibraryFailure.invalidName => l10n.libraryErrorName,
    LibraryFailure.unknown => l10n.libraryErrorUnknown,
  };
  if (text == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        action: failure == LibraryFailure.limitReached
            ? SnackBarAction(
                label: l10n.seePremium,
                onPressed: () => ref
                    .read(shellTabProvider.notifier)
                    .select(ShellTab.premium),
              )
            : null,
      ),
    );
}

/// Guarda [song] o la quita de la biblioteca.
Future<LibraryFailure?> toggleSaved(
  BuildContext context,
  WidgetRef ref,
  Song song,
) async {
  final l10n = AppLocalizations.of(context);
  final notifier = ref.read(libraryProvider.notifier);
  final saved = ref.read(currentLibraryProvider).contains(song.id);
  final failure = saved
      ? await notifier.remove(song.id)
      : await notifier.save(song.id);
  if (context.mounted) {
    showLibraryResult(
      context,
      ref,
      failure,
      success: saved ? l10n.songUnsaved : l10n.songSaved,
    );
  }
  return failure;
}

/// Hoja al mantener presionada una canción: biblioteca, playlists y
/// descargas. [playlistId] = se abrió desde esa playlist (permite quitarla).
Future<void> showSongActionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required Song song,
  required List<Song> list,
  String? playlistId,
}) {
  final l10n = AppLocalizations.of(context);
  final library = ref.read(currentLibraryProvider);
  final access = ref.read(songAccessProvider);
  final saved = library.contains(song.id);
  final remaining = library.remaining;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      void close() => Navigator.of(sheetContext).pop();

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                saved
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
              ),
              title: Text(saved ? l10n.songUnsave : l10n.songSave),
              subtitle: !saved && remaining != null
                  ? Text(
                      l10n.libraryRemaining(
                        remaining,
                        library.account.libraryLimit!,
                      ),
                    )
                  : null,
              onTap: () {
                close();
                toggleSaved(context, ref, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: Text(l10n.songAddToPlaylist),
              onTap: () {
                close();
                showAddToPlaylistSheet(context, ref, song);
              },
            ),
            if (playlistId != null)
              ListTile(
                leading: const Icon(Icons.playlist_remove_rounded),
                title: Text(l10n.songRemoveFromPlaylist),
                onTap: () async {
                  close();
                  final failure = await ref
                      .read(libraryProvider.notifier)
                      .removeFromPlaylist(playlistId, song.id);
                  if (context.mounted) showLibraryResult(context, ref, failure);
                },
              ),
            // Descargar solo lo que se puede escuchar.
            if (access.canPlay(song))
              ...downloadTiles(
                context,
                ref,
                song: song,
                list: [
                  for (final item in list)
                    if (access.canPlay(item)) item,
                ],
                close: close,
              ),
          ],
        ),
      );
    },
  );
}

/// Elige una playlist (o crea una) y agrega [song].
Future<void> showAddToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  Song song,
) {
  final l10n = AppLocalizations.of(context);
  final playlists = ref.read(currentLibraryProvider).playlists;

  Future<void> add(String playlistId, String name) async {
    final failure = await ref
        .read(libraryProvider.notifier)
        .addToPlaylist(playlistId, song.id);
    if (context.mounted) {
      showLibraryResult(
        context,
        ref,
        failure,
        success: l10n.songAddedToPlaylist(name),
      );
    }
  }

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: Text(l10n.libraryNewPlaylist),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final name = await showPlaylistNameDialog(
                  context,
                  title: l10n.libraryNewPlaylist,
                  action: l10n.playlistCreate,
                );
                if (name == null || !context.mounted) return;
                final notifier = ref.read(libraryProvider.notifier);
                final failure = await notifier.createPlaylist(name);
                if (!context.mounted) return;
                if (failure != null) {
                  showLibraryResult(context, ref, failure);
                  return;
                }
                // La recién creada es la última (orden de creación).
                final created = ref
                    .read(currentLibraryProvider)
                    .playlists
                    .lastOrNull;
                if (created != null) await add(created.id, created.name);
              },
            ),
            for (final playlist in playlists)
              ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                enabled: !playlist.songIds.contains(song.id),
                trailing: playlist.songIds.contains(song.id)
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  add(playlist.id, playlist.name);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// Pide el nombre de una playlist. `null` si se cancela.
Future<String?> showPlaylistNameDialog(
  BuildContext context, {
  required String title,
  required String action,
  String initial = '',
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _PlaylistNameDialog(title: title, action: action, initial: initial),
);

class _PlaylistNameDialog extends StatefulWidget {
  const _PlaylistNameDialog({
    required this.title,
    required this.action,
    required this.initial,
  });

  final String title;
  final String action;
  final String initial;

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.title, style: AppTypography.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: maxPlaylistNameLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l10n.playlistName),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => TextButton(
            onPressed: _controller.text.trim().isEmpty ? null : _submit,
            child: Text(widget.action),
          ),
        ),
      ],
    );
  }
}

/// Cuenta gratis y canción no guardada: explica el límite y ofrece guardarla
/// (si queda lugar) o ir a Premium. [onSaved] recibe la canción ya guardada,
/// con su audio firmado, para reproducirla.
Future<void> showLockedSongSheet(
  BuildContext context,
  WidgetRef ref, {
  required Song song,
  ValueChanged<Song>? onSaved,
}) {
  final l10n = AppLocalizations.of(context);
  final library = ref.read(currentLibraryProvider);
  final limit = library.account.libraryLimit ?? 0;
  final full = library.isFull;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.lockedTitle, style: AppTypography.title),
              const SizedBox(height: 8),
              Text(
                full ? l10n.lockedFull(limit) : l10n.lockedBody(limit),
                style: AppTypography.body.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (!full) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.libraryRemaining(library.remaining ?? 0, limit),
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (!full)
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    final failure = await ref
                        .read(libraryProvider.notifier)
                        .save(song.id);
                    if (!context.mounted) return;
                    showLibraryResult(
                      context,
                      ref,
                      failure,
                      success: l10n.songSaved,
                    );
                    final saved = ref
                        .read(currentLibraryProvider)
                        .song(song.id);
                    if (failure == null && saved != null) onSaved?.call(saved);
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: Text(l10n.songSave),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  ref.read(shellTabProvider.notifier).select(ShellTab.premium);
                },
                child: Text(l10n.seePremium),
              ),
            ],
          ),
        ),
      );
    },
  );
}
