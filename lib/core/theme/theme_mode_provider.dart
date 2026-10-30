import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

/// El modo guardado, leído en `main` antes del primer cuadro (así no se ve
/// un cuadro con el tema equivocado). Por defecto, el del sistema.
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(initialThemeModeProvider);

  /// Pasa al modo contrario del que se ve ahora ([shown]) y lo recuerda.
  Future<void> toggle(Brightness shown) async {
    state = shown == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    await ref.read(themePreferenceProvider).save(state);
  }
}
