# Sonify

App de música multiplataforma, parecida a Spotify pero pensada para **artistas emergentes**: personas que recién entran al mundo musical y quieren publicar música **libre de derechos** para que otros la escuchen. Lema del diseño: *"tu ritmo son latino"*.

> Estado: app Flutter (iOS + Android) con Login real (Google + Supabase), Home (`106:97`), reproductor (`just_audio` + `audio_service`: segundo plano, pantalla de bloqueo, cola, aleatorio, seek), subida de canciones a B2 y descargas offline cifradas. CDN (Worker de Cloudflare) escrito pero sin desplegar. Catálogo todavía de desarrollo (`InMemoryCatalogRepository`) con audio de prueba en dominio público de Wikimedia Commons. Este archivo describe la visión y las decisiones acordadas; actualízalo a medida que se tomen decisiones nuevas.

## Comandos

```bash
flutter pub get
flutter gen-l10n                 # tras editar lib/l10n/*.arb
dart run build_runner build      # tras editar tablas de Drift (*.g.dart)
flutter analyze
flutter test
flutter run --dart-define-from-file=config/dev.json            # debug
flutter run --profile --dart-define-from-file=config/dev.json  # medir rendimiento en iPhone real

# Instalar una build release en el iPhone (`flutter install` busca el .app en una ruta equivocada en esta versión)
flutter build ios --release --dart-define-from-file=config/dev.json
xcrun devicectl device install app --device <udid> build/ios/iphoneos/Runner.app   # la ruta que imprime el build
```

- Configuración por entorno en `config/dev.json` (gitignored; plantilla en `config/dev.example.json`): `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_WEB_CLIENT_ID`. Se lee en `lib/core/config/app_config.dart`. Las configuraciones de VS Code ya la pasan.
- Supabase: proyecto `sonify`, ref `gbpnbcpbqraojdeaaalt`, región `sa-east-1`. Migraciones en `supabase/migrations/` con el mismo nombre/versión que en el proyecto remoto: al aplicar una nueva con el MCP, guardar el archivo local con la versión que devuelve `list_migrations`.
- Login con Google: `google_sign_in` 7 + `signInWithIdToken` con **nonce** por intento (no activar "Skip nonce check" en Supabase).

