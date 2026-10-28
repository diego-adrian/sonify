import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../catalog/domain/song.dart';
import '../../../catalog/presentation/widgets/song_cover.dart';
import '../../../player/domain/playback_snapshot.dart';
import '../../../player/presentation/widgets/playback_progress_bar.dart';
import '../../../../core/theme/app_typography.dart';

/// Portada circular, título, progreso y controles (Figma node 106:97).
class NowPlayingHeader extends StatelessWidget {
  const NowPlayingHeader({
    super.key,
    required this.song,
    required this.isLoaded,
    required this.playing,
    required this.buffering,
    required this.shuffle,
    required this.repeat,
    required this.duration,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onShuffle,
    required this.onRepeat,
    required this.onSeek,
  });

  final Song song;

  /// `true` si [song] es la que está cargada en el reproductor.
  final bool isLoaded;
  final bool playing;
  final bool buffering;
  final bool shuffle;
  final PlaybackRepeat repeat;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coverSize = (MediaQuery.sizeOf(context).width * 0.75).clamp(
      200.0,
      330.0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.onSurface.withValues(
                      alpha: isDark ? 0.0 : 0.12,
                    ),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SongCover(
                cover: song.coverLarge ?? song.cover,
                size: coverSize,
                circular: true,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headline.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            song.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 22),
          PlaybackProgressBar(
            duration: duration,
            enabled: isLoaded,
            playing: playing && !buffering,
            onSeek: onSeek,
          ),
          const SizedBox(height: 18),
          _Controls(
            playing: playing,
            buffering: buffering,
            shuffle: shuffle,
            repeat: repeat,
            onPlayPause: onPlayPause,
            onPrevious: onPrevious,
            onNext: onNext,
            onShuffle: onShuffle,
            onRepeat: onRepeat,
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.playing,
    required this.buffering,
    required this.shuffle,
    required this.repeat,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onShuffle,
    required this.onRepeat,
  });

  final bool playing;
  final bool buffering;
  final bool shuffle;
  final PlaybackRepeat repeat;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundButton(
          icon: Icons.shuffle_rounded,
          tooltip: l10n.shuffle,
          selected: shuffle,
          onPressed: onShuffle,
        ),
        _RoundButton(
          icon: Icons.skip_previous_rounded,
          tooltip: l10n.previous,
          onPressed: onPrevious,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: isDark ? 0.2 : 0.4),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: IconButton(
            tooltip: playing ? l10n.pause : l10n.play,
            onPressed: onPlayPause,
            style: IconButton.styleFrom(
              fixedSize: const Size.square(76),
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
            icon: buffering
                ? SizedBox.square(
                    dimension: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.onPrimary,
                    ),
                  )
                : Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 40,
                  ),
          ),
        ),
        _RoundButton(
          icon: Icons.skip_next_rounded,
          tooltip: l10n.next,
          onPressed: onNext,
        ),
        _RoundButton(
          icon: repeat == PlaybackRepeat.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          tooltip: switch (repeat) {
            PlaybackRepeat.off => l10n.repeatOff,
            PlaybackRepeat.all => l10n.repeatAll,
            PlaybackRepeat.one => l10n.repeatOne,
          },
          selected: repeat != PlaybackRepeat.off,
          onPressed: onRepeat,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      isSelected: selected,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(54),
        backgroundColor: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        foregroundColor: selected ? scheme.primary : scheme.onSurface,
      ),
      icon: Icon(icon, size: 26),
    );
  }
}
