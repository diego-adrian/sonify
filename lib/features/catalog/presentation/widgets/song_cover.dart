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
    this.loading = false,
    this.showProgress = false,
  });

  final Uri? cover;
  final double size;
  final bool circular;

  /// Todavía no se sabe qué portada va: indicador de carga en vez de [cover].
  final bool loading;

  /// Mientras la imagen se lee o se decodifica, indicador de carga en vez de
  /// la nota (que en una portada grande se nota como un parpadeo).
  final bool showProgress;

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
    final progress = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox.square(
          dimension: (size * 0.12).clamp(16.0, 32.0),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: scheme.primary,
          ),
        ),
      ),
    );
    final pending = showProgress ? progress : placeholder;
    // Hasta el primer cuadro decodificado (las imágenes locales también se
    // decodifican de forma asíncrona). En las listas no: ahí un hueco vacío
    // de un cuadro no se nota y la nota sí.
    Widget untilFirstFrame(
      BuildContext _,
      Widget child,
      int? frame,
      bool wasSynchronouslyLoaded,
    ) => frame == null && !wasSynchronouslyLoaded ? pending : child;
    // Decodificar al tamaño mostrado para no gastar RAM.
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    final cover = this.cover;
    final Widget image = loading
        ? progress
        : switch (cover?.scheme) {
            'asset' => Image.asset(
              cover!.path,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              frameBuilder: showProgress ? untilFirstFrame : null,
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
              placeholder: (_, _) => pending,
              errorWidget: (_, _, _) => placeholder,
            ),
            'file' => Image.file(
              File.fromUri(cover!),
              fit: BoxFit.cover,
              cacheHeight: cacheSize,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              frameBuilder: showProgress ? untilFirstFrame : null,
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
