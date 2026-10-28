import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/result.dart';
import '../domain/app_user.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_provider_type.dart';

final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, AsyncValue<void>>(
      LoginController.new,
    );

class LoginController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn(AuthProviderType provider) async {
    if (state.isLoading) return;
    state = const AsyncLoading();

    final Result<AppUser, AuthFailure> result;
    try {
      result = await ref.read(signInProvider)(provider);
    } on Object catch (error, stackTrace) {
      // Nunca dejar el botón cargando: cualquier fallo inesperado
      // (p. ej. configuración ausente) se muestra como error.
      if (ref.mounted) state = AsyncError(AuthFailure.unknown, stackTrace);
      debugPrint('Login falló: $error');
      return;
    }
    if (!ref.mounted) return;

    state = switch (result) {
      Ok() || Err(error: AuthFailure.cancelled) => const AsyncData(null),
      Err(:final error) => AsyncError(error, StackTrace.current),
    };
  }
}