- CDN de medios: Worker `sonify-media` en `cloudflare/media-worker/` (ruta `sonify.diegoadrian.com/*`). Comandos dentro de esa carpeta: `pnpm install`, `pnpm check`, `pnpm test`, `pnpm wrangler deploy`. **Siempre pnpm** (nunca npm, yarn ni npx; `pnpm dlx` en su lugar).
- Transcodificador: servicio Cloud Run `sonify-transcoder` (proyecto GCP `sonifyauth`, región `us-east1`, cerca de B2) en `transcoder/`: Node 24 ejecutando TypeScript directo + ffmpeg de Debian (el ffmpeg de Homebrew no trae libwebp). Hexagonal: `domain/media_plan.ts` (keys y argumentos de ffmpeg), `application/transcode_song.ts`, `infrastructure/` (B2, PostgREST con llave secreta, ffmpeg, archivos). Comandos en `transcoder/`: `pnpm test`, `pnpm check`, y `docker build --target test .` (pruebas con el ffmpeg real de la imagen). Lo dispara el trigger `songs_request_transcode` (pg_net → `POST /transcode` con cabecera `x-transcoder-secret`) al pasar una canción a `processing`; reintento manual: `select private.request_transcode('<song_id>')`. Secretos en Vault (`transcoder_url`, `transcoder_secret`) y en Secret Manager de GCP; nunca en el chat ni el repo. `songs.cover_key` guarda el prefijo `covers/{id}` (tamaños `200` y `640`).
- Bundle ID / applicationId: `app.sonify.sonify`.
- Fuente Poppins empaquetada en `assets/fonts/poppins/` (no `google_fonts`, que descarga en tiempo de ejecución: rompe offline y gasta red).
- Estado e inyección de dependencias: `flutter_riverpod`; el composition root está en `lib/core/di/providers.dart`.
- Subida: `features/upload` (formulario → `UploadSong` → `SupabaseUploadRepository`: Edge Function `create-upload` → PUT directo a B2 con `background_downloader` → `complete-upload`). Edge Functions en `supabase/functions/` (código compartido en `_shared/`), desplegadas con `verify_jwt = false`: el proyecto usa llaves de firma asimétricas y cada función verifica el JWT en código con `auth.getClaims`. Se suben audio original y portada original opcional (`originals/{user_id}/{song_id}.{ext}` y `…/{song_id}-cover.{ext}`, JPG/PNG/WebP, mín. 640 px de lado (como Spotify; se recorta al centro), ≤ 10 MB) más descripción (≤ 500). Secretos de las funciones: `B2_KEY_ID`, `B2_APPLICATION_KEY`, `B2_BUCKET`, `B2_ENDPOINT` (los pone el usuario en el dashboard; nunca pasan por el chat ni el repo). Verificar con `deno check` antes de desplegar.
- Descargas offline: `features/downloads`. `BackgroundDownloadRepository` implementa a la vez `DownloadRepository` y `LocalAudioLibrary` (puerto del reproductor): `AudioServicePlayer` pregunta por cada canción y, si está descargada, la reproduce con un `StreamAudioSource` que descifra al vuelo por rangos de 256 KB, cada uno en un isolate. AES-256-CTR en Dart puro (`pointycastle`, ~26 MB/s en AOT; si al medir en el iPhone pesa en batería, pasar a CommonCrypto / javax.crypto por canal nativo). Canal nativo propio `app.sonify.sonify/storage` (`AppDelegate.swift`, `MainActivity.kt`): espacio libre y `isExcludedFromBackup`. Android: `allowBackup=false` + `data_extraction_rules.xml`. La clave va en Keychain con `first_unlock_this_device` (sin iCloud, legible con el teléfono bloqueado). **Descargas por usuario**: carpeta `downloads/users/{userId}/` con su propia base Drift, su clave (`sonify.downloads.key.v1.{userId}`) y su grupo de `background_downloader`. Al cerrar sesión se conservan (ocultas) y se pausa lo que estaba bajando (`suspend`; se retoma al volver a entrar); otra cuenta en el mismo teléfono no las ve ni puede descifrarlas. UI: mantener presionada una canción (descargar / toda la lista / quitar) y pantalla Descargas desde la barra superior.
- Reproductor: `features/player`. El puerto `AudioPlayerPort` lo implementa `AudioServicePlayer` sobre `SonifyAudioHandler` (`audio_service` + `just_audio`), creado en `main` con `AudioService.init` e inyectado con override de `audioHandlerProvider`. La posición va en un stream aparte a ~1 Hz y solo se escucha con la app en primer plano (`appResumedProvider`); `PlaybackProgressBar` interpola con un reloj local y repinta solo al avanzar un píxel físico (movimiento continuo con pocas actualizaciones). En tests se usa `test/helpers/fake_audio_player.dart`.

## Idea del producto

- **Todo usuario es artista y dueño de sí mismo**: no hay roles (oyente/artista/admin de catálogo). Cualquiera puede subir sus canciones libres de derechos y escuchar las de los demás.
- Catálogo filtrable por género (Baladas, Rancheras, Cumbia, Románticos, etc.).
- **Modo offline como requisito central**, no como extra: la app debe poder reproducir música descargada en lugares sin señal (sótanos, bares, locales pequeños donde suelen presentarse canciones en vivo).
- Interfaz en español.

## Stack

| Capa | Tecnología | Rol |
|---|---|---|
| App | **Flutter** | Un solo código para iOS, Android (y luego web/desktop) |
| Autenticación | **Supabase Auth** | Login con Google (es el único botón del diseño de Login) |
| Base de datos | **Supabase Postgres** | Metadatos: perfiles (artistas), canciones, géneros, playlists, likes |
| Almacenamiento | **Backblaze B2** | Archivos de audio y portadas |
| CDN / dominio | **Cloudflare** | `sonify.diegoadrian.com`: Worker que sirve los archivos de B2 con caché |
| Arquitectura | **Hexagonal (puertos y adaptadores)** | Obligatoria en la app Flutter y en el código de backend (Edge Functions / Worker) |

## Arquitectura hexagonal

El núcleo (dominio + casos de uso) no conoce Flutter, Supabase, Backblaze, Cloudflare ni la base local. Todo lo externo entra o sale por **puertos** (interfaces) implementados por **adaptadores**.

```
lib/
  core/                      # utilidades compartidas, errores, Result/Either, DI, theme
  features/
    <feature>/               # auth, catalog, player, library, downloads, upload, ...
      domain/                # entidades, value objects, puertos (abstract interface class)
      application/           # casos de uso (uno por acción: PlaySong, DownloadSong, ...)
      infrastructure/        # adaptadores de salida: Supabase, CDN/B2, Drift/Isar, just_audio
      presentation/          # adaptadores de entrada: pantallas, widgets, estado (controllers)
```

