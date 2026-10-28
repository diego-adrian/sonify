// Composition root del Worker de `sonify.diegoadrian.com`: conecta el caso de
// uso con B2 y la caché del edge.
import { serveMedia } from './application/serve_media.ts';
import { importSigningKey } from './domain/signed_url.ts';
import { b2ObjectStore } from './infrastructure/b2_object_store.ts';
import { edgeCache } from './infrastructure/edge_cache.ts';

interface Env {
  B2_BUCKET: string;
  B2_ENDPOINT: string;
  B2_KEY_ID?: string;
  B2_APPLICATION_KEY?: string;
  MEDIA_URL_SECRET?: string;
}

// Se crean una vez por isolate.
let wired: { secret: string; signingKey: Promise<CryptoKey>; store: ReturnType<typeof b2ObjectStore> } | undefined;

function wire(env: Env) {
  const { B2_KEY_ID, B2_APPLICATION_KEY, MEDIA_URL_SECRET } = env;
  if (!B2_KEY_ID || !B2_APPLICATION_KEY || !MEDIA_URL_SECRET) return undefined;
  if (wired?.secret !== MEDIA_URL_SECRET) {
    wired = {
      secret: MEDIA_URL_SECRET,
      signingKey: importSigningKey(MEDIA_URL_SECRET),
      store: b2ObjectStore({
        keyId: B2_KEY_ID,
        applicationKey: B2_APPLICATION_KEY,
        bucket: env.B2_BUCKET,
        endpoint: env.B2_ENDPOINT,
      }),
    };
  }
  return wired;
}

export default {
  async fetch(request, env, ctx): Promise<Response> {
    const deps = wire(env);
    if (!deps) {
      console.error('Faltan secretos: B2_KEY_ID, B2_APPLICATION_KEY o MEDIA_URL_SECRET');
      return new Response(null, { status: 503 });
    }
    const url = new URL(request.url);
    try {
      return await serveMedia(
        {
          method: request.method,
          pathname: url.pathname,
          exp: url.searchParams.get('exp'),
          sig: url.searchParams.get('sig'),
          range: request.headers.get('Range'),
        },
        {
          store: deps.store,
          cache: edgeCache(caches.default, url.origin),
          signingKey: await deps.signingKey,
          nowSeconds: () => Math.floor(Date.now() / 1000),
          defer: (work) => ctx.waitUntil(work),
        },
      );
    } catch (error) {
      console.error(error);
      return new Response(null, { status: 500 });
    }
  },
} satisfies ExportedHandler<Env>;
