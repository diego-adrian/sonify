import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../domain/picked_audio_file.dart';
import '../domain/song_license.dart';
import 'widgets/genre_field.dart';
import '../domain/upload_failure.dart';
import '../domain/upload_rules.dart';
import 'upload_controller.dart';

class UploadPage extends ConsumerStatefulWidget {
  const UploadPage({super.key});

  @override
  ConsumerState<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends ConsumerState<UploadPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  PickedAudioFile? _file;
  PickedImageFile? _cover;
  int? _genreId;

  /// Por ahora todo se publica en dominio público: sin selector de licencia.
  static const _license = SongLicense.cc0;
  bool _rightsAccepted = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ref.read(uploadControllerProvider.notifier).pickFile();
    if (file == null || !mounted) return;
    setState(() {
      _file = file;
      if (_title.text.trim().isEmpty) {
        final dot = file.name.lastIndexOf('.');
        _title.text = dot > 0 ? file.name.substring(0, dot) : file.name;
      }
    });
  }

  Future<void> _pickCover() async {
    final cover = await ref.read(uploadControllerProvider.notifier).pickCover();
    if (cover == null || !mounted) return;
    setState(() => _cover = cover);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref
        .read(uploadControllerProvider.notifier)
        .upload(
          file: _file,
          title: _title.text,
          license: _license,
          rightsAccepted: _rightsAccepted,
          genreId: _genreId,
          description: _description.text,
          cover: _cover,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(uploadControllerProvider);
    final genres = ref.watch(genresProvider).value ?? const [];
    final busy = state is UploadInProgress;

    ref.listen(uploadControllerProvider, (_, next) {
      final message = switch (next) {
        UploadSucceeded() => l10n.uploadDone,
        UploadFailed(:final failure) => _failureText(l10n, failure),
        _ => null,
      };
      if (message == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      if (next is UploadSucceeded) {
        ref.read(uploadControllerProvider.notifier).reset();
        Navigator.of(context).maybePop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.uploadTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: _CoverPicker(
                cover: _cover,
                enabled: !busy,
                onTap: _pickCover,
              ),
            ),
            const SizedBox(height: 20),
            _FileTile(file: _file, enabled: !busy, onTap: _pick),
            const SizedBox(height: 20),
            TextField(
              controller: _title,
              enabled: !busy,
              maxLength: UploadRules.maxTitleLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.uploadSongTitle,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _description,
              enabled: !busy,
              maxLength: UploadRules.maxDescriptionLength,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.uploadDescription,
                hintText: l10n.uploadDescriptionHint,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            GenreField(
              genres: genres,
              value: _genreId,
              enabled: !busy,
              onChanged: (id) => setState(() => _genreId = id),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              value: _rightsAccepted,
              onChanged: busy
                  ? null
                  : (value) => setState(() => _rightsAccepted = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.uploadRights,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (state case UploadInProgress(:final progress)) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: scheme.primaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.uploadProgress((progress * 100).round()),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ] else
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: AppTypography.body,
                ),
                child: Text(l10n.uploadSubmit),
              ),
          ],
        ),
      ),
    );
  }

  static String _failureText(AppLocalizations l10n, UploadFailure failure) =>
      switch (failure) {
        UploadFailure.noFile => l10n.uploadErrorNoFile,
        UploadFailure.invalidTitle => l10n.uploadErrorTitle,
        UploadFailure.descriptionTooLong => l10n.uploadErrorDescription,
        UploadFailure.coverUnsupported => l10n.uploadErrorCoverType,
        UploadFailure.coverTooLarge => l10n.uploadErrorCoverTooLarge,
        UploadFailure.coverTooSmall => l10n.uploadErrorCoverTooSmall,
        UploadFailure.rightsNotAccepted => l10n.uploadErrorRights,
        UploadFailure.unsupportedType => l10n.uploadErrorType,
        UploadFailure.tooLarge => l10n.uploadErrorTooLarge,
        UploadFailure.dailyLimit => l10n.uploadErrorDailyLimit,
        UploadFailure.network => l10n.uploadErrorNetwork,
        UploadFailure.unknown => l10n.uploadErrorUnknown,
      };
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.file,
    required this.enabled,
    required this.onTap,
  });

  final PickedAudioFile? file;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final file = this.file;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                file == null
                    ? Icons.upload_file_rounded
                    : Icons.audio_file_rounded,
                color: scheme.primary,
                size: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file?.name ?? l10n.uploadPickFile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title.copyWith(
                        color: scheme.onSurface,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file == null
                          ? l10n.uploadFileHint
                          : '${(file.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Portada cuadrada con vista previa, decodificada al tamaño mostrado.
class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.cover,
    required this.enabled,
    required this.onTap,
  });

  static const size = 160.0;

  final PickedImageFile? cover;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cover = this.cover;
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return Semantics(
      button: true,
      label: l10n.uploadPickCover,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: SizedBox.square(
            dimension: size,
            child: cover == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 36,
                        color: scheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.uploadPickCover,
                        style: AppTypography.bodySmall.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        l10n.uploadCoverHint,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                : Image.file(
                    File(cover.path),
                    fit: BoxFit.cover,
                    cacheWidth: cover.width <= cover.height ? cacheSize : null,
                    cacheHeight: cover.width > cover.height ? cacheSize : null,
                    excludeFromSemantics: true,
                  ),
          ),
        ),
      ),
    );
  }
}
