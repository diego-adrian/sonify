# Costos de Sonify: qué vigilar para evitar cobros excesivos

> Revisado el **28 de octubre de 2026**. Los precios y límites salen de las páginas de cada proveedor y de guías de terceros; **cambian seguido**, así que confirma en la página oficial antes de presupuestar. Las estimaciones de consumo son aproximadas y hay que validarlas con el uso real.

## Resumen

| Servicio | Para qué lo usa Sonify | Plan actual | ¿Puede cobrar sin aviso? | Riesgo |
|---|---|---|---|---|
| **Backblaze B2** | Originales, audio AAC y portadas | Pago por uso, con tarjeta | **Sí: sin topes, el cobro no tiene límite** | 🔴 Alto hasta configurar los topes |
| **Cloudflare** | DNS, CDN y Worker `sonify-media` (+ tu sitio en Pages) | Gratis | No, pero al pasar el límite el CDN **deja de responder** | 🟠 Corte del servicio |
| **Supabase** | Auth, Postgres, Edge Functions, cron | Gratis | No, pero **se pausa** tras 1 semana sin uso o al pasar los límites | 🟠 Corte del servicio |
| **Render** | Transcodificador (ffmpeg) | Gratis | No, pero se suspende al pasar los límites | 🟡 Medio |
| **Apple Developer** | Publicar en App Store, CarPlay | 99 USD al año (pendiente) | Precio fijo | 🟢 Bajo |
| **Google Play Console** | Publicar en Play Store | 25 USD una vez (pendiente) | Precio fijo | 🟢 Bajo |
| **Google Cloud** | Solo el login con Google (OAuth) | Sin facturación | No: el OAuth es gratis | 🟢 Bajo |
| **GitHub** | Repositorio `diego-adrian/sonify` | Gratis | No | 🟢 Bajo |
| **Dominio** `diegoadrian.com` | Subdominio del CDN | Renovación anual | Renovación automática | 🟢 Bajo |

---

## 1. Backblaze B2 🔴 (lo primero que hay que configurar)

**Qué cobra:**

| Concepto | Precio | Gratis |
|---|---|---|
| Almacenamiento | ~6,95 USD por TB al mes | Primeros 10 GB |
| Descarga (egress) | 0,01 USD por GB | Hasta **3 veces lo almacenado** al mes; **siempre gratis hacia Cloudflare** (Bandwidth Alliance) |
| Transacciones clase B (lecturas: GET, HEAD) | 0,004 USD cada 10 000 | 2 500 al día |
| Transacciones clase C (listar archivos, gestionar llaves) | 0,004 USD cada 1 000 | 2 500 al día |
| Subidas (clase A) | Gratis | — |

**Qué consume en Sonify, por canción:**
- **El original:** un MP3 pesa unos 8 MB, un WAV puede llegar a **200 MB**. Es lo que más ocupa, y se guarda para siempre.
- **Las versiones convertidas:** unos 22 MB (96 + 128 + 256 kbps) más ~40 KB de portadas.
- **Lecturas clase B:**
  - El Worker lee de B2 cuando el archivo no está en la caché de Cloudflare (1 o 2 GET por canción la primera vez en cada data center).
  - Render baja el original para procesarlo.
  - `complete-upload` hace un HEAD.

**Cuánto saldría (estimación):**
- 1 000 canciones con originales MP3 ocupan unos 30 GB, **menos de 0,20 USD al mes**.
- Con originales WAV serían unos 220 GB, alrededor de **1,50 USD al mes**.
- 10 000 canciones con originales WAV ocupan unos 2,2 TB, alrededor de **15 USD al mes**.

**Riesgos:**
- **Sin topes, B2 cobra lo que se consuma.** Un error en un bucle, una subida masiva o alguien abusando de la API generan cobros sin límite.
- **Versiones ocultas:** B2 guarda **todas las versiones** de un archivo. Cada reintento del transcodificador sobrescribe las mismas keys, y la versión anterior queda oculta pero **se sigue cobrando**. Borrar con la API S3 también deja el archivo oculto y cobrado.
- **Subidas huérfanas:** si alguien empieza una subida y no la termina, el original queda en el bucket. Falta la limpieza automática.
- **Listar archivos (clase C):** si algún script lista el bucket seguido, las transacciones clase C se disparan.

