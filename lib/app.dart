import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/theme/sonify_colors.dart';
import 'core/widgets/tap_outside_dismisses_keyboard.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/shell/presentation/main_shell.dart';
import 'l10n/app_localizations.dart';

class SonifyApp extends ConsumerWidget {
  const SonifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // El del sistema hasta que se elige uno con el botón de la Home.
      themeMode: ref.watch(themeModeProvider),
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          TapOutsideDismissesKeyboard(child: _SystemBars(child: child!)),
      home: const _AuthGate(),
    );
  }
}

/// Hora, batería y barra de navegación legibles sobre el tema de la app (no
/// el del sistema, que puede ser otro si se eligió a mano). Se aplica en
/// cada cuadro; una pantalla puede pedir otro estilo con su propia
/// `AnnotatedRegion` (el Login, blanco sobre la foto).
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final content = brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // iOS: brillo de lo que hay detrás; Android: color de los íconos.
        statusBarBrightness: brightness,
        statusBarIconBrightness: content,
        systemNavigationBarIconBrightness: content,
      ),
      child: child,
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Con un usuario conocido se queda en la app aunque el provider recargue o
    // falle (sin red): solo una sesión nula lleva al Login.
    return switch (ref.watch(authStateProvider)) {
      AsyncValue(value: final user?) => MainShell(user: user),
      AsyncLoading(hasValue: false) => const ColoredBox(
        color: SonifyColors.loginScrim,
      ),
      _ => const LoginPage(),
    };
  }
}