Reglas:
- Dependencias siempre hacia adentro: `presentation → application → domain` e `infrastructure → domain`. `domain` es Dart puro, sin imports de `package:flutter`, `supabase_flutter`, `drift`, `just_audio`, etc.
- Los widgets nunca llaman a Supabase ni a la red directamente: llaman a un caso de uso, que usa un puerto.
- Los adaptadores convierten DTOs/filas a entidades de dominio; los DTOs no salen de `infrastructure`.
- La inyección de dependencias (en `core/`) es el único lugar que conecta puertos con adaptadores concretos.
- **Offline encaja aquí**: p. ej. el puerto `SongRepository` tiene un adaptador remoto (Supabase + CDN) y uno local (Drift/Isar + archivos descargados); un repositorio compuesto decide cuál usar según la conectividad, sin que el dominio ni la UI lo sepan.
- Los casos de uso se prueban con tests unitarios usando fakes de los puertos, sin Flutter ni red.
- Mismo principio en Edge Functions / Worker: lógica en funciones puras, y el acceso a B2, Supabase o Cloudflare detrás de interfaces.

## Usuarios, propiedad y base de datos

**Principio:** Backblaze solo guarda bytes de todo el mundo; **la propiedad vive en Postgres**. Cada canción tiene un dueño (`owner_id`) y RLS hace cumplir quién puede ver o modificar qué. La app nunca decide rutas ni dueños: eso lo hace el backend a partir del JWT.

### Autenticación multi-proveedor

- Hoy solo **Google**; en el futuro más proveedores (Apple, email, etc.) sin cambiar el modelo de datos.
- La identidad interna es siempre **`auth.users.id` (uuid)**. Nunca usar como clave el ID de Google ni el email: un usuario puede tener varias identidades (`auth.identities`) vinculadas a la misma cuenta (identity linking de Supabase).
- Al crearse un usuario en `auth.users`, un **trigger** crea su fila en `public.profiles` con nombre y avatar del proveedor.
- En la app, el login es un puerto (`AuthRepository`) con un adaptador por proveedor; añadir uno nuevo no toca dominio ni UI más allá del botón.
- **Antes de publicar en App Store hay que añadir "Iniciar sesión con Apple"**: la guideline 4.8 lo exige si se ofrece login con Google.
- **Borrado de cuenta dentro de la app** (exigido por App Store, guideline 5.1.1(v)): borra perfil, canciones (soft delete) y encola el borrado de sus archivos en B2.

### Esquema (Supabase Postgres)

| Tabla | Campos clave | Notas |
|---|---|---|
| `profiles` | `id` (= `auth.users.id`, PK, FK on delete cascade), `display_name`, `slug` unique, `bio`, `avatar_url`, `created_at` | **El perfil es el artista**: todo usuario es artista de sí mismo, sin tabla ni rol aparte. Creado por trigger |
| `genres` | `id`, `slug`, `name` | Baladas, Rancheras, Cumbia, Románticos… |
| `songs` | `id` (uuid), `owner_id` → `profiles.id` (el artista), `title`, `genre_id`, `duration_ms`, `status`, `visibility`, `license`, `rights_accepted_at`, `original_key`, `original_size`, `cover_key`, `created_at`, `deleted_at` | `owner_id` es a la vez el artista y la clave de las políticas RLS |
| `song_files` | PK (`song_id`, `quality`), `key`, `size_bytes`, `sha256` | Una fila por calidad (96/128/256) generada por el transcodificador |
| `likes`, `playlists`, `playlist_songs` | `user_id` → `profiles.id` | Más adelante |

- `status`: `uploading` → `processing` → `ready` | `failed`; `removed` para moderación.
- `visibility`: `public` | `private` (borrador visible solo para el dueño).
- `license`: licencia libre declarada por el artista (CC0, CC BY, CC BY-SA…). Al subir, el usuario **acepta una declaración de que tiene los derechos**; se guarda en `rights_accepted_at`.
- Índices en `songs (status, visibility, genre_id, created_at)` y `songs (owner_id)`.
- Todo cambio de esquema como migración (vía MCP de Supabase o `supabase/migrations/`).

### Reglas RLS

