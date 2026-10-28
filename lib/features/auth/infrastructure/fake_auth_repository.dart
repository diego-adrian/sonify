import 'dart:async';

import '../../../core/result.dart';
import '../domain/app_user.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_provider_type.dart';
import '../domain/auth_repository.dart';

/// Adaptador temporal para desarrollo hasta conectar Supabase Auth.
/// No usar en producción.
final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;
  final _changes = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  static const _devUser = AppUser(
    id: '00000000-0000-0000-0000-000000000001',
    displayName: 'Artista',
  );

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _changes.stream;
  }

  @override
  Future<Result<AppUser, AuthFailure>> signIn(AuthProviderType provider) async {
    await Future<void>.delayed(latency);
    _current = _devUser;
    _changes.add(_current);
    return const Ok(_devUser);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _changes.add(null);
  }

  void dispose() => _changes.close();
}
