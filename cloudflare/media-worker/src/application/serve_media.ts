import { parseMediaKey, type MediaKey } from '../domain/media_key.ts';
import { verifyMediaSignature } from '../domain/signed_url.ts';

/** Bucket de origen (B2). Devuelve la respuesta tal cual: 200, 206, 404… */
export interface ObjectStore {
  fetch(
    key: string,
    init: { method: 'GET' | 'HEAD'; range: string | null },
  ): Promise<Response>;
}

/** Caché del edge, por key (sin la firma de la URL). */
export interface MediaCache {
  /** Con `range`, devuelve el 206 recortado del objeto cacheado. */
  match(key: string, range: string | null): Promise<Response | undefined>;
  put(key: string, response: Response): Promise<void>;
}

export type ServeMediaDeps = {
  store: ObjectStore;
  cache: MediaCache;
  signingKey: CryptoKey;
  nowSeconds: () => number;
  /** Trabajo que sigue tras responder (`ctx.waitUntil`). */
  defer: (work: Promise<unknown>) => void;
};

export type MediaRequest = {
  method: string;
  pathname: string;
  exp: string | null;
  sig: string | null;
  range: string | null;
};

// Los archivos de audio/ y covers/ son inmutables: si cambian, cambia la key.
const IMMUTABLE = 'public, max-age=31536000, immutable';
const PASSED_HEADERS = ['content-length', 'content-range', 'etag', 'last-modified'];

export async function serveMedia(
  req: MediaRequest,
  deps: ServeMediaDeps,
): Promise<Response> {
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    return status(405, { Allow: 'GET, HEAD' });
  }
  const media = parseMediaKey(req.pathname);
  if (!media) return status(404);
  const valid = await verifyMediaSignature(
    deps.signingKey,
    media.key,
    req.exp,
    req.sig,
    deps.nowSeconds(),
  );
  if (!valid) return status(403);

  const head = req.method === 'HEAD';
  const cached = await deps.cache.match(media.key, req.range);
  if (cached) return present(cached, media, head);

  const origin = await deps.store.fetch(media.key, {
    method: req.method,
    range: req.range,
  });
  if (origin.status === 404 || origin.status === 416 || !origin.ok) {
    await origin.body?.cancel();
    if (origin.status === 404) return status(404);
    if (origin.status === 416) return status(416);
    console.error(`origin ${origin.status} for ${media.key}`);
    return status(502);
  }
  if (head) return present(origin, media, true);

  if (origin.status === 206 || !origin.body) {
    // Responde ya el rango pedido (primer byte rápido para el reproductor) y
    // llena la caché con el archivo completo en segundo plano.
    deps.defer(fillCache(media, deps));
    return present(origin, media, false);
  }

  const [forClient, forCache] = origin.body.tee();
  deps.defer(
    deps.cache.put(media.key, present(new Response(forCache, origin), media, false)),
  );
  return present(new Response(forClient, origin), media, false);
}

async function fillCache(media: MediaKey, deps: ServeMediaDeps): Promise<void> {
  const full = await deps.store.fetch(media.key, { method: 'GET', range: null });
  if (full.status !== 200) {
    await full.body?.cancel();
    return;
  }
  await deps.cache.put(media.key, present(full, media, false));
}

function present(source: Response, media: MediaKey, head: boolean): Response {
  const headers = new Headers({
    'Content-Type': media.contentType,
    'Cache-Control': IMMUTABLE,
    'Accept-Ranges': 'bytes',
    'Access-Control-Allow-Origin': '*',
  });
  for (const name of PASSED_HEADERS) {
    const value = source.headers.get(name);
    if (value) headers.set(name, value);
  }
  if (head) source.body?.cancel();
  return new Response(head ? null : source.body, {
    status: source.status,
    headers,
  });
}

function status(code: number, headers?: Record<string, string>): Response {
  return new Response(null, {
    status: code,
    headers: { 'Cache-Control': 'no-store', ...headers },
  });
}
