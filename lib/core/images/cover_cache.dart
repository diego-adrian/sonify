import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Portadas en disco (carpeta de cachés: el sistema puede purgarla si falta
/// espacio, y no va a respaldos). Así no se vuelven a bajar cada vez que se
/// abre la app y las de canciones no descargadas también se ven sin red.
///
/// ~600 portadas: las de 200 px pesan ~15–30 KB y las de 640 px ~60–100 KB,
/// unos 20–30 MB en el peor caso. Se borran las menos usadas al pasar el
/// tope o tras 60 días sin verse.
final coverCacheManager = CacheManager(
  Config(
    'sonifyCovers',
    stalePeriod: const Duration(days: 60),
    maxNrOfCacheObjects: 600,
  ),
);

/// Clave estable: la URL sin la firma (`?exp=…&sig=…` cambia cada día). Las
/// portadas son inmutables (si cambian, cambia la ruta), como en la caché
/// del Worker.
String coverCacheKey(Uri url) => '${url.origin}${url.path}';

/// Tope de imágenes decodificadas en memoria (por defecto Flutter permite
/// 100 MB). Las portadas se decodifican al tamaño mostrado: una fila ocupa
/// ~80 KB y la portada grande del reproductor ~4 MB.
void configureImageMemoryCache() {
  PaintingBinding.instance.imageCache
    ..maximumSizeBytes = 40 << 20
    ..maximumSize = 300;
}