**Qué configurar ya:**
1. **Caps & Alerts** (B2 → *Caps & Alerts*): pon un tope diario en dólares en las 4 categorías: almacenamiento, descargas, clase B y clase C. Para empezar sirve **0,10 USD al día** en cada una. Llega un correo al 75 % y al 100 % y, al llegar al tope, B2 bloquea esa operación hasta la medianoche (GMT) en lugar de cobrar. Ojo: así también se puede cortar el servicio; súbelos a medida que crezcas.
2. **Lifecycle rule** en el bucket `sonify-media-adrian`: *Keep only the last version of the file*, para que las versiones ocultas se borren al día siguiente.
3. **Llaves con lo mínimo necesario**, como ya está:
   - `sonify-cdn`: solo lectura.
   - `sonify-transcoder`: lectura y escritura.
   - Edge Functions: lectura y escritura.
   - Ninguna tiene acceso a otros buckets.
4. **Cambiar la llave que se pegó en el chat al inicio del proyecto.**

---

## 2. Cloudflare 🟠

**Qué usa Sonify:**
- **DNS y proxy** de `diegoadrian.com`: gratis.
- **Worker `sonify-media`:** cuenta **una petición por cada pedido del reproductor**, incluido cada pedazo (rango) de audio.
- **Cache API:** gratis.
- Tu sitio en **Pages** comparte la cuota de peticiones si usa Functions.

**Límites:**

| | Gratis | Workers Paid (5 USD al mes) |
|---|---|---|
| Peticiones al Worker | **100 000 al día** (se reinician a medianoche UTC) | 10 millones al mes incluidas, luego ~0,30 USD por millón (otras fuentes dicen 0,50; confírmalo) |
| Al pasar el límite | El Worker **responde error** y la app no puede reproducir ni descargar | Cobra el excedente |
| Containers | No disponible | Incluido con cuota (no se usa: el transcodificador está en Render) |

**Cuánto consume Sonify (estimación):**
- Una canción reproducida genera unas **3–6 peticiones**: el reproductor pide por rangos, más la portada.
- 500 usuarios al día con 20 canciones cada uno son unas **50 000 peticiones al día**, la mitad del plan gratis.
- **Con ~1 000 usuarios activos al día se llega al límite gratis.** Ahí hay que pasar a Workers Paid.

**Riesgo con los términos de servicio:** los términos del CDN de Cloudflare restringen servir video y "archivos grandes" alojados fuera de Cloudflare, salvo con servicios pagos (Developer Platform, R2, Stream). No queda claro si el audio entra en esa restricción.
- Servir mediante un Worker con el plan **Workers Paid** (Developer Platform) probablemente cubre el caso.
- Si el tráfico crece mucho, la alternativa es mover `audio/` y `covers/` a **R2**, que no cobra egress.
- **Antes de publicar en la tienda, revisa los Service-Specific Terms o pregunta a soporte.**

**Qué configurar:**
1. **Notificaciones** (Notifications → Add): alertas de uso de Workers y, si pasas a Paid, de *Usage based billing*.
2. **Pasar a Workers Paid antes de lanzar** en la tienda: evita que el CDN se caiga en un día de mucho uso y ayuda con los términos de servicio.
3. Revisar de vez en cuando *Workers & Pages → sonify-media → Metrics*: peticiones por día y porcentaje de aciertos de la caché.

---

## 3. Supabase 🟠

**Límites del plan gratis:**

| Recurso | Gratis | Qué lo consume en Sonify |
|---|---|---|
| Base de datos | 500 MB | Filas de canciones, perfiles y archivos (muy poco; miles de canciones ocupan pocos MB) |
| Usuarios activos al mes (MAU) | 50 000 | Login con Google |
| Egress (respuestas de la API) | 5 GB al mes | **El catálogo:** cada carga trae ~30 canciones con 4 URLs firmadas, unos 15–20 KB |
| Edge Functions | 500 000 invocaciones al mes | `create-upload` y `complete-upload` (2 por subida) |
| Proyectos activos | 2 por organización | `sonify` (+ otro que tengas) |
| Backups automáticos | **No incluidos** | — |
| **Pausa** | **Tras 1 semana sin actividad** | Si nadie usa la app por 7 días, se pausa y hay que reactivarlo a mano |

