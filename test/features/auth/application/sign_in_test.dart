import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/result.dart';
import 'package:sonify/features/auth/application/sign_in.dart';
import 'package:sonify/features/auth/domain/app_user.dart';
import 'package:sonify/features/auth/domain/auth_failure.dart';
import 'package:sonify/features/auth/domain/auth_provider_type.dart';
import 'package:sonify/features/auth/domain/auth_repository.dart';

class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository(this.result);

  final Result<AppUser, AuthFailure> result;
  AuthProviderType? requestedProvider;

  @override
  Stream<AppUser?> authStateChanges() => const Stream.empty();

  @override
  Future<Result<AppUser, AuthFailure>> signIn(AuthProviderType provider) async {
    requestedProvider = provider;
    return result;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  const user = AppUser(id: 'u1', displayName: 'Cinthia');

  test('delega en el puerto con el proveedor pedido', () async {
    final repository = _StubAuthRepository(const Ok(user));

    final result = await SignIn(repository)(AuthProviderType.google);

    expect(repository.requestedProvider, AuthProviderType.google);
    expect(result, isA<Ok<AppUser, AuthFailure>>());
    expect((result as Ok<AppUser, AuthFailure>).value, user);
  });

  test('propaga el fallo del adaptador', () async {
    final repository = _StubAuthRepository(const Err(AuthFailure.network));

    final result = await SignIn(repository)(AuthProviderType.google);

    expect((result as Err<AppUser, AuthFailure>).error, AuthFailure.network);
  });
}
