import 'package:flutter/material.dart';

import 'app_typography.dart';

import 'sonify_colors.dart';

abstract final class AppTheme {
  /// Baja todos los estilos de Material a Light/Regular, como el Login.
  static TextTheme _lighten(TextTheme t) {
    TextStyle? light(TextStyle? s) => s?.copyWith(fontWeight: FontWeight.w300);
    TextStyle? regular(TextStyle? s) =>
        s?.copyWith(fontWeight: FontWeight.w400);
    return t.copyWith(
      displayLarge: light(t.displayLarge),
      displayMedium: light(t.displayMedium),
      displaySmall: light(t.displaySmall),
      headlineLarge: light(t.headlineLarge),
      headlineMedium: light(t.headlineMedium),
      headlineSmall: light(t.headlineSmall),
      titleLarge: regular(t.titleLarge),
      titleMedium: regular(t.titleMedium),
      titleSmall: regular(t.titleSmall),
      bodyLarge: light(t.bodyLarge),
      bodyMedium: light(t.bodyMedium),
      bodySmall: light(t.bodySmall),
      labelLarge: regular(t.labelLarge),
      labelMedium: regular(t.labelMedium),
      labelSmall: regular(t.labelSmall),
    );
  }

  static const fontFamily = AppTypography.fontFamily;

  static final ThemeData light = _build(
    brightness: Brightness.light,
    surface: SonifyColors.lightSurface,
    surfaceVariant: SonifyColors.lightSurfaceVariant,
    onSurface: SonifyColors.lightOnSurface,
    onSurfaceVariant: SonifyColors.lightOnSurfaceVariant,
    outline: SonifyColors.lightOutline,
    primaryContainerAlpha: 0.12,
  );

  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    surface: SonifyColors.darkSurface,
    surfaceVariant: SonifyColors.darkSurfaceVariant,
    onSurface: SonifyColors.darkOnSurface,
    onSurfaceVariant: SonifyColors.darkOnSurfaceVariant,
    outline: SonifyColors.darkOutline,
    primaryContainerAlpha: 0.20,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color surface,
    required Color surfaceVariant,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color outline,
    required double primaryContainerAlpha,
  }) {
    final primaryContainer = Color.alphaBlend(
      SonifyColors.primary.withValues(alpha: primaryContainerAlpha),
      surface,
    );
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: SonifyColors.primary,
      onPrimary: SonifyColors.onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: SonifyColors.primary,
      secondary: SonifyColors.primary,
      onSecondary: SonifyColors.onPrimary,
      error: SonifyColors.primary,
      onError: SonifyColors.onPrimary,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outline,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      fontFamily: fontFamily,
    );

    return base.copyWith(textTheme: _lighten(base.textTheme));
  }
}
