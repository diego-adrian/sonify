import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/images/cover_cache.dart';

void main() {
  test('la clave de la portada no cambia al renovarse la firma', () {
    final today = Uri.parse(
      'https://sonify.diegoadrian.com/covers/abc/200.webp?exp=1761696000&sig=aa',
    );
    final tomorrow = Uri.parse(
      'https://sonify.diegoadrian.com/covers/abc/200.webp?exp=1761782400&sig=bb',
    );

    expect(coverCacheKey(today), coverCacheKey(tomorrow));
    expect(
      coverCacheKey(today),
      'https://sonify.diegoadrian.com/covers/abc/200.webp',
    );
  });

  test('cada tamaño de portada tiene su propia clave', () {
    expect(
      coverCacheKey(Uri.parse('https://cdn/covers/abc/200.webp?sig=a')),
      isNot(coverCacheKey(Uri.parse('https://cdn/covers/abc/640.webp?sig=a'))),
    );
  });
}
