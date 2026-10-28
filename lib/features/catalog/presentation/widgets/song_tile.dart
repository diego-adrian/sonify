import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/song.dart';
import 'row_icon_button.dart';
import 'song_cover.dart';

/// Fila de pista (Figma node 106:97). La usan la Home y Descargas.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.actionTooltip,
    required this.onTap,
    required this.onAction,
    this.onLongPress,
    this.secondaryAction,
    this.enabled = true,
    this.subtitle,
    this.subtitleColor,
  });

  /// Alto fijo: permite listas de extensión fija (scroll más barato).
  static const height = AppSizes.trackRowHeight;

  final Song song;
  final String actionTooltip;

  /// `null` = no se puede reproducir todavía (p. ej. una descarga en curso),
  /// sin atenuar la fila.
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final VoidCallback? onLongPress;

  /// Segunda línea; por defecto el artista.
  final String? subtitle;
  final Color? subtitleColor;

  /// Botón opcional a la izquierda del de reproducir (p. ej. descargar).
  final Widget? secondaryAction;

  /// `false` sin red para una canción no descargada: se ve atenuada y no se
  /// puede reproducir (descargar y mantener presionado siguen activos).
  final bool enabled;

  static const _disabledOpacity = RowIconButton.disabledOpacity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                enabled: enabled,
                child: SongCover(cover: song.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Dimmed(
                  enabled: enabled,
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
              if (secondaryAction != null) const SizedBox(width: 10),
              RowIconButton(
                tooltip: actionTooltip,
                onPressed: enabled ? onAction : null,
                color: scheme.primary,
                icon: const Icon(Icons.play_arrow_outlined, size: 24),
              ),
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
