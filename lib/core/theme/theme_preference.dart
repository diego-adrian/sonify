import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dónde se guarda el modo elegido a mano (claro u oscuro). Sin elección, la
/// app sigue al sistema.
abstract interface class ThemePreference {
  Future<ThemeMode> load();

  Future<void> save(ThemeMode mode);
}

/// En las preferencias del dispositivo (no es un dato sensible).
final class SharedPreferencesThemePreference implements ThemePreference {
  SharedPreferencesThemePreference([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'sonify.theme_mode';

  final SharedPreferencesAsync _preferences;

  @override
  Future<ThemeMode> load() async {
    try {
      return switch (await _preferences.getString(_key)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } on Exception catch (error) {
      debugPrint('Tema: no se pudo leer ($error)');
      return ThemeMode.system;
    }
  }

  @override
  Future<void> save(ThemeMode mode) async {
    try {
      mode == ThemeMode.system
          ? await _preferences.remove(_key)
          : await _preferences.setString(_key, mode.name);
    } on Exception catch (error) {
      debugPrint('Tema: no se pudo guardar ($error)');
    }
  }
}
