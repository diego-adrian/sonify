import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result.dart';
import '../domain/app_user.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_provider_type.dart';
import '../domain/auth_repository.dart';
import 'supabase_user_mapper.dart';

/// Supabase Auth con login nativo de Google (`signInWithIdToken`).
///
/// La sesión queda guardada en el dispositivo, así que la app arranca y
/// reconoce al usuario sin conexión.
final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required this._auth,
    required this._googleSignIn,
    required this.googleIosClientId,
    required this.googleWebClientId,
  });

  final GoTrueClient _auth;
  final GoogleSignIn _googleSignIn;
  final String googleIosClientId;
  final String googleWebClientId;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser();
    yield* _auth.onAuthStateChange
        .map((state) => _mapUser(state.session?.user))
        // Supabase emite como error que no pudo renovar el token (p. ej. sin
        // red al volver a la app). La sesión guardada sigue valiendo; si de
        // verdad venció, llega como `signedOut`.
        .handleError((Object error) => debugPrint('Sesión sin renovar: $error'))
        .distinct();
  }

  @override
  Future<Result<AppUser, AuthFailure>> signIn(AuthProviderType provider) {
    return switch (provider) {
      AuthProviderType.google => _signInWithGoogle(),
    };
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } on Object catch (error) {
      // No impide cerrar la sesión de Sonify.
      debugPrint('Google signOut falló: $error');
    }
  }

  Future<Result<AppUser, AuthFailure>> _signInWithGoogle() async {
    try {
      // Nonce nuevo en cada intento: Supabase comprueba que el ID token de
      // Google se emitió para esta petición.
      final rawNonce = _auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      await _googleSignIn.initialize(
        clientId: Platform.isIOS ? googleIosClientId : null,
        serverClientId: googleWebClientId,
        nonce: hashedNonce,
      );
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return const Err(AuthFailure.unknown);

      final response = await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        nonce: rawNonce,
      );
      final user = response.user;
      if (user == null) return const Err(AuthFailure.unknown);
      return Ok(appUserFromSupabase(user));
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const Err(AuthFailure.cancelled);
      }
      debugPrint('Google sign-in: ${error.code} ${error.description}');
      return const Err(AuthFailure.unknown);
    } on AuthRetryableFetchException {
      return const Err(AuthFailure.network);
    } on SocketException {
      return const Err(AuthFailure.network);
    } on AuthException catch (error) {
      debugPrint('Supabase auth: ${error.code} ${error.message}');
      return const Err(AuthFailure.unknown);
    }
  }

  AppUser? _currentUser() => _mapUser(_auth.currentSession?.user);

  AppUser? _mapUser(User? user) =>
      user == null ? null : appUserFromSupabase(user);
}
