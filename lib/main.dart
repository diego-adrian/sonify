import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/providers.dart';
import 'features/player/infrastructure/sonify_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.hasSupabase) {
    // Lee la sesión guardada en el dispositivo; no necesita red para arrancar.
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  }

  await SonifyAudioHandler.configureSession();
  final audioHandler = await AudioService.init(
    builder: SonifyAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'app.sonify.sonify.playback',
      androidNotificationChannelName: 'Reproducción',
      androidNotificationOngoing: true,
      // Al pausar se suelta el servicio en primer plano (batería).
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [audioHandlerProvider.overrideWithValue(audioHandler)],
      child: const SonifyApp(),
    ),
  );
}