**Cuánto consume Sonify (estimación):**
- **El egress es el primer límite que se va a alcanzar.** 1 000 usuarios al día que abren la app unas 10 veces suman 1 000 × 10 × 17 KB ≈ **5 GB al mes**, justo el límite.
- La app ya ayuda a reducirlo: solo recarga el catálogo al deslizar hacia abajo o si pasaron más de 10 minutos.

**Qué configurar:**
1. Revisar **Usage** en el dashboard (Organization → Usage) cada semana al principio.
2. **Plan Pro (25 USD al mes) cuando haya usuarios reales.** No se pausa, incluye backups diarios, más egress y 100 000 MAU. Viene con el **Spend cap activado por defecto**: al llegar al límite **bloquea en lugar de cobrar**. Déjalo activado hasta que tengas claro el consumo.
3. Mientras sigas en el plan gratis, la app no debería quedar 7 días sin uso; en desarrollo, abre la app o el dashboard al menos una vez por semana.
4. **Hacer un respaldo manual de la base** antes de cambios grandes, porque el plan gratis no tiene backups.

---

## 4. Render 🟡

**Plan gratis:**
- **Instancia:** 512 MB de RAM y 0,1 CPU.
- **Horas:** 750 al mes por workspace, suficientes para 1 servicio.
- **Se duerme** tras 15 minutos sin peticiones y despierta en 30–60 s.
- **Ancho de banda de salida limitado:** hay reportes de que en agosto de 2026 se recortó.

**Qué consume Sonify:** por cada canción, bajar el original de B2 (entrada) y **subir unos 22 MB de versiones convertidas a B2 (salida)**. 200 canciones al mes son unos 4,4 GB de salida.

**Riesgos:**
- **Si pasas el límite de ancho de banda u horas,** Render suspende el servicio y las canciones quedan en `processing`. El cron reintenta 3 veces y después las marca `failed`.
- **Bucles de reintento:** ya están limitados a 3 intentos por canción (`transcode_attempts`).

**Qué configurar:**
1. Revisar **Billing → Usage** en Render una vez al mes (horas y ancho de banda).
2. Si suben más de unas 200 canciones al mes, o tardan mucho en procesarse, pasar a **Starter (~7 USD al mes)** o mover el transcodificador a Cloud Run o Cloudflare Containers. El código no cambia.

---

## 5. Apple y Google Play 🟢

| | Costo | Ojo |
|---|---|---|
| Apple Developer Program | 99 USD al año | Si no renuevas, la app sale de la tienda. El permiso de CarPlay es gratis, pero requiere la cuenta |
| Google Play Console | 25 USD, un solo pago | — |
| Comisión por ventas | 15–30 % | Solo si algún día se cobra algo dentro de la app; hoy no aplica |

---

## 6. Google Cloud (solo el login) 🟢

- El proyecto `sonifyauth` solo se usa para el **OAuth de Google**, que es gratis y **no necesita facturación**.
- La facturación quedó sin activar (error OR_BACR2_59), así que **no hay forma de que cobre**.
- **Antes de publicar:** publica la *OAuth consent screen* (de "Testing" a "In production"). Con permisos básicos (email y perfil) no requiere la verificación paga.
- **Cambiar el *client secret* de Google**, que estuvo en un archivo local del proyecto.

---

## 7. Otros

| Servicio | Costo | Ojo |
|---|---|---|
| GitHub (repo privado) | Gratis | No usar GitHub Actions como servidor (lo prohíben sus términos); solo para pruebas y despliegues |
| Dominio `diegoadrian.com` | ~10–15 USD al año | Que la renovación no falle: el CDN depende del subdominio |
| **A futuro:** login con email (Supabase Auth) | Gratis hasta cierto volumen | El correo incluido de Supabase tiene un límite de envíos muy bajo; para producción hace falta un SMTP propio (Resend, Postmark…, con nivel gratis) |
| **A futuro:** notificaciones push | Gratis (APNs y FCM) | — |
| **A futuro:** reportes de errores y analítica | Niveles gratis (Sentry, Crashlytics) | Configurar el muestreo para no pasar la cuota |

