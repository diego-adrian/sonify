import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/presentation/widgets/song_cover.dart';
import '../domain/download_entry.dart';
import 'download_actions.dart';
import 'downloads_providers.dart';

/// Lo que se puede escuchar sin señal. Funciona sin red: lee de Drift.
class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  static const _rowHeight = 80.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final entries = ref.watch(downloadsProvider).value ?? const [];
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
              onPressed: () => _confirmDeleteAll(context, ref),
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
                    return _DownloadTile(
                      entry: entry,
                      onTap: entry.state == DownloadState.done
                          ? () => ref.read(playSongsProvider)([
                              for (final e in done) e.song,
                            ], entry.song)
                          : null,
                      onRetry: () => downloadSongs(context, ref, [entry.song]),
                      onRemove: () =>
                          ref.read(removeDownloadProvider)(entry.song.id),
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

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.downloadsDeleteAllConfirm),
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
    if (confirmed ?? false) {
      await ref.read(stopPlaybackProvider)();
      await ref.read(clearDownloadsProvider)();
    }
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

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            SongCover(cover: entry.song.cover, size: 52),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.song.artistName} · $status',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: entry.state == DownloadState.failed
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (entry.state == DownloadState.failed)
              IconButton(
                tooltip: l10n.downloadRetry,
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
            IconButton(
              tooltip: l10n.downloadRemove,
              onPressed: onRemove,
              // Sin avance todavía (en cola o esperando Wi-Fi): ícono fijo,
              // nada de animaciones en bucle.
              icon: entry.state == DownloadState.queued && progress == null
                  ? const Icon(Icons.schedule_rounded)
                  : entry.state == DownloadState.queued
                  ? SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
