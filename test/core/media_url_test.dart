import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/core/network/media_url.dart';

void main() {
  Uri signed(int exp) =>
      Uri.parse('https://cdn.test/audio/x/128.m4a?exp=$exp&sig=abc');
  final noon = DateTime.utc(2026, 10, 29, 12);
  final exp = noon.millisecondsSinceEpoch ~/ 1000;

  test('lee el vencimiento de una URL firmada', () {
    expect(mediaUrlExpiry(signed(exp)), noon);
    expect(mediaUrlExpiry(Uri.file('/a.enc')), isNull);
    expect(mediaUrlExpiry(null), isNull);
  });

  test('vencida o a punto de vencer', () {
    final url = signed(exp);
    expect(
      isMediaUrlExpired(url, now: noon.subtract(const Duration(hours: 1))),
      isFalse,
    );
    expect(
      isMediaUrlExpired(url, now: noon.subtract(const Duration(minutes: 1))),
      isTrue,
    );
    expect(
      isMediaUrlExpired(url, now: noon.add(const Duration(days: 1))),
      isTrue,
    );
    expect(isMediaUrlExpired(Uri.file('/a.enc'), now: noon), isFalse);
  });

  test('se queda con la que vence más tarde', () {
    final old = signed(exp);
    final fresh = signed(exp + 86400);
    expect(fresherMediaUrl(old, fresh), fresh);
    expect(fresherMediaUrl(fresh, old), fresh);
    expect(fresherMediaUrl(old, Uri.file('/a.enc')), old);
    expect(fresherMediaUrl(null, fresh), fresh);
  });
}