- `profiles`: lectura pública de campos básicos; `update` solo `id = auth.uid()`.
- `songs`:
  - `select`: (`status = 'ready'` y `visibility = 'public'` y `deleted_at is null`) **o** `owner_id = auth.uid()`.
  - `insert`: **no desde la app**; solo la Edge Function con service role (ella fija `owner_id`, `id` y keys).
  - `update`: el dueño solo puede cambiar metadatos (`title`, `genre_id`, `visibility`, `cover_key`); `status`, keys, `owner_id` y tamaños solo los cambia el backend (trigger que lo bloquee o columnas revocadas).
  - `delete`: soft delete (`deleted_at`) por el dueño; un job borra los archivos de B2.
- `song_files`: lectura si la canción es legible; escritura solo backend.

### Flujo de subida de una canción

1. La app llama a la Edge Function **`create-upload`** con el JWT y los metadatos (título, género, licencia, aceptación de derechos, tamaño y tipo del archivo).
2. La función obtiene `user_id` del JWT, valida (tipos permitidos WAV/FLAC/MP3/M4A, tamaño máximo del original, cuota por usuario), inserta la canción con `status = 'uploading'` y **genera ella misma la key**: `originals/{user_id}/{song_id}.{ext}`.
3. Devuelve una **URL prefirmada de subida** (API S3 de B2) válida unos minutos y solo para esa key.
4. La app sube el archivo directo a B2 (con `background_downloader`, que también hace uploads en segundo plano y reanudables).
5. Al terminar, la app llama a **`complete-upload`** (o lo detecta una notificación de evento de B2): se verifica que el objeto existe y pesa lo declarado → `status = 'processing'` → se encola la transcodificación.
6. El transcodificador genera `audio/{song_id}/…` y `covers/{song_id}/…`, rellena `song_files` → `status = 'ready'`.
7. Canciones que se quedan en `uploading` más de X horas se limpian (fila y objeto huérfano).

- Cuotas por usuario (nº de subidas por día, tamaño máximo) para evitar abuso y costos.
- Una canción `private` no se puede descargar aunque alguien conozca la ruta: el Worker solo sirve **URLs firmadas** que Postgres emite para lo que RLS deja leer al usuario (ver CDN).

## Arquitectura de archivos (Backblaze + Cloudflare)

```
Flutter app ──(URL firmada)──► sonify.diegoadrian.com  (Cloudflare: DNS proxied + Worker)
                                      │  caché en el edge
                                      ▼
                               Backblaze B2 bucket (audio/, covers/)
```

- **Lectura**: la app nunca habla directo con B2. Pide los archivos al subdominio de Cloudflare, que hace proxy al bucket y cachea. B2 y Cloudflare son socios del Bandwidth Alliance, así que el egreso B2 → Cloudflare no se cobra.
- **Bucket privado + Cloudflare Worker** (`cloudflare/media-worker/`, hexagonal: `domain/` claves y firmas, `application/serve_media.ts`, `infrastructure/` B2 y Cache API):
  - **URLs firmadas, no JWT**: `/{key}?exp={unix}&sig={hex(HMAC-SHA256(MEDIA_URL_SECRET, "{key}:{exp}"))}`. Las genera Postgres con `private.media_path(key)` (secreto `media_url_secret` en Vault), llamada solo desde vistas/funciones que ya filtraron por RLS; así el catálogo trae las URLs en la misma consulta. El Worker solo verifica la firma (sin llamar a Supabase). Sin cabeceras: el reproductor nativo, `background_downloader` y la portada de CarPlay/Android Auto usan la URL tal cual (con cabeceras, `just_audio` en iOS levanta un proxy local, que gasta batería).
  - `exp` cae en límite de día UTC (válida 24–48 h; el Worker rechaza > 7 días): la URL es estable durante el día y la caché de imágenes de la app la reutiliza. La caché del edge usa la key sin la firma.
  - Solo sirve `audio/{uuid}/{96|128|256}.m4a` y `covers/{uuid}/{200|640}.webp`; `originals/` nunca. GET/HEAD con Range: en fallo de caché con rango responde el 206 de B2 y llena la caché con el archivo entero en segundo plano.
  - Secretos del Worker (dashboard de Cloudflare, nunca chat ni repo): `B2_KEY_ID` / `B2_APPLICATION_KEY` (Application Key **de solo lectura** del bucket) y `MEDIA_URL_SECRET` (copia del de Vault). `B2_BUCKET` y `B2_ENDPOINT` van en `wrangler.jsonc`.
