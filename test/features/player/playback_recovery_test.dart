import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/features/player/infrastructure/playback_recovery.dart';

/// `testWidgets` usa un reloj falso: `tester.pump(d)` adelanta los Timer.
void main() {
  late List<bool> reloadResults;
  late int reloads;
  late int retries;
  late PlaybackRecovery recovery;

  setUp(() {
    reloadResults = [];
    reloads = 0;
    retries = 0;
    recovery = PlaybackRecovery(
      reload: () async {
        reloads++;
        return reloadResults.isEmpty ? true : reloadResults.removeAt(0);
      },
      retry: () => retries++,
    );
  });

  tearDown(() => recovery.dispose());

  test('sin fallos, play no recarga nada', () async {
    expect(await recovery.ensureLoaded(), isTrue);
    expect(reloads, 0);
  });

  test('tras un fallo, play recarga una sola vez', () async {
    recovery.failed(wasPlaying: false);
    expect(recovery.needsReload, isTrue);

    // Dos play seguidos (p. ej. doble toque del reloj): una recarga.
    final results = await Future.wait([
      recovery.ensureLoaded(),
      recovery.ensureLoaded(),
    ]);

    expect(results, [true, true]);
    expect(reloads, 1);
    expect(recovery.needsReload, isFalse);
  });

  test('si la recarga falla, sigue pendiente para el próximo play', () async {
    reloadResults = [false, true];
    recovery.failed(wasPlaying: false);

    expect(await recovery.ensureLoaded(), isFalse);
    expect(recovery.needsReload, isTrue);
    expect(await recovery.ensureLoaded(), isTrue);
    expect(reloads, 2);
  });

  testWidgets('si estaba sonando reintenta solo con espera creciente', (
    tester,
  ) async {
    recovery.failed(wasPlaying: true);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(retries, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(retries, 1);

    // El reintento falló (el reproductor ya está en pausa): 4 s y luego 8 s.
    recovery.failed(wasPlaying: false);
    await tester.pump(const Duration(seconds: 4));
    expect(retries, 2);
    recovery.failed(wasPlaying: false);
    await tester.pump(const Duration(seconds: 8));
    expect(retries, 3);

    // Agotados: ya solo al pulsar play.
    recovery.failed(wasPlaying: false);
    await tester.pump(const Duration(minutes: 1));
    expect(retries, 3);
    expect(recovery.needsReload, isTrue);
  });

  testWidgets('si estaba en pausa no reanuda por su cuenta', (tester) async {
    recovery.failed(wasPlaying: false);
    await tester.pump(const Duration(minutes: 1));
    expect(retries, 0);
  });

  testWidgets('pausar cancela el reintento pendiente', (tester) async {
    recovery.failed(wasPlaying: true);
    recovery.paused();
    await tester.pump(const Duration(minutes: 1));
    expect(retries, 0);
  });

  testWidgets('al volver a sonar se reinicia la cuenta de reintentos', (
    tester,
  ) async {
    for (var i = 0; i < 3; i++) {
      recovery.failed(wasPlaying: true);
      await tester.pump(const Duration(seconds: 8));
    }
    expect(retries, 3);

    await recovery.ensureLoaded();
    recovery.recovered();
    recovery.failed(wasPlaying: true);
    await tester.pump(const Duration(seconds: 2));
    expect(retries, 4);
  });

  testWidgets('un "listo" antes de recargar no corta los reintentos', (
    tester,
  ) async {
    recovery.failed(wasPlaying: true);
    // Al pausar la pista que falló, aún con búfer, el nativo dice "listo".
    recovery.recovered();
    await tester.pump(const Duration(seconds: 2));
    expect(retries, 1);

    // El reintento falló: siguen los que faltan.
    recovery.failed(wasPlaying: false);
    await tester.pump(const Duration(seconds: 4));
    expect(retries, 2);
  });
}
