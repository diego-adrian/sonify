import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

/// Pestañas del menú inferior, en orden.
enum ShellTab { home, search, library, premium, downloads }

/// Pestaña visible. Cualquier pantalla puede cambiarla (p. ej. "Ver Premium").
final shellTabProvider = NotifierProvider<ShellTabNotifier, ShellTab>(
  ShellTabNotifier.new,
);

class ShellTabNotifier extends Notifier<ShellTab> {
  /// Cada sesión empieza en Inicio.
  @override
  ShellTab build() {
    ref.watch(currentUserIdProvider);
    return ShellTab.home;
  }

  void select(ShellTab tab) => state = tab;
}
