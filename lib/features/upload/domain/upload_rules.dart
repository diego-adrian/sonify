/// Mismas reglas que `supabase/functions/_shared/upload_rules.ts`; el
/// servidor las vuelve a comprobar.
abstract final class UploadRules {
  static const maxOriginalBytes = 200 * 1024 * 1024;
  static const maxTitleLength = 120;
  static const maxDescriptionLength = 500;

  static const maxCoverBytes = 10 * 1024 * 1024;

  /// Lado mínimo de la portada (se recorta al centro si no es cuadrada).
  /// 640 px como Spotify: admite miniaturas de video 1280×720 recortadas.
  static const minCoverSide = 640;

  static const contentTypes = {
    'wav': 'audio/wav',
    'flac': 'audio/flac',
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
  };

  static const coverContentTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  static List<String> get extensions => contentTypes.keys.toList();

  static List<String> get coverExtensions => coverContentTypes.keys.toList();

  static String? contentTypeFor(String fileName) =>
      contentTypes[_extension(fileName)];

  static String? coverContentTypeFor(String fileName) =>
      coverContentTypes[_extension(fileName)];

  static String? _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot < 0 ? null : fileName.substring(dot + 1).toLowerCase();
  }
}