---

## 8. Protecciones que ya tiene el código

- **Subidas acotadas:** máximo **20 por usuario al día** y **200 MB** por archivo, validado en el servidor (`create-upload`). La portada, hasta 10 MB.
- **El CDN solo sirve lo convertido** (`audio/` y `covers/`), nunca `originals/`, y solo con **URL firmada** (24–48 h). Nadie puede usar el bucket como hosting gratis.
- **Caché del edge** con `immutable` durante un año: cada archivo se lee de B2 una vez por data center.
- **Transcodificación de a una canción** y **máximo 3 intentos** por canción. No hay bucles infinitos.
- **El catálogo no se recarga en segundo plano:** solo al deslizar hacia abajo o al volver a la app tras 10 minutos.
- **Descargas offline solo con Wi-Fi** por defecto. Eso protege el plan de datos del usuario; para B2 y Cloudflare no cambia nada.

## 9. Pendientes que bajan costos o riesgos

- [ ] **B2:** configurar Caps & Alerts y la lifecycle rule *Keep only the last version* (sección 1).
- [ ] **Limpieza de subidas abandonadas:** borrar las filas `uploading` de más de 24 h **y su original en B2**.
- [ ] **Borrar los archivos en B2** cuando se elimina una canción (hoy solo se marca `deleted_at`) y al borrar una cuenta.
- [ ] **Decidir si se guardan los originales para siempre.** Son lo que más ocupa. Opciones: guardarlos (permite volver a convertir), comprimirlos a FLAC o borrarlos tras X meses.
- [ ] **Workers Paid** antes de lanzar (sección 2).
- [ ] **Supabase Pro** cuando haya usuarios reales (sección 3).
- [ ] **Cambiar las llaves expuestas:** la de B2 y el client secret de Google.

## 10. Revisión mensual (5 minutos)

1. **Backblaze:** *Caps & Alerts* y la factura del mes. ¿Crece el almacenamiento como se esperaba?
2. **Cloudflare:** *sonify-media → Metrics*. ¿Cuántas peticiones al día y qué porcentaje de aciertos de caché?
3. **Supabase:** *Usage*. Egress, tamaño de la base y MAU frente a los límites.
4. **Render:** *Usage*. Horas y ancho de banda.
5. **Canciones en `failed`** (señal de que algo falla en el transcodificador):
   ```sql
   select count(*) from songs where status = 'failed' and created_at > now() - interval '30 days';
   ```

## Fuentes

- [Backblaze B2 pricing explained (oct 2026)](https://upstash.com/blog/backblaze-b2-pricing-explained-2026.md)
- [Backblaze: Data Caps and Alerts](https://www.backblaze.com/docs/cloud-storage-data-caps-and-alerts)
- [Backblaze: Create and Manage Caps and Alerts](https://www.backblaze.com/docs/cloud-storage-create-and-manage-caps-and-alerts)
- [Supabase Pricing](https://Supabase.io/pricing)
- [Supabase Pricing 2026 (jetadmin)](https://www.jetadmin.io/blog/supabase-pricing-2026-guide-to-plans-limits-and-real-world-costs/)
- [Supabase Free Tier Limits 2026](https://automationatlas.io/answers/supabase-free-tier-limits-2026/)
- [Cloudflare free limits 2026 (eastondev)](https://eastondev.com/blog/en/posts/dev/20260526-cloudflare-free-limits/)
- [Cloudflare Pages Functions pricing](https://developers.cloudflare.com:2053/pages/functions/pricing)
- [Cloudflare: Goodbye, section 2.8 (nuevos términos)](https://blog.cloudflare.com/updated-tos/?hl=en-US)
- [Cloudflare Containers pricing](https://developers.cloudflare.com/containers/pricing/)
- [Render pricing](https://render-www.onrender.com/pricing)
- [Render en 2026: cambio de plan y recorte de ancho de banda](https://jwatte.com/blog/render-com-platform-review.md)