- **Subida**: las credenciales de B2 **nunca** van dentro de la app. Ver "Flujo de subida de una canción": la Edge Function crea la canción, genera la key y devuelve una URL prefirmada; la app sube el original directo a B2.
- Rutas en el bucket:
  - `originals/{user_id}/{song_id}.{ext}` — archivo subido por el artista (WAV/FLAC/MP3). **Privado, nunca se sirve a la app.**
  - `audio/{song_id}/{96|128|256}.m4a` — versiones transcodificadas que consume la app.
  - `covers/{song_id}/{200|640}.webp` — portadas: 200 px (~15–30 KB, listas y offline) y 640 px (reproductor).
- En la base de datos guardar solo la *key*, no la URL completa, para poder cambiar de dominio/CDN sin migrar datos.
- Los archivos de `audio/` y `covers/` son **inmutables** (si cambian, cambia la key): se sirven con `Cache-Control: public, max-age=31536000, immutable` para que Cloudflare los cachee siempre.
- Revisar los términos de Cloudflare sobre servir mucho contenido multimedia desde el CDN normal; si el tráfico crece, considerar R2 o un plan acorde.

### Transcodificación (peso de las canciones)

Cifrar no reduce el tamaño; lo reduce el códec. Todo el audio se sirve en **AAC (`.m4a`)**: compatible nativamente con iOS, Android, CarPlay y Android Auto, sin plugins.

| Calidad (ajuste del usuario) | Bitrate | ~5 min | 100 canciones |
|---|---|---|---|
| Normal | 96 kbps | ~3.6 MB | ~360 MB |
| **Alta (por defecto)** | 128 kbps | ~4.8 MB | ~480 MB |
| Máxima | 256 kbps | ~9.6 MB | ~960 MB |

(Referencia: un MP3 a 320 kbps pesa ~12 MB → 1.2 GB por 100 canciones.)

- Un **worker de transcodificación con ffmpeg** en contenedor (Cloudflare Containers, Fly.io, Cloud Run o un VPS) se dispara al subir un original (cola: Cloudflare Queues o tabla/`pgmq` en Supabase). No corre en Edge Functions ni en Workers.
- Pasos: leer de `originals/` → normalizar volumen a **−14 LUFS** (las mezclas de artistas emergentes son muy desiguales) → limpiar metadatos → generar las 3 calidades → generar portadas WebP → calcular **SHA-256** y duración de cada archivo → guardar keys, tamaños y hashes en Postgres → marcar la canción como `ready`.
- Sigue la arquitectura hexagonal: el pipeline es un caso de uso; ffmpeg, B2 y Supabase son adaptadores.

## Modo offline

Objetivo: descargar muchas canciones ocupando lo mínimo y con el mejor rendimiento. **Todo es local al dispositivo**: nada se sube a iCloud, Google Drive ni a ningún respaldo en la nube del sistema.

### Almacenamiento local

- Audio descargado en el almacenamiento privado de la app: iOS `Application Support/downloads/` (no `Caches/`, que el SO puede purgar); Android `filesDir/downloads/`.
- **Excluido de respaldos del sistema**: en iOS marcar la carpeta con `isExcludedFromBackup` (`NSURLIsExcludedFromBackupKey`); en Android excluirla en `data_extraction_rules.xml` / `full_backup_content.xml` (o `android:allowBackup="false"`).
- Base de datos local **Drift** (SQLite) con los metadatos de lo descargado (canción, artista, portada, key local, calidad, tamaño, SHA-256, fecha) para que listas, búsqueda y reproducción funcionen sin red.
- Portadas offline solo en miniatura WebP.
- Dos zonas separadas:
  - **Descargas**: solo las borra el usuario ("Borrar todo" o una a una). Se conservan al cerrar sesión, separadas por usuario.
  - **Caché de streaming**: tamaño máximo configurable, se purga por LRU.
- Pantalla de almacenamiento: espacio usado por Sonify, por calidad y por playlist; botón para borrar todo.

### Cifrado de archivos descargados

