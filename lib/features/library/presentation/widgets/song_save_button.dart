import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../catalog/domain/song.dart';
import '../../../catalog/presentation/widgets/row_icon_button.dart';
import '../library_actions.dart';
import '../library_providers.dart';

/// ＋ guarda la canción en la biblioteca; ✓ (en `primary`) la quita.
class SongSaveButton extends ConsumerStatefulWidget {
  const SongSaveButton({super.key, required this.song});

  final Song song;

  @override
  ConsumerState<SongSaveButton> createState() => _SongSaveButtonState();
}

class _SongSaveButtonState extends ConsumerState<SongSaveButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    setState(() => _busy = true);
    await toggleSaved(context, ref, widget.song);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final saved = ref.watch(
      currentLibraryProvider.select(
        (library) => library.contains(widget.song.id),
      ),
    );

    return RowIconButton(
      tooltip: saved ? l10n.songSavedTooltip : l10n.songSave,
      onPressed: _busy ? null : _toggle,
      color: saved ? scheme.primary : null,
      icon: _busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(saved ? Icons.check_rounded : Icons.add_rounded, size: 22),
    );
  }
}
