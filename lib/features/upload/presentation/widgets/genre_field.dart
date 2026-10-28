import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../catalog/domain/genre.dart';

/// Combo de género con buscador: se escribe para filtrar los ~80 géneros.
/// La búsqueda ignora mayúsculas y tildes ("musica" encuentra "Música").
class GenreField extends StatefulWidget {
  const GenreField({
    super.key,
    required this.genres,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final List<Genre> genres;

  /// `null` = sin género.
  final int? value;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  @override
  State<GenreField> createState() => _GenreFieldState();
}

class _GenreFieldState extends State<GenreField> {
  /// Entrada deshabilitada que se muestra cuando nada coincide.
  static const _noResultsValue = -1;

  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l10n, int? id) {
    if (id == null) return l10n.uploadGenreNone;
    for (final genre in widget.genres) {
      if (genre.id == id) return genre.name;
    }
    return '';
  }

  /// Si se escribió algo sin elegir, al salir vuelve a mostrar lo elegido.
  void _restoreLabel(AppLocalizations l10n) {
    final label = _label(l10n, widget.value);
    if (_text.text != label) _text.text = label;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedLabel = _label(l10n, widget.value);
    final entries = [
      DropdownMenuEntry<int?>(value: null, label: l10n.uploadGenreNone),
      for (final genre in widget.genres)
        DropdownMenuEntry<int?>(value: genre.id, label: genre.name),
    ];

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) {
        if (!focused) _restoreLabel(l10n);
      },
      child: DropdownMenu<int?>(
        controller: _text,
        initialSelection: widget.value,
        enabled: widget.enabled,
        // En móvil el campo no recibe foco al tocarlo salvo que se pida.
        requestFocusOnTap: true,
        enableFilter: true,
        expandedInsets: EdgeInsets.zero,
        menuHeight: 360,
        label: Text(l10n.uploadGenre),
        hintText: l10n.uploadGenreSearch,
        leadingIcon: const Icon(Icons.search_rounded),
        inputDecorationTheme: const InputDecorationThemeData(
          border: OutlineInputBorder(),
        ),
        dropdownMenuEntries: entries,
        filterCallback: (entries, filter) {
          // Al abrir con lo ya elegido escrito, se muestra la lista entera.
          if (filter.isEmpty || filter == selectedLabel) return entries;
          final query = foldForSearch(filter);
          final matches = [
            for (final entry in entries)
              if (foldForSearch(entry.label).contains(query)) entry,
          ];
          return matches.isNotEmpty
              ? matches
              : [
                  DropdownMenuEntry<int?>(
                    value: _noResultsValue,
                    label: l10n.uploadGenreNoResults,
                    enabled: false,
                  ),
                ];
        },
        searchCallback: (entries, query) {
          if (query.isEmpty || query == selectedLabel) return null;
          final folded = foldForSearch(query);
          final index = entries.indexWhere(
            (entry) =>
                entry.enabled && foldForSearch(entry.label).contains(folded),
          );
          return index < 0 ? null : index;
        },
        onSelected: (id) {
          if (id == _noResultsValue) return;
          widget.onChanged(id);
        },
      ),
    );
  }
}

/// Minúsculas y sin tildes, para buscar en español y portugués.
String foldForSearch(String text) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    final index = from.indexOf(char);
    buffer.write(index < 0 ? char : to[index]);
  }
  return buffer.toString();
}
