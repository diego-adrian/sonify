import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../catalog/domain/song.dart';
import '../../../catalog/presentation/widgets/row_icon_button.dart';
import '../../domain/download_entry.dart';
import '../download_actions.dart';
import '../downloads_providers.dart';

/// Botón de descarga de una fila: muestra el estado y es la forma visible de
/// descargar (la otra es mantener presionada la canción).
class SongDownloadButton extends ConsumerWidget {
  const SongDownloadButton({super.key, required this.song, required this.list});

  final Song song;

  /// Lista de la que forma parte (para "Descargar toda la lista").
  final List<Song> list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Solo esta fila se reconstruye cuando cambia su estado o su avance.
    final state = ref.watch(
      downloadStatesProvider.select((states) => states[song.id]),
    );
    final progress = state == DownloadState.queued
        ? ref.watch(downloadProgressProvider.select((p) => p.value?[song.id]))
        : null;

    final (
      Widget icon,
      String tooltip,
      VoidCallback onPressed,
    ) = switch (state) {
      null => (
        const Icon(Icons.download_rounded, size: 22),
        l10n.downloadSong,
        () => downloadSongs(context, ref, [song]),
      ),
      DownloadState.queued => (
        // Sin avance todavía (en cola o esperando Wi-Fi): ícono fijo, nada de
        // animaciones en bucle.
        progress == null
            ? const Icon(Icons.schedule_rounded, size: 24)
            : SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.5,
                ),
              ),
        l10n.downloadStateQueued,
        () => showSongDownloadSheet(context, ref, song: song, list: list),
      ),
      DownloadState.done => (
        Icon(Icons.download_done_rounded, size: 22, color: scheme.primary),
        l10n.downloadStateDone,
        () => showSongDownloadSheet(context, ref, song: song, list: list),
      ),
      DownloadState.failed => (
        Icon(Icons.error_outline_rounded, size: 22, color: scheme.error),
        l10n.downloadRetry,
        () => downloadSongs(context, ref, [song]),
      ),
    };

    return RowIconButton(tooltip: tooltip, onPressed: onPressed, icon: icon);
  }
}
