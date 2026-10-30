import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/app.dart';
import 'package:sonify/core/di/providers.dart';
import 'package:sonify/core/result.dart';
import 'package:sonify/features/auth/domain/app_user.dart';
import 'package:sonify/features/auth/domain/auth_failure.dart';
import 'package:sonify/features/auth/domain/auth_provider_type.dart';
import 'package:sonify/features/auth/domain/auth_repository.dart';
import 'package:sonify/features/auth/presentation/login_page.dart';
import 'package:sonify/features/shell/presentation/main_shell.dart';

import '../../../helpers/fake_audio_player.dart';
import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/fake_download_repository.dart';
import '../../../helpers/fake_library_repository.dart';
import '../../../helpers/fake_network_status.dart';

/// Sesión guardada cuyo flujo puede fallar, como Supabase al no poder
/// renovar el token sin red.
final class _FlakyAuthRepository implements AuthRepository {
  final _changes = StreamController<AppUser?>.broadcast();

  static const user = AppUser(id: 'user-1', displayName: 'Artista');

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield user;
    yield* _changes.stream;
  }

  void fail(Object error) => _changes.addError(error);

  @override
  Future<Result<AppUser, AuthFailure>> signIn(AuthProviderType provider) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async => _changes.add(null);

  void dispose() => _changes.close();
}

void main() {
  testWidgets('un error del flujo de sesión no saca al usuario de la app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    addTearDown(tester.view.reset);

    final auth = _FlakyAuthRepository();
    final player = FakeAudioPlayer();
    final downloads = FakeDownloadRepository();
    addTearDown(() async {
      auth.dispose();
      await player.dispose();
      await downloads.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          audioPlayerProvider.overrideWithValue(player),
          downloadRepositoryProvider.overrideWithValue(downloads),
          libraryRepositoryProvider.overrideWithValue(FakeLibraryRepository()),
          networkStatusProvider.overrideWithValue(FakeNetworkStatus()),
          catalogRepositoryProvider.overrideWithValue(
            const FakeCatalogRepository(),
          ),
        ],
        child: const SonifyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MainShell), findsOneWidget);

    // Riverpod reintenta el provider que falló: mientras tanto queda cargando.
    auth.fail(const SocketException('Network is unreachable'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MainShell), findsOneWidget);
    }
    await tester.pumpAndSettle();
    expect(find.byType(MainShell), findsOneWidget);

    // Cerrar sesión de verdad sí vuelve al Login.
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
