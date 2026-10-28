import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

final _onlineStreamProvider = StreamProvider<bool>(
  (ref) => ref.watch(networkStatusProvider).watchOnline().distinct(),
);

/// `false` cuando el sistema avisa que no hay red. Mientras no se sabe, se
/// asume que sí (para no atenuar la lista al arrancar).
final isOnlineProvider = Provider<bool>(
  (ref) => ref.watch(_onlineStreamProvider).value ?? true,
);
