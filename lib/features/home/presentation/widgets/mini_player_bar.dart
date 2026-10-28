import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../catalog/domain/song.dart';
import '../../../catalog/presentation/widgets/song_cover.dart';

/// Reproductor compacto que queda pegado arriba cuando el grande sale de la
/// vista al bajar por la lista. Sin barra de progreso: no suma otro reloj.
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({
    super.key,
    required this.song,
    required this.playing,
    required this.buffering,
    required this.onTap,
    required this.onPlayPause,
    required this.onNext,
  });

  /// Alto total, margen incluido (para saber cuándo tapa al grande).
  static const height = 64.0;

  final Song song;
  final bool playing;
  final bool buffering;

  /// Vuelve al reproductor grande.
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: Material(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: height - 12,
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  SongCover(cover: song.cover, size: AppSizes.thumbnailMini),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      button: true,
                      hint: l10n.showPlayer,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.trackTitle.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            song.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.trackSubtitle.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: playing ? l10n.pause : l10n.play,
                    onPressed: onPlayPause,
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(40),
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                    ),
                    icon: buffering
                        ? SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 26,
                          ),
                  ),
                  IconButton(
                    tooltip: l10n.next,
                    onPressed: onNext,
                    color: scheme.onSurface,
                    icon: const Icon(Icons.skip_next_rounded, size: 28),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
