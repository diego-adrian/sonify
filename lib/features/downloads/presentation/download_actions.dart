import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/domain/song.dart';
import '../domain/download_entry.dart';
import '../domain/download_failure.dart';
import 'downloads_providers.dart';

/// Encola [songs] y avisa con un snackbar (cuántas, o si falta espacio).
Future<void> downloadSongs(
  BuildContext context,
  WidgetRef ref,
  List<Song> songs,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final result = await ref.read(downloadSongsProvider)(songs);
  messenger.showSnackBar(
    SnackBar(
      content: Text(switch (result) {
        Ok(:final value) => l10n.downloadQueued(value),
        Err(
          error: NotEnoughSpace(:final requiredBytes, :final availableBytes),
        ) =>
          l10n.downloadNoSpace(
            formatBytes(requiredBytes),
            formatBytes(availableBytes),
          ),
      }),
    ),
  );
}

/// Hoja al mantener presionada una canción: descargarla, descargar toda la
/// lista o quitar la descarga.
Future<void> showSongDownloadSheet(
  BuildContext context,
  WidgetRef ref, {
  required Song song,
  required List<Song> list,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheetContext) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: downloadTiles(
        context,
        ref,
        song: song,
        list: list,
        close: Navigator.of(sheetContext).pop,
      ),
    ),
  ),
);

/// Opciones de descarga de [song] para una hoja (también la de acciones de la
/// biblioteca). [close] cierra la hoja antes de ejecutar la acción.
List<Widget> downloadTiles(
  BuildContext context,
  WidgetRef ref, {
  required Song song,
  required List<Song> list,
  required VoidCallback close,
}) {
  final l10n = AppLocalizations.of(context);
  final state = ref.read(downloadStatesProvider)[song.id];

  void run(Future<void> Function() action) {
    close();
    action();
  }

  return [
    if (state == null || state == DownloadState.failed)
      ListTile(
        leading: Icon(
          state == null
              ? Icons.download_for_offline_outlined
              : Icons.refresh_rounded,
        ),
        title: Text(state == null ? l10n.downloadSong : l10n.downloadRetry),
        onTap: () => run(() => downloadSongs(context, ref, [song])),
      ),
    if (list.length > 1)
      ListTile(
        leading: const Icon(Icons.playlist_add_check_rounded),
        title: Text(l10n.downloadList(list.length)),
        onTap: () => run(() => downloadSongs(context, ref, list)),
      ),
    if (state != null)
      ListTile(
        leading: const Icon(Icons.delete_outline_rounded),
        title: Text(l10n.downloadRemove),
        onTap: () => run(() => ref.read(removeDownloadProvider)(song.id)),
      ),
  ];
}
