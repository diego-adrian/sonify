import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/providers.dart';
import 'core/images/cover_cache.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/theme/theme_preference.dart';
import 'features/player/infrastructure/sonify_audio_handler.dart';
import 'features/upload/infrastructure/file_picker_temp_files.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureImageMemoryCache();
  // Una subida no sobrevive a cerrar la app: lo que quedó ya no sirve.
  unawaited(const FilePickerTempFiles().clear());

  if (AppConfig.hasSupabase) {
    // Lee la sesión guardada en el dispositivo; no necesita red para arrancar.
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  }

  final themeMode = await SharedPreferencesThemePreference().load();

  await SonifyAudioHandler.configureSession();
  final audioHandler = await AudioService.init(
    builder: SonifyAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'app.sonify.sonify.playback',
      androidNotificationChannelName: 'Reproducción',
      androidNotificationOngoing: true,
      // Silueta blanca (branding/generate.mjs): el ícono de la app es
      // adaptativo y a color, y la barra de estado solo usa la transparencia.
      androidNotificationIcon: 'drawable/ic_stat_sonify',
      // Al pausar se suelta el servicio en primer plano (batería).
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
        initialThemeModeProvider.overrideWithValue(themeMode),
      ],
      child: const SonifyApp(),
    ),
  );
}