- **AES-256-CTR** por archivo, con IV aleatorio de 16 bytes al inicio (overhead de tamaño despreciable; AES acelerado por hardware, impacto mínimo en batería).
- Clave por usuario + dispositivo, guardada en **Keychain** (iOS) / **Android Keystore** (vía `flutter_secure_storage`). Nunca en disco plano ni en la base local.
- Se descifra **al vuelo durante la reproducción** con un `StreamAudioSource` de `just_audio`: CTR permite saltar a cualquier posición (seek) sin descifrar el archivo completo y sin escribir nunca el audio en claro a disco.
- Cifrar en streaming mientras se descarga (o justo al terminar, borrando el temporal): el archivo en claro no debe quedar en el dispositivo.
- Clave y descargas **por usuario**: al cerrar sesión se conservan (ocultas, sin poder descifrarse desde otra cuenta) y vuelven al entrar con la misma cuenta. Al **borrar la cuenta** sí se borran su carpeta y su clave.
- Validación de licencia offline: revalidar con el servidor como máximo cada **30 días** (pensado para uso prolongado sin señal en sótanos/locales).
- Sin DRM pesado (Widevine/FairPlay): innecesario para música libre de derechos.

### Descargas eficientes (p. ej. 100 canciones)

- **`background_downloader`**: usa `URLSession` en segundo plano (iOS) y `WorkManager` (Android); sigue descargando con la app cerrada o el teléfono bloqueado.
- Cola con **3–4 descargas concurrentes**, reintentos con backoff y **reanudación por HTTP Range** (si se corta en la canción 63, sigue desde ahí y desde el byte donde quedó).
- **Solo Wi-Fi por defecto** (configurable).
- **Verificar espacio libre antes** de un lote ("necesitas 480 MB, tienes 300 MB") en lugar de fallar a mitad.
- **Verificar SHA-256** tras cada descarga; si no coincide, se re-descarga.
- Descarga por playlist/álbum con progreso agregado; las canciones ya descargadas en otra playlist no se duplican (se referencian por `song_id` + calidad).
- Descargas directas desde el CDN de Cloudflare (caché en el edge, sin egreso de B2).

### Arranque y sincronización

- La app arranca y muestra la biblioteca descargada sin conexión; la sesión de Supabase en caché no debe bloquear el uso offline.
- Reproducción en segundo plano y controles en pantalla de bloqueo: `just_audio` + `audio_service`.
- Likes, playlists y reproducciones hechos offline van a una **cola de sincronización** en Drift que se vacía al volver la conexión (`connectivity_plus`).
- En hexagonal: el puerto `SongRepository` / `PlaybackSource` tiene adaptador remoto (CDN) y local (Drift + archivos cifrados); la decisión online/offline vive en infraestructura, no en el dominio ni en la UI.

## CarPlay y Android Auto

Prioridad desde el inicio: **deben funcionar**, usando las plantillas del sistema (no se muestra la interfaz de Sonify en el auto).

- **Android Auto**: `audio_service` expone el árbol navegable (`MediaBrowserService`) desde Dart.
- **CarPlay**: módulo nativo en Swift (`CPTemplateApplicationSceneDelegate`, `CPListTemplate`, `CPTabBarTemplate`, `CPNowPlayingTemplate`) que pide los datos al núcleo Dart por platform channels.
- La app debe funcionar **lanzada solo desde el auto** con el teléfono bloqueado (motor Flutter arrancado sin UI en iOS). Diseñarlo desde el principio.
- En el auto se prioriza lo descargado: Descargas, Recientes, Favoritos, Géneros. La reproducción no debe depender de la red.
- En hexagonal, el auto es otro **adaptador de entrada** que llama a los mismos casos de uso que la UI del teléfono.
- Pendiente: **solicitar el entitlement de CarPlay Audio** a Apple (aprobación manual, puede tardar semanas).
- Probar con CarPlay Simulator (Xcode Additional Tools) y Android Auto Desktop Head Unit (DHU).

## Diseño (Figma)

Archivo: https://www.figma.com/design/N1HN0LGiqPOE4msh9jM5Tb/Clon-de-spotify (fileKey `N1HN0LGiqPOE4msh9jM5Tb`)

| Pantalla | Node ID | Contenido |
|---|---|---|
| Login | `102:88` | Foto de concierto a pantalla completa con degradado a negro, título "Sonify", subtítulo "tu ritmo son latino", botón rojo "Ingresar con Google" |
| **Home V1 Oficial** | `106:97` | **Diseño de la Home** y referencia para todo lo de pistas (ver abajo) |
| Home V1 | `1:2` | Versión anterior de la Home (chips de género, mini-reproductor). **Reemplazada** por `106:97`; solo de referencia |
| Componente `Buttons` | `61:148` | Chip de género, variantes `active=true` / `active=false` |
| Componente `List` | `42:56` | Fila de canción antigua; **reemplazada** por el estilo de fila de `106:97` |

