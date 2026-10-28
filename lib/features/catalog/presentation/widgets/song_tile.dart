import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../downloads/domain/download_entry.dart';
import '../../domain/song.dart';
import 'song_cover.dart';

enum SongTileAction { play, queue }

/// Fila de pista (Figma node 106:97).
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.action,
    required this.actionTooltip,
    required this.onTap,
    required this.onAction,
    this.onLongPress,
    this.downloadState,
  });

  /// Alto fijo: permite listas de extensión fija (scroll más barato).
  static const height = 92.0;

  final Song song;
  final SongTileAction action;
  final String actionTooltip;
  final VoidCallback onTap;
  final VoidCallback onAction;
  final VoidCallback? onLongPress;

  /// Marca junto al artista si la canción está descargada o bajando.
  final DownloadState? downloadState;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outline)),
          ),
          child: Row(
            children: [
              SongCover(cover: song.cover),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (downloadState case final state?) ...[
                          Icon(
                            switch (state) {
                              DownloadState.done => Icons.download_done_rounded,
                              DownloadState.queued => Icons.downloading_rounded,
                              DownloadState.failed =>
                                Icons.error_outline_rounded,
                            },
                            size: 16,
                            color: state == DownloadState.done
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            song.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: actionTooltip,
                onPressed: onAction,
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(52),
                  backgroundColor: scheme.surface,
                  foregroundColor: action == SongTileAction.play
                      ? scheme.primary
                      : scheme.onSurface,
                  side: BorderSide(color: scheme.outline),
                ),
                icon: Icon(switch (action) {
                  SongTileAction.play => Icons.play_arrow_outlined,
                  SongTileAction.queue => Icons.drag_handle_rounded,
                }, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
