import '../../../core/result.dart';
import '../domain/app_user.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_provider_type.dart';
import '../domain/auth_repository.dart';

final class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser, AuthFailure>> call(AuthProviderType provider) =>
      _repository.signIn(provider);
}
