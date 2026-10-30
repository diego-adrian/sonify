// URLs firmadas del CDN (`/{key}?exp={unix}&sig=…`, las genera Postgres con
// `private.media_path`): valen 24–48 h. Sirve para no usar una vencida y
// para quedarse con la más nueva de dos URLs del mismo archivo.

/// Cuándo vence [url], o `null` si no está firmada (archivo local, asset).
DateTime? mediaUrlExpiry(Uri? url) {
  final exp = int.tryParse(url?.queryParameters['exp'] ?? '');
  return exp == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
}

/// Vencida o a punto de vencer ([margin]): pedirla daría 403.
bool isMediaUrlExpired(
  Uri? url, {
  DateTime? now,
  Duration margin = const Duration(minutes: 5),
}) {
  final expiry = mediaUrlExpiry(url);
  if (expiry == null) return false;
  return !(now ?? DateTime.now()).add(margin).isBefore(expiry);
}

/// La que vence más tarde (a igualdad, [current]).
Uri? fresherMediaUrl(Uri? current, Uri? candidate) {
  final a = mediaUrlExpiry(current);
  final b = mediaUrlExpiry(candidate);
  if (candidate == null || b == null) return current;
  if (current == null || a == null) return candidate;
  return b.isAfter(a) ? candidate : current;
}
