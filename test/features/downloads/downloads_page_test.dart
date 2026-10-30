import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/di/providers.dart';
import 'package:sonify/core/theme/app_theme.dart';
import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/catalog/presentation/widgets/song_tile.dart';
import 'package:sonify/features/downloads/domain/download_entry.dart';
import 'package:sonify/features/downloads/presentation/downloads_page.dart';
import 'package:sonify/features/player/domain/local_audio.dart';
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

/// Caché de lo escuchado con [bytes] guardados.
final class _Cache implements ListeningCache {
  _Cache(this.bytes);

  int bytes;
  bool cleared = false;

  @override
  Future<int> usedBytes() async => bytes;

  @override
  Future<void> clear() async {
    cleared = true;
    bytes = 0;
  }

  @override
  Stream<List<Song>> watchSongs() => Stream.value(const []);

  @override
  Future<LocalAudio?> find(String songId) async => null;

  @override
  Future<String?> tempPathFor(String songId) async => null;

  @override
  void protect(Set<String> songIds) {}

  @override
  Future<void> finished(
    Song song, {
    required bool listenedEnough,
    required bool stillCurrent,
  }) async {}

  @override
  Future<void> clearTemporary() async {}

  @override
  Future<void> discardTemporary(String songId) async {}
}

void main() {
  late FakeDownloadRepository downloads;
  late FakeAudioPlayer player;

  Future<void> pumpPage(
    WidgetTester tester, {
    ListeningCache cache = const NoListeningCache(),
  }) async {
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
          listeningCacheProvider.overrideWithValue(cache),
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

  Finder rowTitle(String title) =>
      find.descendant(of: find.byType(SongTile), matching: find.text(title));

  Finder dialogButton(String label) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(label));

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
    await tester.tap(dialogButton('Cancelar'));
    await tester.pumpAndSettle();
    expect(downloads.entries, hasLength(2));

    await tester.tap(trashOf('Primera'));
    await tester.pumpAndSettle();
    await tester.tap(dialogButton('Borrar'));
    await tester.pumpAndSettle();
    expect(downloads.entries.map((e) => e.song.id), ['2']);
    expect(find.text('Primera'), findsNothing);
  });

  testWidgets('deslizar la fila pide confirmación antes de borrar', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.drag(rowTitle('Segunda'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    // Con la fila fuera, el fondo rojo sigue mostrando el título.
    expect(find.text('Segunda'), findsNWidgets(2));
    expect(rowTitle('Segunda'), findsOneWidget);
    await tester.tap(dialogButton('Cancelar'));
    await tester.pumpAndSettle();
    expect(downloads.entries, hasLength(2));
    expect(rowTitle('Segunda'), findsOneWidget);

    await tester.drag(rowTitle('Segunda'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(dialogButton('Borrar'));
    await tester.pumpAndSettle();
    expect(downloads.entries.map((e) => e.song.id), ['1']);
    expect(find.text('Segunda'), findsNothing);
  });

  testWidgets('las filas no llevan play y tocarlas reproduce', (tester) async {
    await pumpPage(tester);

    expect(find.byType(SongTile), findsNWidgets(2));
    expect(find.byIcon(Icons.play_arrow_outlined), findsNothing);
    await tester.tap(find.text('Segunda'));
    await tester.pumpAndSettle();

    expect(player.state.queue.map((s) => s.id), ['1', '2']);
    expect(player.state.current?.id, '2');
  });

  testWidgets('sin nada en la caché no muestra la fila de vaciar', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Vaciar caché de Sonify'), findsNothing);
  });

  testWidgets('el subtítulo de una descarga es solo su estado', (tester) async {
    await pumpPage(tester);

    expect(
      find.descendant(
        of: find.byType(SongTile).first,
        matching: find.textContaining('Artista'),
      ),
      findsNothing,
    );
  });

  testWidgets('explica la caché en el pie y la vacía tras confirmar', (
    tester,
  ) async {
    final cache = _Cache(120 << 20);
    await pumpPage(tester, cache: cache);

    expect(
      find.textContaining('Sonify guarda automáticamente'),
      findsOneWidget,
    );

    await tester.tap(find.text('Vaciar caché de Sonify'));
    await tester.pumpAndSettle();
    await tester.tap(dialogButton('Cancelar'));
    await tester.pumpAndSettle();
    expect(cache.cleared, isFalse);

    await tester.tap(find.text('Vaciar caché de Sonify'));
    await tester.pumpAndSettle();
    await tester.tap(dialogButton('Borrar'));
    await tester.pumpAndSettle();

    expect(cache.cleared, isTrue);
    expect(find.text('Vaciar caché de Sonify'), findsNothing);
    // Las descargas siguen ahí.
    expect(rowTitle('Primera'), findsOneWidget);
  });
}
