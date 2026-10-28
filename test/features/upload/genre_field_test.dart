import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/features/catalog/domain/genre.dart';
import 'package:sonify/features/upload/presentation/widgets/genre_field.dart';
import 'package:sonify/l10n/app_localizations.dart';

const _genres = [
  Genre(id: 1, slug: 'baladas', name: 'Baladas'),
  Genre(id: 3, slug: 'cumbia', name: 'Cumbia'),
  Genre(id: 31, slug: 'musica-andina', name: 'Música andina'),
  Genre(id: 32, slug: 'huayno', name: 'Huayño'),
  Genre(id: 110, slug: 'cristiana', name: 'Música cristiana'),
];

void main() {
  int? selected;

  Future<void> pump(WidgetTester tester) async {
    selected = null;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => GenreField(
              genres: _genres,
              value: selected,
              enabled: true,
              onChanged: (id) => setState(() => selected = id),
            ),
          ),
        ),
      ),
    );
  }

  Finder menuItem(String label) => find.descendant(
    of: find.byType(MenuItemButton),
    matching: find.text(label),
  );

  test('la búsqueda ignora mayúsculas y tildes', () {
    expect(foldForSearch('Música Andina'), 'musica andina');
    expect(foldForSearch('HUAYÑO'), 'huayno');
    expect(foldForSearch('Forró'), 'forro');
  });

  testWidgets('escribir filtra la lista y elegir fija el género', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'musica');
    await tester.pumpAndSettle();

    expect(menuItem('Música andina'), findsOneWidget);
    expect(menuItem('Música cristiana'), findsOneWidget);
    expect(menuItem('Cumbia'), findsNothing);

    await tester.tap(menuItem('Música andina'));
    await tester.pumpAndSettle();
    expect(selected, 31);
  });

  testWidgets('sin coincidencias avisa y al salir vuelve a lo elegido', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'huayno');
    await tester.pumpAndSettle();
    await tester.tap(menuItem('Huayño'));
    await tester.pumpAndSettle();
    expect(selected, 32);

    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pumpAndSettle();
    expect(menuItem('No hay géneros con ese nombre'), findsOneWidget);

    // Sale del campo sin elegir (p. ej. cierra el teclado).
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(selected, 32);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Huayño',
    );
  });
}
