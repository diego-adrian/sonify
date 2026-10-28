import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/images/cover_cache.dart';
import '../../../../core/theme/app_sizes.dart';

class SongCover extends StatelessWidget {
  const SongCover({
    super.key,
    required this.cover,
    this.size = AppSizes.thumbnailTrack,
    this.circular = false,
  });

  final Uri? cover;
  final double size;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.4,
        color: scheme.onSurfaceVariant,
      ),
    );
    // Decodificar al tamaño mostrado para no gastar RAM.
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    final cover = this.cover;
    final Widget image = switch (cover?.scheme) {
      'asset' => Image.asset(
        cover!.path,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => placeholder,
      ),
      // Con caché en disco: no se vuelve a bajar al abrir la app.
      'http' || 'https' => CachedNetworkImage(
        imageUrl: cover.toString(),
        cacheKey: coverCacheKey(cover!),
        cacheManager: coverCacheManager,
        memCacheHeight: cacheSize,
        fit: BoxFit.cover,
        // Sin animaciones de aparición (y sin parpadeo al cambiar la URL
        // firmada de un día a otro).
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        useOldImageOnUrlChange: true,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
      'file' => Image.file(
        File.fromUri(cover!),
        fit: BoxFit.cover,
        cacheHeight: cacheSize,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => placeholder,
      ),
      _ => placeholder,
    };
    final sized = SizedBox.square(dimension: size, child: image);

    return circular
        ? ClipOval(child: sized)
        : ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.thumbnailRadius),
            child: sized,
          );
  }
}
