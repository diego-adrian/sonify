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
import '../../../core/widgets/visible_center.dart';

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
    final hasCache = (ref.watch(cachedBytesProvider).value ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.downloads, style: AppTypography.appBarTitle),
        actions: [
          if (entries.isNotEmpty)
            TextButton(
              onPressed: _confirmDeleteAll,
              child: Text(l10n.downloadsDeleteAll),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // El pie de la caché ya queda por encima del menú.
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: hasCache,
              child: _list(entries, done, used),
            ),
          ),
          if (hasCache) _cacheFooter(),
        ],
      ),
    );
  }

  Widget _list(
    List<DownloadEntry> entries,
    List<DownloadEntry> done,
    int used,
  ) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return entries.isEmpty
        ? VisibleCenter(
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
                    background: _RemoveBackground(title: entry.song.title),
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
                      onRetry: () => downloadSongs(context, ref, [entry.song]),
                      onRemove: () async {
                        if (await _confirmRemove(entry)) {
                          await ref.read(removeDownloadProvider)(entry.song.id);
                        }
                      },
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) => SizedBox(
                    height: MediaQuery.paddingOf(context).bottom + 16,
                  ),
                ),
              ),
            ],
          );
  }

  /// Qué es la caché de lo escuchado (hasta 300 MB) y cómo vaciarla, justo
  /// encima del menú. Solo si tiene algo.
  Widget _cacheFooter() {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          8,
          MediaQuery.paddingOf(context).bottom + 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                l10n.listeningCacheInfo,
                style: AppTypography.trackSubtitle.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: _confirmClearCache,
              child: Text(l10n.listeningCacheClear),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearCache() async {
    final confirmed = await _confirm(
      AppLocalizations.of(context).listeningCacheClearConfirm,
    );
    if (confirmed) {
      // Lo que suena puede venir de la caché.
      await ref.read(stopPlaybackProvider)();
      await ref.read(clearListeningCacheProvider)();
      ref.invalidate(cachedBytesProvider);
    }
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

/// Fondo rojo al deslizar para borrar: con la fila fuera de la pantalla (y
/// mientras se pide confirmación) sigue diciendo qué canción se va a borrar.
class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return ColoredBox(
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.trackTitle.copyWith(color: onPrimary),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              l10n.delete,
              style: AppTypography.trackSubtitle.copyWith(color: onPrimary),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: onPrimary),
          ],
        ),
      ),
    );
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
    // Mismo estilo de fila que la Home: portada, título, solo el estado y el
    // botón de borrar (en rojo); se reproduce tocando la fila.
    return SongTile(
      song: entry.song,
      subtitle: status,
      subtitleColor: failed ? scheme.error : null,
      onTap: onTap,
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
