import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/features/catalog/domain/song.dart';

void main() {
  Song song({String? description}) => Song(
    id: '1',
    title: 'Con otra',
    artistName: 'Cazzu',
    duration: const Duration(minutes: 3),
    description: description,
  );

  test('bajo el título va la descripción o, si no tiene, el artista', () {
    expect(
      song(description: 'Cumbia de 2025.').descriptionOrArtist,
      'Cumbia de 2025.',
    );
    expect(song().descriptionOrArtist, 'Cazzu');
    expect(song(description: '   ').descriptionOrArtist, 'Cazzu');
  });
}
