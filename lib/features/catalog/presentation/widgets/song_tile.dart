import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/song.dart';
import 'now_playing_bars.dart';
import 'row_icon_button.dart';
import 'song_cover.dart';

/// Fila de pista (Figma node 106:97). La usan la Home, Buscar, la biblioteca
/// y Descargas.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.actionTooltip,
    this.onAction,
    this.onLongPress,
    this.secondaryAction,
    this.enabled = true,
    this.locked = false,
    this.nowPlaying = false,
    this.subtitle,
    this.subtitleColor,
  });

  /// Alto fijo: permite listas de extensión fija (scroll más barato).
  static const height = AppSizes.trackRowHeight;

  final Song song;

  /// Tooltip del botón de reproducir; `null` = la fila no lleva ese botón
  /// (p. ej. Descargas, donde se reproduce tocando la fila).
  final String? actionTooltip;

  /// `null` = no se puede reproducir todavía (p. ej. una descarga en curso),
  /// sin atenuar la fila.
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final VoidCallback? onLongPress;

  /// Segunda línea; por defecto el artista.
  final String? subtitle;
  final Color? subtitleColor;

  /// Botón opcional a la izquierda del de reproducir (p. ej. descargar), o
  /// al final de la fila si no hay botón de reproducir.
  final Widget? secondaryAction;

  /// `false` sin red para una canción no descargada: se ve atenuada y no se
  /// puede reproducir (descargar y mantener presionado siguen activos).
  final bool enabled;

  /// Cuenta gratis y canción no guardada: se ve atenuada con un candado en
  /// lugar de ▷, pero tocarla sigue funcionando (ofrece guardarla).
  final bool locked;

  /// Es la que está sonando: en lugar de ▷ se ve una onda animada en
  /// `tertiary`.
  final bool nowPlaying;

  static const _disabledOpacity = RowIconButton.disabledOpacity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dimmed = !enabled || locked;

    return InkWell(
      onTap: enabled ? onTap : null,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outline)),
          ),
          child: Row(
            children: [
              _Dimmed(
                enabled: !dimmed,
                child: SongCover(cover: song.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Dimmed(
                  enabled: !dimmed,
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle ?? song.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.trackSubtitle.copyWith(
                          color: subtitleColor ?? scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ?secondaryAction,
              if (actionTooltip case final tooltip?) ...[
                if (secondaryAction != null) const SizedBox(width: 10),
                RowIconButton(
                  tooltip: tooltip,
                  onPressed: enabled ? onAction : null,
                  color: nowPlaying ? scheme.tertiary : scheme.primary,
                  icon: nowPlaying
                      ? NowPlayingBars(color: scheme.tertiary, size: 18)
                      : Icon(
                          locked
                              ? Icons.lock_outline_rounded
                              : Icons.play_arrow_outlined,
                          size: locked ? 20 : 24,
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Dimmed extends StatelessWidget {
  const _Dimmed({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) => enabled
      ? child
      : Opacity(opacity: SongTile._disabledOpacity, child: child);
}
