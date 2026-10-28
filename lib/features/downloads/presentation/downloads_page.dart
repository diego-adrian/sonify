import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/presentation/widgets/row_icon_button.dart';
import '../../catalog/presentation/widgets/song_tile.dart';
import '../domain/download_entry.dart';
import 'download_actions.dart';
import 'downloads_providers.dart';

/// Lo que se puede escuchar sin señal. Funciona sin red: lee de Drift.
class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  static const _rowHeight = AppSizes.trackRowHeight;

  /// Filas quitadas con el gesto: se ocultan ya, porque un `Dismissible`
  /// descartado no puede seguir en el árbol mientras Drift avisa del borrado.
  final _dismissed = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final all = ref.watch(downloadsProvider).value ?? const <DownloadEntry>[];
    _dismissed.retainWhere((id) => all.any((e) => e.song.id == id));
    final entries = [
      for (final entry in all)
        if (!_dismissed.contains(entry.song.id)) entry,
    ];
    final done = [
      for (final entry in entries)
        if (entry.state == DownloadState.done) entry,
    ];
    final used = done.fold<int>(0, (sum, e) => sum + (e.sizeBytes ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.downloads, style: AppTypography.title),
        actions: [
          if (entries.isNotEmpty)
            TextButton(
              onPressed: _confirmDeleteAll,
              child: Text(l10n.downloadsDeleteAll),
            ),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.downloadsEmpty,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(
                      l10n.downloadsSummary(done.length, formatBytes(used)),
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                SliverFixedExtentList.builder(
                  itemExtent: _rowHeight,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Dismissible(
                      key: ValueKey(entry.song.id),
                      direction: DismissDirection.endToStart,
                      background: ColoredBox(
                        color: scheme.primary,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 28),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      confirmDismiss: (_) => _confirmRemove(entry),
                      onDismissed: (_) {
                        setState(() => _dismissed.add(entry.song.id));
                        ref.read(removeDownloadProvider)(entry.song.id);
                      },
                      child: _DownloadTile(
                        entry: entry,
                        onTap: entry.state == DownloadState.done
                            ? () => ref.read(playSongsProvider)([
                                for (final e in done) e.song,
                              ], entry.song)
                            : null,
                        onRetry: () =>
                            downloadSongs(context, ref, [entry.song]),
                        onRemove: () async {
                          if (await _confirmRemove(entry)) {
                            await ref.read(removeDownloadProvider)(
                              entry.song.id,
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.paddingOf(context).bottom + 16,
                  ),
                ),
              ],
            ),
    );
  }

  /// Igual al tocar la papelera o al deslizar la fila.
  Future<bool> _confirmRemove(DownloadEntry entry) => _confirm(
    AppLocalizations.of(context).downloadRemoveConfirm(entry.song.title),
  );

  Future<void> _confirmDeleteAll() async {
    final confirmed = await _confirm(
      AppLocalizations.of(context).downloadsDeleteAllConfirm,
    );
    if (confirmed) {
      await ref.read(stopPlaybackProvider)();
      await ref.read(clearDownloadsProvider)();
    }
  }

  Future<bool> _confirm(String message) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
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
    return confirmed ?? false;
  }
}

class _DownloadTile extends ConsumerWidget {
  const _DownloadTile({
    required this.entry,
    required this.onTap,
    required this.onRetry,
    required this.onRemove,
  });

  final DownloadEntry entry;
  final VoidCallback? onTap;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final id = entry.song.id;
    // Solo esta fila se reconstruye cuando cambia su avance.
    final progress = entry.state == DownloadState.queued
        ? ref.watch(downloadProgressProvider.select((p) => p.value?[id]))
        : null;

    final status = switch (entry.state) {
      DownloadState.done =>
        '${l10n.downloadStateDone} · '
            '${formatBytes(entry.sizeBytes ?? 0)}',
      DownloadState.queued when progress != null => l10n.downloadProgress(
        (progress * 100).floor(),
      ),
      DownloadState.queued => l10n.downloadStateQueued,
      DownloadState.failed => l10n.downloadStateFailed,
    };

    final failed = entry.state == DownloadState.failed;
    // Mismo estilo de fila que la Home: portada, título, artista + estado y
    // botones redondos (borrar en rojo y reproducir).
    return SongTile(
      song: entry.song,
      subtitle: '${entry.song.artistName} · $status',
      subtitleColor: failed ? scheme.error : null,
      actionTooltip: l10n.playSong(entry.song.title),
      onTap: onTap,
      onAction: onTap,
      secondaryAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failed) ...[
            RowIconButton(
              tooltip: l10n.downloadRetry,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 22),
            ),
            const SizedBox(width: 10),
          ],
          RowIconButton(
            tooltip: l10n.downloadRemove,
            onPressed: onRemove,
            // Sin avance todavía (en cola o esperando Wi-Fi): ícono fijo,
            // nada de animaciones en bucle.
            icon: switch (entry.state) {
              DownloadState.queued when progress == null => const Icon(
                Icons.schedule_rounded,
                size: 22,
              ),
              DownloadState.queued => SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.5,
                ),
              ),
              _ => Icon(
                Icons.delete_outline_rounded,
                size: 22,
                color: scheme.primary,
              ),
            },
          ),
        ],
      ),
    );
  }
}
