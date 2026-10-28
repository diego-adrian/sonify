import '../../../core/result.dart';
import 'app_user.dart';
import 'auth_failure.dart';
import 'auth_provider_type.dart';

/// Puerto de autenticación. Cada proveedor/backend es un adaptador.
abstract interface class AuthRepository {
  /// Emite el usuario actual al suscribirse y luego cada cambio de sesión.
  Stream<AppUser?> authStateChanges();

  Future<Result<AppUser, AuthFailure>> signIn(AuthProviderType provider);

  Future<void> signOut();
}
