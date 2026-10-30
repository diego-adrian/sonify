import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/widgets/tap_outside_dismisses_keyboard.dart';

void main() {
  final first = FocusNode();
  final second = FocusNode();

  tearDownAll(() {
    first.dispose();
    second.dispose();
  });

  Future<void> pump(WidgetTester tester, {required bool enabled}) async {
    final page = Scaffold(
      body: Column(
        children: [
          TextField(key: const Key('first'), focusNode: first),
          TextField(key: const Key('second'), focusNode: second),
          TextButton(
            key: const Key('button'),
            onPressed: () {},
            child: const Text('Botón'),
          ),
          const Expanded(key: Key('empty'), child: SizedBox.expand()),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            enabled ? TapOutsideDismissesKeyboard(child: child!) : child!,
        home: page,
      ),
    );
    await tester.tap(find.byKey(const Key('first')));
    await tester.pump();
    expect(first.hasFocus, isTrue);
  }

  testWidgets('sin esto, en el teléfono el campo sigue enfocado', (
    tester,
  ) async {
    await pump(tester, enabled: false);

    await tester.tap(find.byKey(const Key('empty')));
    await tester.pump();

    expect(first.hasFocus, isTrue);
  });

  testWidgets('tocar una zona vacía cierra el teclado', (tester) async {
    await pump(tester, enabled: true);

    await tester.tap(find.byKey(const Key('empty')));
    await tester.pump();

    expect(first.hasFocus, isFalse);
  });

  testWidgets('tocar un botón también lo cierra', (tester) async {
    await pump(tester, enabled: true);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pump();

    expect(first.hasFocus, isFalse);
  });

  testWidgets('pasar a otro campo no lo cierra', (tester) async {
    await pump(tester, enabled: true);

    await tester.tap(find.byKey(const Key('second')));
    await tester.pump();

    expect(second.hasFocus, isTrue);
  });
}
