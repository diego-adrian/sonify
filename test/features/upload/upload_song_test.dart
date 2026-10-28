import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/result.dart';
import 'package:sonify/features/upload/application/upload_song.dart';
import 'package:sonify/features/upload/domain/picked_audio_file.dart';
import 'package:sonify/features/upload/domain/song_license.dart';
import 'package:sonify/features/upload/domain/upload_failure.dart';
import 'package:sonify/features/upload/domain/upload_ports.dart';
import 'package:sonify/features/upload/domain/upload_request.dart';
import 'package:sonify/features/upload/domain/upload_rules.dart';

class _RecordingRepository implements UploadRepository {
  UploadRequest? received;

  @override
  Future<Result<String, UploadFailure>> upload(
    UploadRequest request, {
    required void Function(double progress) onProgress,
  }) async {
    received = request;
    onProgress(1);
    return const Ok('song-1');
  }
}

void main() {
  late _RecordingRepository repository;
  late UploadSong uploadSong;

  setUp(() {
    repository = _RecordingRepository();
    uploadSong = UploadSong(repository);
  });

  const wav = PickedAudioFile(
    path: '/tmp/mi tema.WAV',
    name: 'mi tema.WAV',
    sizeBytes: 10 * 1024 * 1024,
  );

  const cover = PickedImageFile(
    path: '/tmp/portada.jpg',
    name: 'portada.JPG',
    sizeBytes: 2 * 1024 * 1024,
    width: 3000,
    height: 3000,
  );

  Future<Result<String, UploadFailure>> run({
    PickedAudioFile? file = wav,
    String title = '  Mi tema  ',
    bool rights = true,
    String? description,
    PickedImageFile? cover,
  }) => uploadSong(
    file: file,
    title: title,
    license: SongLicense.ccBy,
    rightsAccepted: rights,
    genreId: 3,
    description: description,
    cover: cover,
    onProgress: (_) {},
  );

  UploadFailure? failureOf(Result<String, UploadFailure> result) =>
      result is Err<String, UploadFailure> ? result.error : null;

  test('sube con título recortado y Content-Type según la extensión', () async {
    final result = await run();

    expect(result, isA<Ok<String, UploadFailure>>());
    expect(repository.received?.title, 'Mi tema');
    expect(repository.received?.contentType, 'audio/wav');
    expect(repository.received?.genreId, 3);
  });

  test('valida antes de llamar al servidor', () async {
    expect(failureOf(await run(file: null)), UploadFailure.noFile);
    expect(failureOf(await run(title: '   ')), UploadFailure.invalidTitle);
    expect(
      failureOf(await run(rights: false)),
      UploadFailure.rightsNotAccepted,
    );
    expect(
      failureOf(
        await run(
          file: const PickedAudioFile(
            path: '/a.ogg',
            name: 'a.ogg',
            sizeBytes: 1,
          ),
        ),
      ),
      UploadFailure.unsupportedType,
    );
    expect(
      failureOf(
        await run(
          file: const PickedAudioFile(
            path: '/a.flac',
            name: 'a.flac',
            sizeBytes: UploadRules.maxOriginalBytes + 1,
          ),
        ),
      ),
      UploadFailure.tooLarge,
    );
    expect(repository.received, isNull);
  });

  test('envía portada y descripción recortada', () async {
    await run(description: '  Grabada en vivo  ', cover: cover);

    expect(repository.received?.description, 'Grabada en vivo');
    expect(repository.received?.cover, same(cover));
    expect(repository.received?.coverContentType, 'image/jpeg');
  });

  test('acepta una miniatura de video 1280×720 (lado corto ≥ 640)', () async {
    const thumbnail = PickedImageFile(
      path: '/tmp/thumb.jpg',
      name: 'thumb.jpg',
      sizeBytes: 150 * 1024,
      width: 1280,
      height: 720,
    );

    final result = await run(cover: thumbnail);

    expect(result, isA<Ok<String, UploadFailure>>());
  });

  test('descripción vacía no se envía', () async {
    await run(description: '   ');

    expect(repository.received?.description, isNull);
  });

  test('valida la portada y la descripción', () async {
    PickedImageFile image({
      String name = 'p.png',
      int bytes = 1024,
      int width = 1200,
      int height = 1000,
    }) => PickedImageFile(
      path: '/$name',
      name: name,
      sizeBytes: bytes,
      width: width,
      height: height,
    );

    expect(
      failureOf(await run(cover: image(name: 'p.gif'))),
      UploadFailure.coverUnsupported,
    );
    expect(
      failureOf(await run(cover: image(bytes: UploadRules.maxCoverBytes + 1))),
      UploadFailure.coverTooLarge,
    );
    expect(
      failureOf(await run(cover: image(width: 1000, height: 600))),
      UploadFailure.coverTooSmall,
    );
    expect(
      failureOf(await run(description: 'a' * 501)),
      UploadFailure.descriptionTooLong,
    );
    expect(repository.received, isNull);
  });
}
