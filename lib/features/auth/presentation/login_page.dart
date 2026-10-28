import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sonify_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_provider_type.dart';
import 'login_controller.dart';
import 'widgets/google_sign_in_button.dart';
import '../../../core/theme/app_typography.dart';

/// Login (Figma node 102:88). Igual en modo claro y oscuro.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(loginControllerProvider);

    ref.listen(loginControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        final message = error == AuthFailure.network
            ? l10n.authErrorNetwork
            : l10n.authErrorUnknown;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SonifyColors.loginScrim,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/login_background.jpg',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  // Degradado del diseño: empieza al 49% de la altura y
                  // llega a negro sólido al 82%.
                  stops: [0, 0.49, 0.82, 1],
                  colors: [
                    SonifyColors.loginScrimClear,
                    SonifyColors.loginScrimClear,
                    SonifyColors.loginScrim,
                    SonifyColors.loginScrim,
                  ],
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 52),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    l10n.appTitle,
                    style: AppTypography.brand.copyWith(
                      color: SonifyColors.loginForeground,
                    ),
                  ),
                  Text(
                    l10n.loginTagline,
                    style: AppTypography.body.copyWith(
                      color: SonifyColors.loginForeground,
                    ),
                  ),
                  const SizedBox(height: 44),
                  GoogleSignInButton(
                    label: l10n.loginWithGoogle,
                    loading: state.isLoading,
                    onPressed: () => ref
                        .read(loginControllerProvider.notifier)
                        .signIn(AuthProviderType.google),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
