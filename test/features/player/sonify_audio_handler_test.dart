import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:sonify/features/player/infrastructure/sonify_audio_handler.dart';

import '../../helpers/fake_just_audio_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioSession = MethodChannel('com.ryanheise.audio_session');

  late FakeJustAudioPlatform platform;
  late SonifyAudioHandler handler;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioSession, (_) async => null);
    JustAudioPlatform.instance = platform = FakeJustAudioPlatform();
    handler = SonifyAudioHandler();

    final ids = ['a', 'b', 'c'];
    await handler.load(
      [for (final id in ids) MediaItem(id: id, title: id)],
      () async => [
        for (final id in ids)
          AudioSource.uri(Uri.parse('https://cdn.test/$id.m4a'), tag: id),
      ],
      2,
    );
  });

  tearDown(() async {
    await handler.player.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioSession, null);
  });

  test('doble toque en "anterior": vuelve al inicio y luego a la anterior, '
      'sin pisar seeks en el reproductor nativo', () async {
    // Lleva un rato sonando: el 1.er toque reinicia la canción.
    await handler.seek(const Duration(seconds: 40));
    await handler.play();

    final first = handler.skipToPrevious();
    // El 2.º toque llega antes de que termine el seek del 1.º.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final second = handler.skipToPrevious();
    await Future.wait([first, second]);

    final native = platform.player!;
    expect(native.maxConcurrentSeeks, 1);
    expect(native.index, 1);
    expect(handler.player.currentIndex, 1);
    expect(handler.player.position, lessThan(const Duration(seconds: 1)));
  });

  test('play y enseguida pausa: queda en pausa', () async {
    final play = handler.play();
    await handler.pause();
    await play;
    await Future<void>.delayed(Duration.zero);

    expect(handler.player.playing, isFalse);
  });

  test(
    'doble toque en play/pausa mientras suena: pausa y vuelve a sonar',
    () async {
      await handler.play();

      await Future.wait([handler.click(), handler.click()]);
      await Future<void>.delayed(Duration.zero);

      expect(handler.player.playing, isTrue);
    },
  );

  test(
    'siguiente y enseguida pausa: queda en la siguiente, en pausa',
    () async {
      await handler.skipToQueueItem(0);
      await handler.play();

      final next = handler.skipToNext();
      await handler.pause();
      await next;

      expect(platform.player!.index, 1);
      expect(handler.player.playing, isFalse);
    },
  );

  test('toques seguidos en "siguiente" avanzan de a uno, en orden', () async {
    await handler.skipToQueueItem(0);
    await handler.play();

    await Future.wait([handler.skipToNext(), handler.skipToNext()]);

    final native = platform.player!;
    expect(native.maxConcurrentSeeks, 1);
    expect(native.index, 2);
  });

  group('reproductor de la pantalla de bloqueo', () {
    const nowPlaying = MethodChannel('app.sonify.sonify/now_playing');
    late int renewals;

    setUp(() {
      renewals = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nowPlaying, (_) async {
            renewals++;
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nowPlaying, null);
    });

    test('se renueva al reanudar tras una pausa', () async {
      await handler.play();
      await handler.pause();
      renewals = 0;

      await handler.play();
      await Future<void>.delayed(Duration.zero);

      expect(renewals, 1);
    });

    test('no se renueva si ya estaba sonando', () async {
      await handler.play();
      await Future<void>.delayed(Duration.zero);
      renewals = 0;

      await handler.play();
      await Future<void>.delayed(Duration.zero);

      expect(renewals, 0);
    });
  });

  group('si la recarga no responde', () {
    const stallTimeout = Duration(milliseconds: 50);
    const reloadTimeout = Duration(milliseconds: 200);
    const firstRetryDelay = Duration(milliseconds: 20);

    late SonifyAudioHandler slow;
    late FakeNativePlayer native;

    setUp(() async {
      slow = SonifyAudioHandler(
        stallTimeout: stallTimeout,
        reloadTimeout: reloadTimeout,
        firstRetryDelay: firstRetryDelay,
      );
      await slow.load(
        [const MediaItem(id: 'a', title: 'a')],
        () async => [AudioSource.uri(Uri.parse('https://cdn.test/a.m4a'))],
        0,
      );
      native = platform.player!;
      await slow.play();

      // Se queda esperando la pista y la recarga tampoco responde.
      native.hangLoads = true;
      native.stall();
      await Future<void>.delayed(stallTimeout + firstRetryDelay * 3);
      expect(slow.player.playing, isFalse);
    });

    tearDown(() => slow.player.stop());

    test('play vuelve a funcionar cuando regresa la señal', () async {
      native.hangLoads = false;
      await Future<void>.delayed(reloadTimeout * 2);

      await slow.play();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(slow.player.playing, isTrue);
    });

    test('se reintenta sola, sin tocar nada (en el auto)', () async {
      await Future<void>.delayed(reloadTimeout);
      native.hangLoads = false;
      await Future<void>.delayed(reloadTimeout * 2);

      expect(slow.player.playing, isTrue);
    });
  });
}