### Home V1 Oficial (`106:97`) — diseño de la Home

La Home es esta vista, con la fuente (Poppins) y el color (`#DB4437`) del Login. Arriba se añadió una barra mínima (avatar → cuenta/cerrar sesión, saludo, búsqueda) que no está en Figma. Las filas de canciones y el reproductor siguen este diseño, no el de `List` / Home V1:

- **Reproductor**: portada grande circular con sombra suave, título en negrita ("Canción - By Artista"), artistas en gris debajo.
- **Barra de progreso**: tiempo actual a la izquierda, duración a la derecha, relleno `primary` sobre pista `primaryContainer`.
- **Controles**: fila de botones circulares `surfaceVariant` (aleatorio, anterior, siguiente, cola) con el botón **play** central más grande, en `primary` y con sombra del mismo color.
- **Pestañas**: "Similares" y "A continuación" (en el diseño, "Similar" / "Up Next"), con ícono, y subrayado `primary` en la activa.
- **Fila de pista**: portada cuadrada redondeada, título en negrita (truncado con "…"), artistas debajo (truncados), botón circular con borde `outline` a la derecha: ▷ en `primary` para reproducir, ☰ para la cola. Separador fino entre filas.

### Sistema visual

**Color primario único: `#DB4437`** (el rojo del botón "Ingresar con Google" del Login, node `103:212`). Se usa en **toda** la app: botón play, barra de progreso, pestaña activa, chip de género activo, mini-reproductor, botones principales, íconos activos. No usar otros colores de acento (el verde lima de Home V1 y el coral de `106:97` quedan descartados y se sustituyen por este rojo).

La app soporta **modo claro y modo oscuro** (sigue al sistema por defecto, con opción manual en ajustes). Tokens de partida:

| Token | Claro | Oscuro |
|---|---|---|
| `primary` | `#DB4437` | `#DB4437` |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` |
| `primaryContainer` (chip activo, pista de la barra de progreso) | `#DB4437` al ~12% sobre el fondo | `#DB4437` al ~20% sobre el fondo |
| `background` / `surface` | `#FFFFFF` | `#121212` |
| `surfaceVariant` (botones circulares, chips inactivos, mini-reproductor) | `#F2F2F2` | `#2A2A2A` |
| `onSurface` (texto principal) | `#000000` | `#FFFFFF` |
| `onSurfaceVariant` (artistas, duración, texto secundario) | `#8A8A8A` | `#A0A0A0` |
| `outline` (separadores, borde del botón de cada fila) | `#E6E6E6` | `#333333` |

- El Login es igual en ambos modos (foto + degradado a negro, texto blanco).
- Las sombras de color del botón play usan `primary` con opacidad; en oscuro bajarla o quitarla.
- Todos los colores salen de un `ColorScheme` claro y otro oscuro en un `ThemeData` central; ningún widget lleva colores escritos a mano.

**Tipografía: Poppins Light (300) y Regular (400) en toda la app, como el Login.** Nunca pesos mayores. La escala está en `lib/core/theme/app_typography.dart` (`brand`, `headline`, `title`, `body`, `bodySmall`, `caption`) y el `textTheme` de Material también se baja a Light/Regular. Solo se empaquetan esos dos pesos.

Notas:
- El frame `106:97` es una **imagen pegada** (captura), no capas editables, así que `get_design_context` no devuelve valores exactos; las medidas de esa vista se toman de la imagen.
- En las demás pantallas, sacar valores exactos con `get_design_context` / `get_variable_defs` del MCP de Figma.

## Rendimiento (requisito no negociable)

La app **no debe calentar el dispositivo, ni gastar batería de más, ni saturar la RAM, ni el almacenamiento**. Todo cambio relevante se valida midiendo, no a ojo.

- **CPU / temperatura**
  - La decodificación de audio la hace el reproductor nativo (AVPlayer / ExoPlayer vía `just_audio`), nunca Dart.
  - Cifrado, hashing SHA-256 e importaciones grandes en **isolates**, nunca en el hilo de UI.
  - Nada de polling ni timers en bucle: usar streams/eventos. Sin animaciones corriendo fuera de pantalla.
  - Con la pantalla bloqueada solo trabaja el audio (y descargas del sistema); la UI no se reconstruye en segundo plano.
