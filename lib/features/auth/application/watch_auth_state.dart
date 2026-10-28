import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

final class WatchAuthState {
  const WatchAuthState(this._repository);

  final AuthRepository _repository;

  Stream<AppUser?> call() => _repository.authStateChanges();
}
