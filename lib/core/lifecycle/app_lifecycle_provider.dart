import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true` mientras la app está en primer plano. Sirve para cortar trabajo de
/// UI (p. ej. la posición del reproductor) con la pantalla apagada o la app
/// en segundo plano: el audio sigue, la UI no gasta batería.
final appResumedProvider = NotifierProvider<AppResumed, bool>(AppResumed.new);

class AppResumed extends Notifier<bool> {
  @override
  bool build() {
    final listener = AppLifecycleListener(
      onStateChange: (lifecycle) =>
          state = lifecycle == AppLifecycleState.resumed,
    );
    ref.onDispose(listener.dispose);
    final current = WidgetsBinding.instance.lifecycleState;
    return current == null || current == AppLifecycleState.resumed;
  }
}
