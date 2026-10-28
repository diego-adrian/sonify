import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/di/providers.dart';
import 'package:sonify/features/auth/domain/auth_failure.dart';
import 'package:sonify/features/auth/domain/auth_provider_type.dart';
import 'package:sonify/features/auth/presentation/login_controller.dart';

void main() {
  test('un fallo inesperado no deja el login cargando', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith(
          (ref) => throw StateError('Falta la configuración'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(loginControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    await container
        .read(loginControllerProvider.notifier)
        .signIn(AuthProviderType.google);

    final state = container.read(loginControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, AuthFailure.unknown);
  });
}