- **RAM**
  - Listas siempre perezosas (`ListView.builder` / slivers), nunca listas completas en memoria.
  - Imágenes decodificadas al tamaño mostrado (`cacheWidth`/`cacheHeight`) y caché de imágenes con límite.
  - Descifrado del audio por bloques (streaming), nunca el archivo entero en memoria.
  - Liberar controllers, subscriptions y players en `dispose`.
- **Almacenamiento**: lo definido en Transcodificación y Modo offline (AAC, miniaturas WebP, caché LRU con límite, sin duplicados, temporales borrados).
- **Batería** (prioridad máxima: es una app que suena horas con la pantalla apagada):
  - **Audio**: AAC se decodifica por **hardware** en iOS y Android (una razón más para no usar Opus/MP3 por software). Reproducir siempre con el player nativo vía `just_audio` + `audio_service`.
  - **Wakelocks mínimos**: en Android, `WakeLock`/`WifiLock` solo mientras suena (WifiLock solo si es streaming); al pausar, el servicio en primer plano se detiene tras un timeout corto. Nunca mantener la pantalla encendida.
  - **Background modes en iOS**: solo `audio` (y las descargas en background de `URLSession`). Nada de ubicación, ni audio silencioso para mantener la app viva, ni `fetch` innecesario.
  - **Radio de red**: descargar la canción en ráfagas grandes y luego dejar dormir la radio (evitar goteo de pequeños chunks). Precargar la siguiente canción de la cola de una vez. Si la canción está descargada, **cero red** al reproducir.
  - **Sin polling ni conexiones abiertas en segundo plano**: Supabase Realtime solo con la pantalla visible y se cierra al ir a background. Para avisos, push notifications.
  - **Agrupar trabajo**: cola de sincronización, contadores de reproducción y analytics se envían en lote (al volver a primer plano o en una tarea programada por el SO), no evento por evento.
  - **Descargas programadas por el SO**: lotes grandes con `WorkManager` con restricciones (Wi-Fi, batería no baja) y `URLSession` en background; opción "descargar solo mientras carga".
  - **Modo ahorro de energía** (Low Power Mode en iOS / Battery Saver en Android): pausar precargas y descargas no pedidas, reducir animaciones, posponer sincronización.
  - **Animaciones**: ninguna en bucle (p. ej. portada girando) cuando la app no está visible o con la pantalla apagada; respetar "reducir movimiento".
  - **Pantalla**: el modo oscuro ahorra batería en iPhones OLED; evaluar negro puro (`#000000`) para el fondo oscuro.
  - **Medir**: reproducción de 1 h con pantalla apagada (offline y streaming) comparando con Apple Music/Spotify; Xcode Organizer → Energy, Instruments (Energy Log, Time Profiler), MetricKit; en Android, Energy Profiler y Battery Historian.
- **Red**: paginar el catálogo, caché HTTP, descargas pesadas solo en Wi-Fi por defecto.
- **UI**: 60/120 fps sin jank; widgets `const`, rebuilds mínimos (estado granular).
- **Cómo se mide**: probar siempre en **modo profile en un iPhone real** (`flutter run --profile`), nunca juzgar rendimiento en debug ni en simulador. Herramientas: Flutter DevTools (Performance, Memory, CPU profiler) e Instruments de Xcode (Time Profiler, Allocations, Leaks, Energy Log).
- Presupuestos orientativos a vigilar: arranque en frío < 2 s, RAM estable sin crecer al navegar o reproducir largo rato, sin fugas tras abrir/cerrar pantallas repetidamente.

## Convenciones

- Código y nombres en inglés; textos visibles al usuario en español (preparar i18n desde el inicio).
- Secretos (keys de Supabase service role, B2, Cloudflare) solo en variables de entorno / secretos del backend; en la app solo va la `anon key` de Supabase.
- Activar Row Level Security en todas las tablas de Supabase.

## MCP disponibles

- **Figma** (`figma`): leer el diseño con los node IDs de la sección Diseño.
- **Supabase** (`supabase`, en `.mcp.json`, servidor oficial `https://mcp.supabase.com/mcp`, autenticación OAuth): consultar/crear tablas, migraciones, políticas RLS, Edge Functions y logs. Fijado al proyecto `sonify` con `?project_ref=gbpnbcpbqraojdeaaalt` para no tocar otros proyectos de la cuenta; añadir `&read_only=true` si solo se va a consultar. Cambios de esquema siempre como migraciones.
