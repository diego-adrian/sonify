import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/di/providers.dart';
import 'package:sonify/core/theme/app_theme.dart';
import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/catalog/presentation/widgets/song_tile.dart';
import 'package:sonify/features/downloads/domain/download_entry.dart';
import 'package:sonify/features/downloads/presentation/downloads_page.dart';
import 'package:sonify/l10n/app_localizations.dart';

import '../../helpers/fake_audio_player.dart';
import '../../helpers/fake_download_repository.dart';

Song _song(String id, String title) => Song(
  id: id,
  title: title,
  artistName: 'Artista',
  duration: const Duration(minutes: 3),
  audio: Uri.parse('https://cdn/$id.m4a'),
);

void main() {
  late FakeDownloadRepository downloads;
  late FakeAudioPlayer player;

  Future<void> pumpPage(WidgetTester tester) async {
    player = FakeAudioPlayer();
    addTearDown(player.dispose);
    downloads = FakeDownloadRepository()
      ..entries.addAll([
        DownloadEntry(
          song: _song('1', 'Primera'),
          state: DownloadState.done,
          sizeBytes: 4 << 20,
        ),
        DownloadEntry(
          song: _song('2', 'Segunda'),
          state: DownloadState.done,
          sizeBytes: 4 << 20,
        ),
      ]);
    addTearDown(downloads.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioPlayerProvider.overrideWithValue(player),
          downloadRepositoryProvider.overrideWithValue(downloads),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DownloadsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder trashOf(String title) => find.descendant(
    of: find.ancestor(of: find.text(title), matching: find.byType(Row)).first,
    matching: find.byTooltip('Quitar descarga'),
  );

  testWidgets('la papelera usa el rojo de la marca', (tester) async {
    await pumpPage(tester);

    final icon = tester.widget<Icon>(
      find.descendant(
        of: trashOf('Primera'),
        matching: find.byIcon(Icons.delete_outline_rounded),
      ),
    );
    expect(icon.color, AppTheme.light.colorScheme.primary);
  });

  testWidgets('tocar la papelera pide confirmación antes de borrar', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(trashOf('Primera'));
    await tester.pumpAndSettle();
    expect(find.textContaining('«Primera»'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(downloads.entries, hasLength(2));

    await tester.tap(trashOf('Primera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    expect(downloads.entries.map((e) => e.song.id), ['2']);
    expect(find.text('Primera'), findsNothing);
  });

  testWidgets('deslizar la fila pide confirmación antes de borrar', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.drag(find.text('Segunda'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(downloads.entries, hasLength(2));
    expect(find.text('Segunda'), findsOneWidget);

    await tester.drag(find.text('Segunda'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    expect(downloads.entries.map((e) => e.song.id), ['1']);
    expect(find.text('Segunda'), findsNothing);
  });

  testWidgets('las filas son como las de la Home y el play reproduce', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.byType(SongTile), findsNWidgets(2));
    await tester.tap(find.byTooltip('Reproducir Segunda'));
    await tester.pumpAndSettle();

    expect(player.state.queue.map((s) => s.id), ['1', '2']);
    expect(player.state.current?.id, '2');
  });
}
