import 'dart:io';

import 'package:flutter/material.dart';

class SongCover extends StatelessWidget {
  const SongCover({
    super.key,
    required this.cover,
    this.size = 60,
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
      'http' || 'https' => Image.network(
        cover.toString(),
        fit: BoxFit.cover,
        cacheHeight: cacheSize,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => placeholder,
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
        : ClipRRect(borderRadius: BorderRadius.circular(10), child: sized);
  }
}
