import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/features/catalog/presentation/widgets/now_playing_bars.dart';

void main() {
  Widget bars({bool enabled = true}) => MaterialApp(
    home: TickerMode(
      enabled: enabled,
      child: const Center(child: NowPlayingBars(color: Colors.orange)),
    ),
  );

  /// Cuadros que dibuja la app en [duration], avanzando a 60 Hz.
  Future<int> framesDuring(WidgetTester tester, Duration duration) async {
    await tester.pump(); // el cuadro pendiente de montar o de cambiar estado
    var frames = 0;
    var counting = true;
    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      if (counting) frames++;
    });
    const vsync = Duration(microseconds: 16667);
    for (var t = Duration.zero; t < duration; t += vsync) {
      await tester.pump(vsync);
    }
    counting = false;
    return frames;
  }

  testWidgets('se anima a ~12 cuadros por segundo, no en cada vsync', (
    tester,
  ) async {
    await tester.pumpWidget(bars());

    final frames = await framesDuring(tester, const Duration(seconds: 1));

    expect(frames, inInclusiveRange(10, 14));
  });

  testWidgets('en una pestaña oculta no dibuja', (tester) async {
    await tester.pumpWidget(bars(enabled: false));

    expect(await framesDuring(tester, const Duration(seconds: 1)), 0);
  });

  testWidgets('en segundo plano no dibuja y al volver sigue', (tester) async {
    await tester.pumpWidget(bars());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

    expect(await framesDuring(tester, const Duration(seconds: 1)), 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(
      await framesDuring(tester, const Duration(seconds: 1)),
      greaterThan(5),
    );
  });

  testWidgets('con "reducir movimiento" queda quieta', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(bars());

    expect(await framesDuring(tester, const Duration(seconds: 1)), 0);
  });
}
