import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/network/online_provider.dart';
import '../../../core/result.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/domain/song.dart';
import '../../catalog/presentation/widgets/song_tile.dart';
import '../../library/presentation/library_actions.dart';
import '../../library/presentation/library_providers.dart';
import '../../library/presentation/widgets/song_save_button.dart';
import '../../../core/widgets/visible_center.dart';

/// Resultados de una búsqueda en todo el catálogo (sin red, en lo que está en
/// el dispositivo). Se descartan al salir de la pantalla.
final searchResultsProvider = FutureProvider.autoDispose
    .family<List<Song>, String>((ref, query) async {
      return switch (await ref.watch(searchSongsProvider)(query)) {
        Ok(:final value) => value,
        Err(:final error) => throw error,
      };
    });

/// Buscar (menú inferior): encontrar una canción del catálogo, escucharla y
/// guardarla en la biblioteca. Así nadie sube dos veces la misma.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  /// Espera tras la última tecla antes de pedir (una petición por palabra,
  /// no por letra).
  static const debounce = Duration(milliseconds: 350);

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(SearchPage.debounce, () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final online = ref.watch(isOnlineProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (text) {
                  _debounce?.cancel();
                  setState(() => _query = text.trim());
                },
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => _controller.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            tooltip: l10n.clearSearch,
                            onPressed: _clear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (!online)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  l10n.searchOffline,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            Expanded(child: _Results(query: _query)),
          ],
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    Widget message(String text) => VisibleCenter(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );

    if (query.length < 2) return message(l10n.searchPrompt);

    final results = ref.watch(searchResultsProvider(query));
    final access = ref.watch(songAccessProvider);
    final online = ref.watch(isOnlineProvider);

    return switch (results) {
      AsyncValue(:final value?) when value.isEmpty => message(
        l10n.searchNoResults(query),
      ),
      AsyncValue(:final value?) => Builder(
        builder: (context) {
          final songs = [for (final song in value) access.resolve(song)];
          bool available(Song song) => online || access.local.contains(song.id);
          List<Song> queue() => [
            for (final song in songs)
              if (access.canPlay(song) && available(song)) song,
          ];
          Future<void> play(Song song) =>
              ref.read(playSongsProvider)(queue(), song);

          return ListView.builder(
            itemExtent: SongTile.height,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final locked = !access.canPlay(song);
              void open() => locked
                  ? showLockedSongSheet(
                      context,
                      ref,
                      song: song,
                      onSaved: (saved) =>
                          ref.read(playSongsProvider)([saved], saved),
                    )
                  : play(song);
              return SongTile(
                song: song,
                locked: locked,
                enabled: locked || available(song),
                actionTooltip: locked
                    ? l10n.lockedTooltip
                    : available(song)
                    ? l10n.playSong(song.title)
                    : l10n.songNeedsConnection,
                onTap: open,
                onAction: open,
                secondaryAction: SongSaveButton(song: song),
                onLongPress: () =>
                    showSongActionsSheet(context, ref, song: song, list: songs),
              );
            },
          );
        },
      ),
      AsyncValue(hasError: true) => message(l10n.searchError),
      _ => const VisibleCenter(child: CircularProgressIndicator()),
    };
  }
}
